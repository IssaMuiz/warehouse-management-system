
-- WMS initial schema: company identity and access foundation.
-- This migration is local only until explicitly pushed.

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text,
    phone text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.platform_admins (
    user_id uuid primary key references auth.users(id) on delete cascade,
    created_at timestamptz not null default now(),
    created_by uuid references auth.users(id) on delete set null
);

create table public.companies (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    legal_name text,
    status text not null default 'pending'
        check (status in ('pending', 'approved', 'rejected', 'suspended')),
    created_by uuid references auth.users(id) on delete set null,
    approved_by uuid references auth.users(id) on delete set null,
    approved_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint companies_name_not_blank check (length(trim(name)) > 0)
);

create table public.company_memberships (
    id uuid primary key default gen_random_uuid(),
    company_id uuid not null references public.companies(id) on delete restrict,
    user_id uuid not null references auth.users(id) on delete cascade,
    role text not null check (
        role in (
            'company_admin',
            'production_manager',
            'receiving_officer',
            'customer_service',
            'dispatch_officer',
            'warehouse_staff',
            'report_viewer'
        )
    ),
    status text not null default 'active'
        check (status in ('invited', 'active', 'suspended')),
    invited_by uuid references auth.users(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (company_id, user_id)
);

create index company_memberships_user_idx
    on public.company_memberships (user_id, status);

create index company_memberships_company_role_idx
    on public.company_memberships (company_id, role, status);

-- Functions used by access policies.
-- SECURITY DEFINER lets these functions check memberships without
-- recursively triggering the membership table's own RLS policies.

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.platform_admins pa
        where pa.user_id = (select auth.uid())
    );
$$;

create or replace function public.is_active_company_member(p_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.company_memberships cm
        where cm.company_id = p_company_id
          and cm.user_id = (select auth.uid())
          and cm.status = 'active'
    );
$$;

create or replace function public.has_company_role(
    p_company_id uuid,
    p_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.company_memberships cm
        where cm.company_id = p_company_id
          and cm.user_id = (select auth.uid())
          and cm.status = 'active'
          and cm.role = any(p_roles)
    );
$$;

revoke all on function public.is_platform_admin() from public, anon;
revoke all on function public.is_active_company_member(uuid) from public, anon;
revoke all on function public.has_company_role(uuid, text[]) from public, anon;

grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.is_active_company_member(uuid) to authenticated;
grant execute on function public.has_company_role(uuid, text[]) to authenticated;

-- Automatically create a profile when a Supabase Auth user is created.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.profiles (id, full_name)
    values (
        new.id,
        nullif(trim(new.raw_user_meta_data ->> 'full_name'), '')
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Keep updated_at under database control.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger profiles_set_updated_at
    before update on public.profiles
    for each row execute function public.set_updated_at();

create trigger companies_set_updated_at
    before update on public.companies
    for each row execute function public.set_updated_at();

create trigger company_memberships_set_updated_at
    before update on public.company_memberships
    for each row execute function public.set_updated_at();

-- Enable Row Level Security on every table.

alter table public.profiles enable row level security;
alter table public.platform_admins enable row level security;
alter table public.companies enable row level security;
alter table public.company_memberships enable row level security;

-- Remove default client privileges before granting least privilege.
revoke all on table
    public.profiles,
    public.platform_admins,
    public.companies,
    public.company_memberships
from anon, authenticated;

-- Profiles: users can read and edit only their own permitted fields.

grant select on public.profiles to authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

create policy "Users read their own profile"
    on public.profiles for select to authenticated
    using (id = (select auth.uid()));

create policy "Users update their own profile"
    on public.profiles for update to authenticated
    using (id = (select auth.uid()))
    with check (id = (select auth.uid()));

-- Platform administrator records are readable by platform admins only.
-- No client-side insert, update or delete policy is provided.

grant select on public.platform_admins to authenticated;

create policy "Platform admins read platform admin records"
    on public.platform_admins for select to authenticated
    using (
        user_id = (select auth.uid())
        or (select public.is_platform_admin())
    );

-- Companies: members can see their own company; platform admins can
-- see all companies and create/update company records.

grant select, insert, update on public.companies to authenticated;

create policy "Members and platform admins read companies"
    on public.companies for select to authenticated
    using (
        (select public.is_platform_admin())
        or (select public.is_active_company_member(id))
    );

create policy "Platform admins create companies"
    on public.companies for insert to authenticated
    with check ((select public.is_platform_admin()));

create policy "Platform admins update companies"
    on public.companies for update to authenticated
    using ((select public.is_platform_admin()))
    with check ((select public.is_platform_admin()));

-- Memberships: users can see their own memberships. Company admins
-- can see memberships within their company. Only platform admins can
-- initially create or modify memberships; invitation management will
-- be added in a later reviewed migration.

grant select, insert, update on public.company_memberships to authenticated;

create policy "Users and authorised admins read memberships"
    on public.company_memberships for select to authenticated
    using (
        user_id = (select auth.uid())
        or (select public.is_platform_admin())
        or (
            (select public.has_company_role(
                company_id,
                array['company_admin']::text[]
            ))
        )
    );

create policy "Platform admins create memberships"
    on public.company_memberships for insert to authenticated
    with check ((select public.is_platform_admin()));

create policy "Platform admins update memberships"
    on public.company_memberships for update to authenticated
    using ((select public.is_platform_admin()))
    with check ((select public.is_platform_admin()));

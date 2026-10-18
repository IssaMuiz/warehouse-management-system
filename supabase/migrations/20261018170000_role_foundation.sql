-- WMS Phase 1: role foundation and assignment limits
-- Additive migration. Existing legacy roles and data are preserved.

begin;

-- Designate one central warehouse per company. Existing warehouses remain non-central
-- until explicitly designated after the company confirms which warehouse is central.
alter table public.warehouses
  add column is_central boolean not null default false;

create unique index warehouses_one_central_per_company_uq
  on public.warehouses (company_id)
  where is_central = true;

-- Add the agreed roles while retaining legacy role names for a controlled transition.
alter table public.company_memberships
  drop constraint company_memberships_role_check;

alter table public.company_memberships
  add constraint company_memberships_role_check
  check (role = any (array[
    'company_admin',
    'production_manager',
    'receiving_officer',
    'customer_service',
    'dispatch_officer',
    'warehouse_staff',
    'report_viewer',
    'warehouse_manager',
    'warehouse_executive',
    'auditor',
    'member'
  ]::text[]));

-- Serialize membership/assignment changes by company. This makes the limits safe
-- against concurrent attempts to assign the final available slot.
create or replace function public.enforce_wms_role_assignment_limits()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_company_id uuid;
  v_manager_count integer;
  v_over_limit_warehouse text;
begin
  if tg_table_name = 'company_memberships' then
    v_company_id := new.company_id;
  else
    v_company_id := new.company_id;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_company_id::text, 0)
  );

  if tg_table_name = 'company_memberships' then
    -- No more than two active warehouse managers in a company.
    if new.role = 'warehouse_manager' and new.status = 'active' then
      select count(*)::integer
        into v_manager_count
        from public.company_memberships cm
       where cm.company_id = new.company_id
         and cm.role = 'warehouse_manager'
         and cm.status = 'active'
         and cm.id <> new.id;

      if v_manager_count >= 2 then
        raise exception 'A company may have at most two active warehouse managers.'
          using errcode = '23514';
      end if;
    end if;

    -- If a member is made an active warehouse executive, ensure their existing
    -- assignments will not push any warehouse above two active executives.
    if new.role = 'warehouse_executive' and new.status = 'active' then
      select w.code
        into v_over_limit_warehouse
        from public.warehouse_memberships wm
        join public.warehouses w
          on w.id = wm.warehouse_id and w.company_id = wm.company_id
        join public.company_memberships other_cm
          on other_cm.id = wm.membership_id
       where wm.company_id = new.company_id
         and wm.membership_id <> new.id
         and other_cm.role = 'warehouse_executive'
         and other_cm.status = 'active'
       group by w.id, w.code
      having count(*) >= 2
       limit 1;

      if v_over_limit_warehouse is not null then
        raise exception 'Warehouse % already has two active warehouse executives.', v_over_limit_warehouse
          using errcode = '23514';
      end if;
    end if;

    return new;
  end if;

  -- A warehouse executive may have at most two active assignments in each warehouse.
  if tg_table_name = 'warehouse_memberships' then
    if exists (
      select 1
        from public.company_memberships cm
       where cm.id = new.membership_id
         and cm.company_id = new.company_id
         and cm.role = 'warehouse_executive'
         and cm.status = 'active'
    ) then
      -- Count active executives already assigned to this warehouse.
      if (
        select count(*)
          from public.warehouse_memberships wm
          join public.company_memberships cm on cm.id = wm.membership_id
         where wm.company_id = new.company_id
           and wm.warehouse_id = new.warehouse_id
           and wm.membership_id <> new.membership_id
           and cm.role = 'warehouse_executive'
           and cm.status = 'active'
      ) >= 2 then
        raise exception 'A warehouse may have at most two active warehouse executives.'
          using errcode = '23514';
      end if;
    end if;
    return new;
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_wms_role_assignment_limits() from public, anon, authenticated;

create trigger company_memberships_enforce_role_limits
before insert or update of company_id, role, status
on public.company_memberships
for each row execute function public.enforce_wms_role_assignment_limits();

create trigger warehouse_memberships_enforce_role_limits
before insert or update of company_id, warehouse_id, membership_id
on public.warehouse_memberships
for each row execute function public.enforce_wms_role_assignment_limits();

commit;

-- WMS Phase 1: warehouse-operation authorization helper
-- Additive migration. Does not create or post operational transactions.

begin;

create or replace function public.can_operate_warehouse(
  p_company_id uuid,
  p_warehouse_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.warehouses w
      join public.companies c
        on c.id = w.company_id
     where w.id = p_warehouse_id
       and w.company_id = p_company_id
       and w.is_active = true
       and c.status = 'approved'
       and exists (
         select 1
           from public.company_memberships cm
          where cm.company_id = p_company_id
            and cm.user_id = (select auth.uid())
            and cm.status = 'active'
            and cm.role = 'warehouse_manager'
       )
  )
  or exists (
    select 1
      from public.warehouses w
      join public.companies c
        on c.id = w.company_id
      join public.warehouse_memberships wm
        on wm.company_id = w.company_id
       and wm.warehouse_id = w.id
      join public.company_memberships cm
        on cm.company_id = wm.company_id
       and cm.id = wm.membership_id
     where w.id = p_warehouse_id
       and w.company_id = p_company_id
       and w.is_active = true
       and c.status = 'approved'
       and cm.user_id = (select auth.uid())
       and cm.status = 'active'
       and cm.role = 'warehouse_executive'
  );
$$;

revoke all on function public.can_operate_warehouse(uuid, uuid)
  from public, anon;
grant execute on function public.can_operate_warehouse(uuid, uuid)
  to authenticated;

commit;

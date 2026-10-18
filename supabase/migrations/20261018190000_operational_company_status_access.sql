-- WMS Phase 1: separate company-status visibility from operational data access.
-- Active members may still read their own company record/status, but operational
-- tables are readable only while the company is approved. Warehouse reads remain
-- company-wide; warehouse assignment limits are for operational actions only.

begin;

create or replace function public.is_active_operational_company_member(p_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
    select exists (
        select 1
        from public.company_memberships cm
        join public.companies c
          on c.id = cm.company_id
        where cm.company_id = p_company_id
          and cm.user_id = (select auth.uid())
          and cm.status = 'active'
          and c.status = 'approved'
    );
$function$;

revoke all on function public.is_active_operational_company_member(uuid) from public, anon;
grant execute on function public.is_active_operational_company_member(uuid) to authenticated;

-- Replace the company-membership-only read policies on operational tables.
-- The existing is_active_company_member() helper and companies SELECT policy
-- are intentionally retained so members can see their own company status.

drop policy if exists "active members can read audit_events" on public.audit_events;
create policy "active members can read audit_events"
    on public.audit_events for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read customer_order_lines" on public.customer_order_lines;
create policy "active members can read customer_order_lines"
    on public.customer_order_lines for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read customer_orders" on public.customer_orders;
create policy "active members can read customer_orders"
    on public.customer_orders for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read customers" on public.customers;
create policy "active members can read customers"
    on public.customers for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read daily_warehouse_reports" on public.daily_warehouse_reports;
create policy "active members can read daily_warehouse_reports"
    on public.daily_warehouse_reports for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read dispatch_lines" on public.dispatch_lines;
create policy "active members can read dispatch_lines"
    on public.dispatch_lines for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read dispatches" on public.dispatches;
create policy "active members can read dispatches"
    on public.dispatches for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read goods_receipts" on public.goods_receipts;
create policy "active members can read goods_receipts"
    on public.goods_receipts for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read order_imports" on public.order_imports;
create policy "active members can read order_imports"
    on public.order_imports for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read production_records" on public.production_records;
create policy "active members can read production_records"
    on public.production_records for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read products" on public.products;
create policy "active members can read products"
    on public.products for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read stock_movements" on public.stock_movements;
create policy "active members can read stock_movements"
    on public.stock_movements for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read warehouse_memberships" on public.warehouse_memberships;
create policy "active members can read warehouse_memberships"
    on public.warehouse_memberships for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read warehouse_transfer_lines" on public.warehouse_transfer_lines;
create policy "active members can read warehouse_transfer_lines"
    on public.warehouse_transfer_lines for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read warehouse_transfers" on public.warehouse_transfers;
create policy "active members can read warehouse_transfers"
    on public.warehouse_transfers for select to authenticated
    using (public.is_active_operational_company_member(company_id));

drop policy if exists "active members can read warehouses" on public.warehouses;
create policy "active members can read warehouses"
    on public.warehouses for select to authenticated
    using (public.is_active_operational_company_member(company_id));

commit;

-- WMS operational schema
-- Migration: 20261018150000_warehouse_operations.sql
-- Depends on 20261018135001_initial_schema.sql.
-- Operational writes will be added through reviewed transactional database
-- functions; client roles are intentionally read-only for these tables.

create table public.warehouses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  code text not null,
  name text not null,
  address text,
  is_active boolean not null default true,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, code),
  unique (company_id, id),
  check (length(trim(code)) > 0),
  check (length(trim(name)) > 0)
);

create table public.warehouse_memberships (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  warehouse_id uuid not null,
  membership_id uuid not null references public.company_memberships(id) on delete restrict,
  created_at timestamptz not null default now(),
  foreign key (company_id, warehouse_id) references public.warehouses(company_id, id) on delete restrict,
  unique (warehouse_id, membership_id)
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  sku text not null,
  name text not null,
  description text,
  unit_of_measure text not null default 'unit',
  is_active boolean not null default true,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, sku),
  unique (company_id, id),
  check (length(trim(sku)) > 0),
  check (length(trim(name)) > 0),
  check (length(trim(unit_of_measure)) > 0)
);

-- Production records are references only; they do not create stock.
-- Each filling sheet identifies exactly one product and one batch.
create table public.production_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  production_reference text not null,
  filling_sheet_number text not null,
  product_id uuid not null,
  batch_number text not null,
  expected_quantity numeric(14,3) not null check (expected_quantity > 0),
  production_date date not null,
  notes text,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  foreign key (company_id, product_id) references public.products(company_id, id) on delete restrict,
  unique (company_id, filling_sheet_number),
  unique (company_id, id),
  check (length(trim(production_reference)) > 0),
  check (length(trim(filling_sheet_number)) > 0),
  check (length(trim(batch_number)) > 0)
);

create table public.goods_receipts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  warehouse_id uuid not null,
  production_record_id uuid not null,
  receipt_reference text not null,
  received_quantity numeric(14,3) not null check (received_quantity >= 0),
  accepted_quantity numeric(14,3) not null check (accepted_quantity >= 0 and accepted_quantity <= received_quantity),
  discrepancy_note text,
  status text not null default 'draft' check (status in ('draft','posted','voided')),
  idempotency_key text not null,
  received_by uuid not null references auth.users(id) on delete restrict,
  received_at timestamptz not null default now(),
  posted_at timestamptz,
  foreign key (company_id, warehouse_id) references public.warehouses(company_id, id) on delete restrict,
  foreign key (company_id, production_record_id) references public.production_records(company_id, id) on delete restrict,
  unique (company_id, idempotency_key),
  unique (company_id, id),
  check (length(trim(receipt_reference)) > 0),
  check (status <> 'posted' or posted_at is not null)
);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  customer_code text,
  name text not null,
  phone text,
  email text,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, id),
  check (length(trim(name)) > 0)
);
create unique index customers_company_code_uq on public.customers(company_id, customer_code)
  where customer_code is not null and length(trim(customer_code)) > 0;

create table public.order_imports (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  source_filename text,
  source_checksum text not null,
  imported_by uuid not null references auth.users(id) on delete restrict,
  imported_at timestamptz not null default now(),
  row_count integer not null default 0 check (row_count >= 0),
  status text not null default 'received' check (status in ('received','validated','completed','failed')),
  error_summary text,
  unique (company_id, source_checksum),
  unique (company_id, id)
);

create table public.customer_orders (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  customer_id uuid not null,
  order_import_id uuid,
  approval_number text not null,
  order_category text not null check (order_category in ('retail','reseller','industrial')),
  order_date date,
  status text not null default 'approved' check (status in ('approved','partially_dispatched','dispatched','cancelled')),
  source_row_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (company_id, customer_id) references public.customers(company_id, id) on delete restrict,
  foreign key (company_id, order_import_id) references public.order_imports(company_id, id) on delete restrict,
  unique (company_id, approval_number),
  unique (company_id, id),
  check (length(trim(approval_number)) > 0)
);

create table public.customer_order_lines (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  customer_order_id uuid not null,
  product_id uuid not null,
  approved_quantity numeric(14,3) not null check (approved_quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  created_at timestamptz not null default now(),
  foreign key (company_id, customer_order_id) references public.customer_orders(company_id, id) on delete restrict,
  foreign key (company_id, product_id) references public.products(company_id, id) on delete restrict,
  unique (company_id, id)
);

create table public.dispatches (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  warehouse_id uuid not null,
  customer_order_id uuid not null,
  actual_invoice_number text not null,
  status text not null default 'draft' check (status in ('draft','posted','voided')),
  idempotency_key text not null,
  dispatched_by uuid not null references auth.users(id) on delete restrict,
  dispatched_at timestamptz not null default now(),
  posted_at timestamptz,
  foreign key (company_id, warehouse_id) references public.warehouses(company_id, id) on delete restrict,
  foreign key (company_id, customer_order_id) references public.customer_orders(company_id, id) on delete restrict,
  unique (company_id, idempotency_key),
  unique (company_id, actual_invoice_number),
  unique (company_id, id),
  check (length(trim(actual_invoice_number)) > 0),
  check (status <> 'posted' or posted_at is not null)
);

create table public.dispatch_lines (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  dispatch_id uuid not null,
  customer_order_line_id uuid not null,
  dispatched_quantity numeric(14,3) not null check (dispatched_quantity > 0),
  created_at timestamptz not null default now(),
  foreign key (company_id, dispatch_id) references public.dispatches(company_id, id) on delete restrict,
  foreign key (company_id, customer_order_line_id) references public.customer_order_lines(company_id, id) on delete restrict,
  unique (dispatch_id, customer_order_line_id)
);

create table public.warehouse_transfers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  transfer_reference text not null,
  source_warehouse_id uuid not null,
  destination_warehouse_id uuid not null,
  status text not null default 'draft' check (status in ('draft','in_transit','partially_received','received','cancelled')),
  idempotency_key text not null,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  dispatched_by uuid references auth.users(id) on delete restrict,
  dispatched_at timestamptz,
  received_by uuid references auth.users(id) on delete restrict,
  received_at timestamptz,
  foreign key (company_id, source_warehouse_id) references public.warehouses(company_id, id) on delete restrict,
  foreign key (company_id, destination_warehouse_id) references public.warehouses(company_id, id) on delete restrict,
  unique (company_id, transfer_reference),
  unique (company_id, idempotency_key),
  unique (company_id, id),
  check (source_warehouse_id <> destination_warehouse_id),
  check (length(trim(transfer_reference)) > 0)
);

create table public.warehouse_transfer_lines (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  transfer_id uuid not null,
  product_id uuid not null,
  sent_quantity numeric(14,3) not null check (sent_quantity > 0),
  received_quantity numeric(14,3) check (received_quantity is null or received_quantity >= 0),
  discrepancy_note text,
  created_at timestamptz not null default now(),
  foreign key (company_id, transfer_id) references public.warehouse_transfers(company_id, id) on delete restrict,
  foreign key (company_id, product_id) references public.products(company_id, id) on delete restrict,
  unique (transfer_id, product_id)
);

-- Append-only ledger: current stock is the sum of signed movements.
create table public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  warehouse_id uuid not null,
  product_id uuid not null,
  movement_type text not null check (movement_type in ('receipt','dispatch','transfer_out','transfer_in','adjustment','reversal')),
  quantity_delta numeric(14,3) not null check (quantity_delta <> 0),
  source_table text not null,
  source_id uuid not null,
  idempotency_key text not null,
  recorded_by uuid not null references auth.users(id) on delete restrict,
  recorded_at timestamptz not null default now(),
  notes text,
  foreign key (company_id, warehouse_id) references public.warehouses(company_id, id) on delete restrict,
  foreign key (company_id, product_id) references public.products(company_id, id) on delete restrict,
  unique (company_id, idempotency_key)
);
create index stock_movements_balance_idx on public.stock_movements(company_id, warehouse_id, product_id, recorded_at);
create index production_records_product_batch_idx on public.production_records(company_id, product_id, batch_number);
create index customer_orders_customer_status_idx on public.customer_orders(company_id, customer_id, status);
create index dispatches_order_idx on public.dispatches(company_id, customer_order_id);
create index transfers_source_status_idx on public.warehouse_transfers(company_id, source_warehouse_id, status);

create table public.daily_warehouse_reports (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  warehouse_id uuid not null,
  report_date date not null,
  submitted_by uuid not null references auth.users(id) on delete restrict,
  submitted_at timestamptz not null default now(),
  opening_notes text,
  closing_notes text,
  reported_zero_activity boolean not null default false,
  foreign key (company_id, warehouse_id) references public.warehouses(company_id, id) on delete restrict,
  unique (company_id, warehouse_id, report_date)
);

create table public.audit_events (
  id bigint generated always as identity primary key,
  company_id uuid not null references public.companies(id) on delete restrict,
  actor_user_id uuid references auth.users(id) on delete restrict,
  event_type text not null,
  entity_table text not null,
  entity_id uuid,
  request_id text,
 details jsonb not null default jsonb_build_object(),
  occurred_at timestamptz not null default now()
);
create index audit_events_company_time_idx on public.audit_events(company_id, occurred_at desc);

-- RLS is enabled on every operational table. Read-only direct access is granted
-- to authenticated clients; all writes are reserved for trusted DB functions.
do $$
declare t text;
begin
  foreach t in array array[
    'warehouses','warehouse_memberships','products','production_records','goods_receipts',
    'customers','order_imports','customer_orders','customer_order_lines','dispatches',
    'dispatch_lines','warehouse_transfers','warehouse_transfer_lines','stock_movements',
    'daily_warehouse_reports','audit_events'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on table public.%I from anon, authenticated', t);
    execute format('grant select on table public.%I to authenticated', t);
    execute format('create policy %I on public.%I for select to authenticated using (public.is_active_company_member(company_id))', 'active members can read ' || t, t);
  end loop;
end $$;

create view public.stock_balances with (security_invoker = true) as
select company_id, warehouse_id, product_id, sum(quantity_delta)::numeric(14,3) as quantity_on_hand
from public.stock_movements
group by company_id, warehouse_id, product_id;
grant select on public.stock_balances to authenticated;
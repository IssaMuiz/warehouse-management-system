# WMS Database Design

**Status:** Proposed — pending implementation and validation  
**Version:** 0.1

## 1. Purpose

Define the initial relational database design for a secure, multi-company Warehouse Management System.

The database will use Supabase PostgreSQL. All stock-changing operations must be validated and processed through trusted server-side logic.

This document describes the proposed logical schema. Exact SQL types, constraints, indexes, policies and transaction functions will be defined during implementation.

## 2. Design Principles

- Every company's business records must be isolated from other companies.
- Warehouse access must be explicitly assigned and enforced.
- Primary keys will use UUIDs for internal records unless a justified alternative is required.
- Business references, including approval numbers, filling sheet numbers and invoice numbers, must be preserved.
- External reference uniqueness must be scoped appropriately to the source system and company.
- Quantities must use suitable numeric types and explicit units of measure.
- Posted stock movements must be auditable and protected against duplicate processing.
- Stock balances must be derived from validated movements.
- Posted transactions must not be silently overwritten or deleted.
- Critical transactions must be atomic.
- Imported data must retain source references and import history.

## 3. Company, User and Access Tables

### 3.1 companies

Represents each organisation using the platform.

Proposed fields:
- id
- name
- status
- created_at

### 3.2 profiles

Links an authenticated Supabase user to application-level profile information.

Proposed fields:
- id, matching the Supabase Auth user ID
- display_name
- created_at

### 3.3 company_memberships

Associates users with companies and their company-level roles.

Proposed fields:
- id
- company_id
- user_id
- role
- status
- created_at

A user may belong to more than one company if authorised.

### 3.4 warehouses

Represents physical warehouses belonging to a company.

Proposed fields:
- id
- company_id
- warehouse_code
- name
- address
- status
- created_at

Warehouse codes must be unique within their company.

### 3.5 warehouse_memberships

Associates company members with their permitted warehouses.

Proposed fields:
- id
- company_membership_id
- warehouse_id
- created_at

Server-side checks must validate both company membership and warehouse access.

Platform administrators, company administrators and warehouse staff must have separate, explicitly defined permissions.

## 4. Products and Batches

### 4.1 products

Defines products managed by each company.

Proposed fields:
- id
- company_id
- product_code
- name
- description
- base_unit_of_measure
- category
- status
- created_at

Product codes must be unique within their company.

### 4.2 product_batches

Represents identifiable batches of a product.

Proposed fields:
- id
- company_id
- product_id
- batch_number
- created_at

Batch numbers must follow the company's verified uniqueness rules.

Inventory must be traceable by product and batch whenever batch tracking is required.

## 5. Production and Filling Sheets

### 5.1 production_records

Records production reported by the production manager.

Proposed fields:
- id
- company_id
- production_reference
- production_date
- recorded_by
- created_at

### 5.2 filling_sheets

Records the product, batch and quantity associated with a filling sheet.

Proposed fields:
- id
- company_id
- production_record_id
- filling_sheet_number
- product_id
- product_batch_id
- produced_quantity
- unit_of_measure
- created_at

Each filling sheet must contain exactly one product and one batch.

The production record is not itself a stock movement.

### 5.3 production_receipts

Records the warehouse's physical receipt against a filling sheet.

Proposed fields:
- id
- company_id
- filling_sheet_id
- receiving_warehouse_id
- expected_quantity_snapshot
- actual_received_quantity
- accepted_quantity
- discrepancy_quantity
- status
- received_by
- received_at
- idempotency_key

A successfully posted receipt increases stock only by the quantity accepted under the approved receiving rules.

A filling sheet must not be received twice unless the business explicitly approves a separate, controlled process for multiple receipts.

## 6. Customers and Customer-Service Orders

### 6.1 customers

Represents customers belonging to a company.

Proposed fields:
- id
- company_id
- customer_code, where available
- name
- customer_category
- status
- created_at

Customer categories initially include retail, reseller and industrial.

### 6.2 order_import_batches

Tracks each customer-service spreadsheet import.

Proposed fields:
- id
- company_id
- source_system
- source_file_name
- file_fingerprint
- status
- imported_by
- imported_at
- error_summary

Import history must identify successful, failed and partially processed imports.

### 6.3 customer_orders

Represents the approved order originating from customer service.

Proposed fields:
- id
- company_id
- customer_id
- approval_number
- order_date
- status
- source_import_batch_id
- created_at

Approval numbers must originate from authorised source records and must not be invented by the WMS.

### 6.4 customer_order_lines

Represents the approved products and quantities for an order.

Proposed fields:
- id
- customer_order_id
- line_number
- product_id
- approved_quantity
- unit_of_measure
- approved_unit_price, where supplied and required
- created_at

The source order and its line details must remain traceable.

Partial fulfilment, amendments, cancellations and reservations must follow the confirmed company rules.

## 7. Sales and Dispatch

### 7.1 dispatches

Represents an actual dispatch from a warehouse.

Proposed fields:
- id
- company_id
- warehouse_id
- customer_order_id, where applicable
- customer_id
- invoice_number
- dispatch_type
- status
- dispatched_by
- dispatched_at
- idempotency_key

The invoice number is distinct from the customer-service approval number.

The design must support multiple dispatches against one approval number if the company's confirmed process allows partial fulfilment.

Invoice uniqueness must follow the company's actual numbering rules.

### 7.2 dispatch_lines

Represents individual products dispatched on an invoice.

Proposed fields:
- id
- dispatch_id
- product_id
- product_batch_id, where applicable
- order_line_id, where applicable
- dispatched_quantity
- unit_of_measure
- unit_price, where applicable

A posted dispatch deducts its validated quantities from the issuing warehouse.

Order fulfilment totals must be calculated or maintained through trusted logic so cumulative dispatches cannot exceed authorised quantities without an approved amendment.

## 8. Inter-Warehouse Transfers

### 8.1 transfers

Represents a transfer between two warehouses belonging to the same company.

Proposed fields:
- id
- company_id
- source_warehouse_id
- destination_warehouse_id
- transfer_reference
- status
- initiated_by
- approved_by, where applicable
- dispatched_at
- received_at
- idempotency_key

The source and destination warehouses must be different.

Transfer references must be unique within their defined company scope.

### 8.2 transfer_lines

Represents products and quantities on a transfer.

Proposed fields:
- id
- transfer_id
- product_id
- product_batch_id, where applicable
- dispatched_quantity
- received_quantity
- unit_of_measure

Dispatch and receipt quantities must be recorded separately.

### 8.3 transfer_receipts

Records receipt events at the destination warehouse.

Proposed fields:
- id
- company_id
- transfer_id
- received_by
- received_at
- status
- idempotency_key

The data model must support discrepancy records and the controlled resolution of short, excess or damaged receipts.

Transfers are inventory movements, not sales.

## 9. Stock Ledger

### 9.1 stock_movements

An append-only ledger of posted inventory changes.

Proposed fields:
- id
- company_id
- warehouse_id
- product_id
- product_batch_id, where applicable
- movement_type
- quantity_delta
- unit_of_measure
- source_document_type
- source_document_id
- source_line_id, where applicable
- reversal_of_movement_id, where applicable
- posted_by
- posted_at
- idempotency_key

Positive quantities increase stock; negative quantities decrease stock.

Only trusted transaction logic may create posted stock movements.

Corrections must use controlled reversal or adjustment movements rather than modifying historical movements.

### 9.2 Transfer stock treatment

When a transfer is dispatched, the source warehouse must lose the dispatched quantity.

The corresponding quantity must be accounted for as in-transit inventory so that it is not incorrectly treated as available at either warehouse.

When the destination accepts the receipt, the accepted quantity enters destination stock. Remaining in-transit quantities and discrepancies must remain traceable until resolved.

The detailed ledger representation of in-transit inventory will be finalised before writing the stock-posting functions.

### 9.3 Stock balance views

The initial authoritative record is the posted stock ledger.

A database view may calculate stock by company, warehouse, product and batch. If performance later requires a stored balance projection, it must be maintained transactionally and reconciled against the ledger.

Users must not edit stock balances directly.

## 10. Discrepancies and Adjustments

### 10.1 inventory_discrepancies

Tracks receiving, transfer and stock-count exceptions.

Proposed fields:
- id
- company_id
- warehouse_id
- related_document_type
- related_document_id
- discrepancy_type
- expected_quantity
- actual_quantity
- status
- reported_by
- resolved_by, where applicable
- resolution_notes
- created_at
- resolved_at

### 10.2 stock_adjustments

Records authorised stock corrections.

Proposed fields:
- id
- company_id
- warehouse_id
- adjustment_reference
- reason
- status
- requested_by
- approved_by, where applicable
- posted_at

Adjustment lines and resulting stock movements must be recorded separately.

An adjustment must not change stock until it has passed the required approval and posting checks.

## 11. Daily Operational Reports

### 11.1 warehouse_daily_reports

Stores the operational report for a warehouse and business date.

Proposed fields:
- id
- company_id
- warehouse_id
- report_date
- activity_status
- submitted_by
- submitted_at
- status

The activity status must distinguish activity, explicitly reported zero activity, and no report submitted.

A unique company/warehouse/report-date combination should prevent duplicate daily reports, subject to any approved correction workflow.

Report details can be expanded once the required reporting fields are confirmed.

## 12. Audit History

### 12.1 audit_events

Records important security and business events.

Proposed fields:
- id
- company_id, where applicable
- actor_user_id, where applicable
- action
- entity_type
- entity_id
- occurred_at
- metadata, containing approved non-sensitive details

Audit records must not expose secrets or unnecessarily duplicate sensitive customer information.

Critical audit events must be written through trusted server-side logic. Ordinary application users must not be able to alter or delete audit history.

## 13. Relationships Summary

- A company has many users, warehouses, products and business records.
- Users gain company permissions through company memberships.
- Company members gain warehouse access through warehouse memberships.
- Products may have multiple batches.
- Production records contain filling sheets.
- Filling sheets identify one product and one batch.
- Production receipts reference filling sheets.
- Customers have customer-service orders.
- Orders contain order lines.
- Dispatches may reference an order and contain dispatch lines.
- Transfers connect a source warehouse to a destination warehouse and contain transfer lines.
- Transfer receipts record the receiving process.
- Posted transactions create stock movements.
- Discrepancies and adjustments retain links to their source documents.
- Daily reports belong to a company, warehouse and business date.

## 14. Security and Integrity Requirements

- Apply Row Level Security to company-owned data exposed through the Supabase API.
- Validate company membership and warehouse permissions on the server.
- Use restrictive policies and trusted server-side functions for privileged operations.
- Prevent untrusted clients from directly inserting arbitrary posted stock movements.
- Protect imports and transaction endpoints against replay and duplicate submissions.
- Use database constraints and foreign keys to protect relationships.
- Validate quantities and stock availability inside the transaction that posts the movement.
- Use database transactions and appropriate locking or conditional updates to prevent concurrent overselling.
- Keep schema changes in version-controlled SQL migrations.
- Test access isolation using users from different companies and warehouses.

## 15. Items Requiring Confirmation

Before finalising the schema and implementing SQL, confirm:

1. The actual customer-service spreadsheet columns and identifier rules.
2. Whether an approval number can have multiple dispatch invoices.
3. Whether orders reserve stock.
4. How batches are selected during dispatch.
5. Whether filling sheets can have more than one receipt event.
6. Transfer approval rules and discrepancy resolution.
7. Required daily report fields and submission deadlines.
8. Company-specific invoice numbering and fiscal requirements.
9. Units of measure, product conversions and decimal precision.
10. Whether stock counts, damaged stock and quarantine require dedicated workflows.

## 16. Implementation Status

This document is a proposed logical design, not an implemented schema.

SQL migrations, indexes, Row Level Security policies, database functions and automated tests will be created and reviewed before the database is used operationally.

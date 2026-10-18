# Warehouse Management System (WMS)

## 1. Project Overview

The Warehouse Management System (WMS) is a mobile-first, multi-warehouse application designed to manage inventory movements and warehouse operations across a company operating multiple locations.

The initial implementation will focus on lubricant distribution and warehousing, while maintaining an architecture that can support other industries in the future.

## 2. Business Objectives

- Maintain accurate stock balances across multiple warehouses.
- Record finished production and verify quantities received into the central warehouse.
- Import approved customer-service orders and fulfil them during dispatch.
- Record sales by customer category: retail, reseller and industrial.
- Manage inter-warehouse transfers, including dispatch, transit and receipt.
- Capture discrepancies, damaged goods and authorised stock adjustments.
- Produce daily warehouse reports, including explicit zero-activity reports.
- Maintain traceable records of stock movements and user actions.
- Provide secure access from Android and iOS devices.

## 3. Proposed Technology Stack

- **Frontend:** Lovable-generated, mobile-first Progressive Web App (PWA).
- **Backend and database:** Supabase with PostgreSQL.
- **Authentication and access control:** Supabase Auth and Row Level Security (RLS).
- **Automation and integrations:** n8n.
- **Version control and documentation:** GitHub.
- **Business transaction processing:** Database transactions and trusted server-side logic, selected according to each operation's security and consistency requirements.

A native Android or iOS application may be considered later if operational requirements justify it.

## 4. Core Modules

1. Company and user management.
2. Warehouse and product management.
3. Production records and production receipt.
4. Customer-service order import and dispatch.
5. Sales and invoice recording.
6. Inter-warehouse transfers.
7. Stock ledger, adjustments and discrepancy management.
8. Daily operational reporting.
9. Audit history and operational monitoring.

## 5. Core Business Rules

- Stock balances must be derived from validated stock movements, not edited directly.
- A production record does not increase warehouse stock by itself.
- Stock increases only when an authorised production receipt is successfully posted.
- Customer-service approval numbers originate from the company's approved order records; the WMS must not invent them.
- Actual dispatch invoices must be recorded separately from approval numbers.
- Transfers are inventory movements, not sales.
- Transfer quantities dispatched and quantities received must be recorded separately.
- Duplicate imports, repeated submissions and retries must not create duplicate transactions.
- Partial fulfilment, cancellation, discrepancies and stock adjustments must follow approved business rules.
- Users may access only the companies, warehouses and functions permitted by their assigned roles.
- Important stock changes must be auditable and corrected through controlled transactions rather than silently overwritten.

## 6. Development Principles

- Mobile-first user experience.
- Secure, multi-company architecture.
- Explicit permissions and server-side validation.
- Atomic stock transactions and duplicate protection.
- Traceable records and controlled reversals.
- Separate development and production environments.
- Tested database migrations and workflow changes.
- Documented backups, recovery and deployment procedures.
- No real credentials, access tokens or confidential operational data in GitHub.

## 7. Development Roadmap

### Phase 1 — Project Foundation and Architecture
Establish project documentation, repository structure, business rules, system architecture and development conventions.

### Phase 2 — Database and Security Foundation
Design the database, company isolation, user roles, warehouse permissions, audit records and stock ledger foundations.

### Phase 3 — Core Application
Build authentication, navigation, mobile layouts, company administration, warehouse management and product management.

### Phase 4 — Production and Warehouse Receiving
Record production outputs and filling sheets, then validate and post actual quantities received into the central warehouse.

### Phase 5 — Customer-Service Orders and Dispatch
Import approved orders, prevent duplicate imports, validate fulfilment and record actual dispatch invoices and quantities.

### Phase 6 — Inter-Warehouse Transfers
Implement transfer requests, authorisation rules, dispatch, in-transit stock, destination receipt and discrepancy handling.

### Phase 7 — Stock Control and Adjustments
Implement stock reconciliation, damage reporting, controlled adjustments and transaction history.

### Phase 8 — Daily Reporting and Automation
Generate warehouse operational reports, consolidate reports for management and implement required n8n automations.

### Phase 9 — Testing and Operational Validation
Test security, permissions, duplicate submissions, concurrent transactions, stock accuracy, mobile usability and recovery procedures.

### Phase 10 — Production Deployment
Configure production hosting, secure credentials, backups, monitoring, user onboarding and controlled rollout.

Phases may be refined as the business rules and operational documents are verified.

## 8. n8n Workflow Documentation

Each significant n8n workflow will have:

- An exported workflow JSON file, reviewed before committing.
- A Markdown document describing its purpose, trigger, inputs, nodes, outputs, permissions, error handling and dependencies.
- Test cases with expected results.
- Setup instructions identifying required credentials by name, without exposing secret values.
- A record of significant changes.

Workflow exports must be checked for secrets and sensitive data before being committed.

## 9. Current Project Status

**Status:** Initial setup and architecture planning.

The GitHub repository has been created. Implementation will proceed phase by phase, with each phase documented and tested before it is considered complete.

## 10. Completion Standard

A feature is not considered complete merely because its interface works. It must also satisfy its business rules, enforce permissions, handle errors and retries safely, preserve stock accuracy, and pass its defined tests.

## 11. Ownership and Maintenance

Repository: https://github.com/IssaMuiz/warehouse-management-system

Project documentation and implementation decisions will be maintained in this repository.

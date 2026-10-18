# Warehouse Management System (WMS)
## Phase 1 Progress Report — Core Database & Security Foundation

**Project:** Warehouse Management System  
**Repository:** https://github.com/IssaMuiz/warehouse-management-system  
**Backend:** Supabase (PostgreSQL, Auth, Row-Level Security)  
**Phase:** 1 — Core Database & Security Foundation  
**Status:** Foundation implemented; security inspection completed, with runtime tests outstanding  
**Date:** 18 October 2026

---

## 1. Phase Objective

Establish a secure, version-controlled database foundation for the WMS before implementing authentication workflows, company onboarding, warehouse management and daily operations.

The database must support multiple companies while keeping their operational data isolated. Access must be governed by user roles, company membership and, where applicable, warehouse assignment.

Critical business rules must ultimately be enforced by the backend and database, not solely by the user interface.

## 2. Environment and Project Setup

- Created the GitHub repository for the WMS.
- Set up the local project and Supabase migration structure.
- Connected the local project to the cloud Supabase project `wms-development`.
- Confirmed that the Supabase CLI was installed, authenticated and linked to the project.
- Applied the database migrations to the cloud project.
- Local Supabase startup was unsuccessful because Docker image downloads encountered TLS timeouts. Cloud Supabase was used instead.
- Existing NovaMart Docker containers and volumes were preserved; they were not rebuilt or deleted for this project.

## 3. Database Structure Implemented

### Foundation tables

- `profiles` — user profile information.
- `platform_admins` — separate platform-administrator authority.
- `companies` — company records and approval status.
- `company_memberships` — user membership and company-level roles.

### Operational tables

The database schema also includes the foundation for:

- Warehouses and warehouse memberships.
- Products.
- Production records and goods receipts.
- Customers, order imports, customer orders and order lines.
- Dispatches and dispatch lines.
- Warehouse transfers and transfer lines.
- Stock movements and stock balances.
- Daily warehouse reports.
- Audit events.

The `stock_movements` table is designed as an append-only stock ledger. Supported movement types include receipts, dispatches, transfers, adjustments and reversals. An idempotency key is constrained within each company to help prevent duplicate movement entries.

The `stock_balances` view calculates balances from stock movements and uses `security_invoker = true`.

**Important:** The schema provides the data foundation for these operations. It does not mean every operational workflow or transaction function has already been implemented and tested.

## 4. Database Migrations Applied

The following migrations were applied to the cloud database:

1. `20261018135001_initial_schema.sql`
2. `20261018150000_warehouse_operations.sql`
3. `20261018170000_role_foundation.sql`
4. `20261018175500_wms_authorization_helpers.sql`
5. `20261018190000_operational_company_status_access.sql`

These migrations establish the initial schema, operational tables, role foundations, warehouse authorization helper and approved-company access rules.

## 5. Role and Access-Control Foundation

The intended company-level roles are:

- `warehouse_manager`
- `warehouse_executive`
- `auditor`
- `production_manager`
- `member`

Legacy role values remain in the database for controlled transition. The legacy `company_admin` role has not been silently treated as equivalent to `warehouse_manager`.

Platform administrators are maintained separately from ordinary company memberships.

### Role requirements represented in the database

- Maximum of two active warehouse managers per company.
- Maximum of two active warehouse executives per warehouse.
- Warehouse managers have company-wide operational scope.
- Warehouse executives require assignment to the warehouse they operate in.
- Warehouse assignment limits operational actions, not company-wide read access.
- Auditors and general members are intended to have read-only access to company records.
- Production records alone must not increase stock; accepted goods receipts must be the mechanism for recording received stock.
- Managers must approve transfers before dispatch, and executives must not be able to approve transfers or approve their own actions.

Database triggers have been implemented for manager and executive assignment limits. The warehouse authorization helper has been implemented to check approved-company status, active membership, warehouse activity and the applicable manager or executive scope.

**Implementation boundary:** These requirements still need to be enforced and tested throughout the relevant transaction functions and workflows as those phases are developed.

## 6. Row-Level Security and Database Permissions

### RLS implementation

- Row-Level Security is enabled on all 20 public base tables.
- Operational-table SELECT policies were updated to use `is_active_operational_company_member(company_id)`.
- This helper checks that the user has an active membership and that the company is approved.
- Company membership visibility remains available through the separate membership helper, allowing users to view their own company membership and status where permitted.
- Warehouse assignment does not restrict company-wide operational reads for active members of approved companies.

### Client privileges

Privilege checks confirmed that, among the tables and views inspected:

- `anon` has no direct SELECT, INSERT, UPDATE or DELETE privileges on the checked tables.
- Authenticated clients have SELECT privileges on the operational tables.
- Authenticated clients do not have direct INSERT, UPDATE or DELETE privileges on the inspected operational tables.
- Direct INSERT and UPDATE privileges on `companies` and `company_memberships` are constrained by RLS policies.
- Client DELETE privileges were not granted on the inspected public tables.

These findings describe the inspected table privileges and policies. They are not a substitute for end-to-end authorization testing.

### Security-definer functions reviewed

The following functions were inspected:

- `is_platform_admin()`
- `is_active_company_member(uuid)`
- `is_active_operational_company_member(uuid)`
- `has_company_role(uuid, text[])`
- `can_operate_warehouse(uuid, uuid)`
- `enforce_wms_role_assignment_limits()`
- `handle_new_user()`
- `rls_auto_enable()`

The relevant functions use restricted search paths. The role-limit enforcement function is not executable directly by ordinary authenticated or anonymous API roles according to the inspected privileges.

The `handle_new_user()` function is attached to `on_auth_user_created` on `auth.users` and creates a profile when a user signs up.

The `rls_auto_enable()` function is attached to the enabled `ensure_rls` event trigger, owned by `postgres`, which runs at `ddl_command_end` for the configured table-creation commands. Its definition enables RLS on newly created tables in the `public` schema.

No function changes or permission revocations were made solely because these functions appeared in the security inspection.

## 7. Initial Administrative Setup

- A platform-administrator account was established in Supabase Auth.
- Its user was registered in the `platform_admins` table through the trusted SQL Editor.
- At the time of the last count check, no company, company membership, warehouse or warehouse-membership records had been created.

This means the role and authorization foundation has been inspected without relying on test companies or operational records.

## 8. Verification Completed

The following checks were performed:

- Confirmed that the role constraint includes the intended new roles and retained legacy roles.
- Confirmed the central-warehouse flag and the unique constraint allowing no more than one central warehouse per company.
- Inspected role-limit triggers and their associated functions.
- Inspected the warehouse-operation authorization helper and its execution privileges.
- Confirmed the operational SELECT policies on all 16 operational tables inspected.
- Reviewed table-level client privileges and RLS enablement.
- Inspected public security-definer functions, their definitions, ownership and search paths.
- Verified the signup trigger's attachment to `auth.users`.
- Verified the RLS automation event trigger and its configured commands.

## 9. Outstanding Work Before Production

The foundation is implemented, but the following work remains.

### Security and authorization tests

- Test that an unauthenticated visitor cannot access protected company data.
- Test that one company cannot read another company's operational records.
- Test access for active, pending, suspended and rejected company states.
- Test every role's allowed and denied actions.
- Test that warehouse executives cannot perform operational actions outside their assigned warehouses.
- Test that warehouse managers can operate across their company's warehouses.
- Test that auditors and general members cannot post transactions.
- Test the manager and executive assignment limits, including concurrent attempts.
- Confirm that platform-admin authority does not automatically grant access to company operational records.

### Business-rule enforcement

- Implement and test secure transaction functions for stock receipts, dispatches, transfers and adjustments.
- Ensure transfer approval cannot be bypassed and self-approval is prevented.
- Ensure production registration does not itself increase stock.
- Ensure stock movements remain consistent, auditable and protected against duplicate posting.
- Confirm that all privileged database functions expose only the intended operations and validate the calling user's authority.

### Operational testing

- Reconcile stock balances against the stock ledger.
- Test transaction failures and rollback behaviour.
- Test audit-event creation and historical record preservation.
- Test the database through the actual application and authenticated API flows.

These checks must be completed in the appropriate implementation and testing phases before production use.

## 10. Important Technical Decisions

1. Supabase cloud is the current development database because local Supabase startup encountered Docker image download problems.
2. Database changes are managed through version-controlled migrations.
3. RLS and database permissions are used as security boundaries; frontend restrictions alone are insufficient.
4. Platform administration is separated from company operational authorization.
5. Company-wide read access is distinct from warehouse-specific operational permission.
6. Stock balances are derived from the stock ledger rather than treated as an independent source of truth.
7. Historical products and stock records must be preserved; deactivation and auditable corrections are preferred over destructive deletion.
8. Working configurations and data must not be deleted or rebuilt without a verified reason and an appropriate backup.

## 11. Phase 1 Conclusion

**Outcome:** The core database schema and principal security foundations have been implemented, migrated and inspected.

The project now has the foundation required to proceed to authentication, company onboarding and user management. However, Phase 1 should not be interpreted as a production security certification: several authorization and concurrency guarantees have been reviewed by inspecting SQL definitions rather than proved through runtime tests.

Those tests remain mandatory before production deployment.

## 12. Next Phase

**Phase 2 — Authentication, Company Onboarding & User Management**

The next phase should focus on user authentication, company creation and approval, membership onboarding, and controlled role assignment. Warehouse and stock-management workflows should remain in their later planned phases.

---

**Document status:** Phase 1 progress record  
**Prepared for:** WMS project documentation  
**Last updated:** 18 October 2026
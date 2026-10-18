# WMS System Architecture

## 1. Purpose

This document defines the proposed architecture for the Warehouse Management System (WMS). It establishes the responsibilities of the frontend, backend, database and automation layer before implementation begins.

## 2. Architecture Overview

The system will use four primary layers.

### 2.1 Frontend — Lovable

Responsibilities:
- Provide a mobile-first interface for Android and iOS users.
- Support warehouse receiving, dispatch, transfers and stock enquiries.
- Display records according to the authenticated user's permissions.
- Validate basic input before submitting requests.
- Clearly communicate successful operations, errors and pending actions.

The initial application will be a Progressive Web App (PWA), accessible through a mobile browser and installable on supported devices.

### 2.2 Backend and Database — Supabase

Responsibilities:
- Authenticate users.
- Store companies, warehouses, products, orders and operational records.
- Enforce company and warehouse access restrictions.
- Maintain stock movement records and audit history.
- Process critical stock transactions using trusted, transactional server-side logic.
- Prevent duplicate transaction posting.

Row Level Security (RLS) and server-side permission checks will be used together where appropriate.

### 2.3 Automation — n8n

Responsibilities may include:
- Importing approved customer-service order spreadsheets.
- Sending notifications.
- Generating and distributing scheduled reports.
- Running controlled integrations with external systems.
- Alerting authorised staff to exceptions.

Critical stock posting must not depend on an ordinary multi-step n8n workflow alone. Stock changes must be performed through a trusted transaction that guarantees consistency and duplicate protection.

### 2.4 Version Control — GitHub

Responsibilities:
- Maintain application source code.
- Store database migrations and technical documentation.
- Store reviewed n8n workflow exports and workflow documentation.
- Track changes and support recovery.
- Record development decisions and testing results.

## 3. Proposed Data Flow

1. A user signs in through the frontend.
2. The frontend submits an authenticated request.
3. Supabase and trusted backend logic validate the user's identity, permissions and business rules.
4. A valid transaction is committed atomically to the database.
5. The frontend displays the confirmed result.
6. n8n handles relevant follow-up automation where required.

## 4. Security Principles

- Each company must have isolated data.
- Warehouse staff must be restricted to their authorised warehouses.
- Administrative permissions must be explicitly assigned.
- Privileged credentials must never be embedded in frontend code.
- Stock transactions must be validated server-side.
- Sensitive operations must be recorded in an audit trail.
- Production and development credentials must be separate.
- External integrations must use securely managed credentials.

## 5. Stock Integrity

Stock balances will be derived from validated stock movements.

The system must distinguish between:
- Production recorded.
- Production physically received.
- Sales dispatched.
- Transfers dispatched.
- Transfers received.
- Adjustments and reversals.

Each stock-changing operation must define its validation rules, transaction boundary, duplicate protection and audit requirements before implementation.

## 6. Deployment Approach

Development and production environments will be separated.

Before production deployment, the project must have:
- Secure environment configuration.
- Database migration procedures.
- Tested backup and recovery procedures.
- Monitoring and error reporting.
- Defined access management.
- Tested workflows and application functionality.
- An operational rollout and support plan.

## 7. Decisions Still Requiring Confirmation

The following must be verified before the relevant modules are implemented:

- Customer-service order import format and approval rules.
- Sales and dispatch invoice requirements.
- Transfer approval and receipt rules.
- Treatment of partial fulfilment, cancellation and discrepancies.
- Production receipt and filling-sheet procedures.
- Warehouse reporting requirements.
- Stock adjustment authorisation.
- Expected connectivity and device requirements.

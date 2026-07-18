# FinanceVision Native Roadmap

> **STATUS: shelved (2026-07-07).** Deliberately paused, not abandoned. No native build work has started. Revisit only if the current Excel/Python/HTML workflow becomes a repeated, specific bottleneck (e.g. manual correction pain, spreadsheet fragility, review friction) — not for "nicer app" curiosity alone. Current workflow (`financas2026-DataEntry.xlsx` + `sync.py` + HTML dashboard) remains the operational system of record.

This file turns the current `financas-2026` workspace into a concrete build plan for a native Apple Silicon tool.

## Objective

Replace the current spreadsheet + Python + injected HTML workflow with a local-first macOS app that:

- imports the same local evidence already used in this repo
- preserves the current validated outputs
- adds a native review workflow
- keeps export compatibility during migration

The app target is `FinanceVision`.

## Current Source Of Truth

These assets are the reference system and must stay reproducible during migration:

- `/Users/eduardofgiovannini/Documents/financas-2026/financas2026-DataEntry.xlsx`
- `/Users/eduardofgiovannini/Documents/financas-2026/dashboard_data.json`
- `/Users/eduardofgiovannini/Documents/financas-2026/html/financas2026-Dashboard.html`
- `/Users/eduardofgiovannini/Documents/financas-2026/nfce`
- `/Users/eduardofgiovannini/Documents/financas-2026/mercado_pago`
- `/Users/eduardofgiovannini/Documents/financas-2026/mercado_livre_ifood`
- `/Users/eduardofgiovannini/Documents/financas-2026/banco_inter`
- `/Users/eduardofgiovannini/Documents/financas-2026/bcb_registrato`

## Product Boundary

FinanceVision should become a single native macOS app with these responsibilities:

- ingest PDFs, CSVs, images, and NFC-e XML folders
- parse them into a canonical local store
- surface validation issues and low-confidence rows
- let the user review and correct parsed results
- compute dashboard analytics and personal inflation
- export JSON and HTML snapshots when needed

What it should not be:

- a cloud service
- a Docker stack
- a web app rewrite
- an LLM-only parser with no deterministic fallback

## Key Constraint

The current HTML is still a static injected artifact. In the native app, the user-facing analysis must be live and configurable.

Minimum required control:

- the `Produtos rastreados` period must be user-configurable

That control should affect:

- visible product rows
- first/last price window
- category summaries
- exported filtered views

## Phases

## Phase 0 — Freeze The Reference System

Goal:

- document the real current contracts before changing behavior

Deliverables:

- canonical schema doc for transactions, balances, subscriptions, international ops, NFC-e items, and inflation outputs
- sample fixture inventory by source type
- parity checklist between native outputs and current outputs

Done when:

- a developer can tell which files are source evidence, which are derived artifacts, and which metrics must stay stable

## Phase 1 — Build The Native Core

Goal:

- create one reusable local engine behind the future app

Deliverables:

- `FinanceCore` for models and persistence
- `FinanceImport` for deterministic importers
- `FinanceAnalytics` for dashboard and inflation calculations
- preserved CLI entrypoint for batch runs and regression checks

Rules:

- deterministic parser first
- LLM assist second
- all imports traceable to source file path and checksum

Done when:

- the native code can persist canonical entities without depending on the workbook

## Phase 2 — Ship Deterministic Importers

Priority order:

1. Mercado Pago CSV and withdrawal CSV
2. NFC-e engine and product/inflation outputs
3. BCB/Registrato parsing
4. Mercado Pago PDFs
5. Banco Inter screenshots and image-heavy inputs
6. Mercado Livre / iFood evidence

Deliverables:

- importer registry
- per-import validation report
- duplicate detection
- malformed field handling
- source-linked error reporting

Done when:

- the majority of current data can enter the native store without spreadsheet mediation

## Phase 3 — Native Review Workflow

Goal:

- replace manual cleanup in spreadsheet and HTML editing with a real review UI

Deliverables:

- import queue
- source preview
- parsed row review
- confidence or validation flags
- edit-and-save flow
- reprocess capability for one source without rebuilding everything

Done when:

- manual correction happens in the app, not in `financas2026-DataEntry.xlsx`

## Phase 4 — Native Dashboard MVP

Screens:

- Overview
- Transactions
- Subscriptions
- Banks
- International
- NFC-e / Personal Inflation
- Validation

MVP requirements:

- local database-backed views
- filters and sorting
- source drill-down
- configurable tracked-product period on NFC-e views
- export current state to JSON and HTML snapshot

Done when:

- `sync.py` is no longer needed for normal weekly use

## Phase 5 — Legacy Parity And Cutover

Goal:

- preserve the current artifact outputs while changing the primary runtime

Deliverables:

- native export of dashboard JSON
- native export of HTML snapshot
- parity test comparing key headline metrics
- migration guide for weekly use

Done when:

- the native app becomes the default operational entrypoint

## Phase 6 — Remove Redundant Glue

Candidates for retirement after parity:

- workbook-driven orchestration
- hardcoded manual lists in Python ETL
- HTML as the primary interface
- ad hoc patch scripts used only to keep the artifact alive

Keep only if they still provide unique value:

- regression fixtures
- one-off recovery utilities
- archival exports

## MVP Definition

The first acceptable native release must do all of this locally:

- import PDFs, CSVs, images, and NFC-e folders
- persist canonical records in one local store
- show a native review queue
- render a native dashboard
- reproduce current NFC-e inflation outputs
- export JSON and HTML snapshots for continuity

If it cannot replace the normal use of `sync.py`, it is not the MVP yet.

## Guardrails

- preserve the validated NFC-e methodology unless a bug is proven
- keep migration reversible
- do not break current outputs before parity exists
- avoid introducing new infrastructure
- keep the app local-first even when cloud LLMs are available

## First Build Sequence

1. Write the canonical schema
2. Introduce local SQLite persistence
3. Move Mercado Pago CSV import to native
4. Wire NFC-e analytics into native storage
5. Build the review queue
6. Build native Overview and NFC-e screens
7. Add JSON/HTML export bridge
8. Migrate remaining importers

## Stop Conditions

Phase 1 stop:

- native core persists canonical data cleanly

MVP stop:

- app replaces `sync.py` for normal operation

Cutover stop:

- HTML becomes export-only, not the primary working surface

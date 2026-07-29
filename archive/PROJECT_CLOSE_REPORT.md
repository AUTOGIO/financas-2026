---
title: financas-2026 — Project Close Report
type: project-close-report
status: operational (Phase 1 complete, frozen for weekly maintenance)
date: 2026-07-07
owner: Eddie
repo_path: /Users/eduardofgiovannini/Documents/GitHub/financas-2026
generated_by: Claude (Cowork)
data_period_covered: Jan–Jun 2026
build_window: 2026-07-01 to 2026-07-07
system_of_record: financas2026-DataEntry.xlsx + sync.py + html/financas2026-Dashboard.html
related_files:
  - LEIA-ME.md
  - PHASES.md
  - FinanceVision/NATIVE_APP_ARCHITECTURE.md
  - FINANCEVISION_CLOSE_REPORT.md
repo_size: 354M
file_count: 1767
git_commits: 1
git_remote: none
reviewed_by: none (single-operator project)
---

# financas-2026 — Project Close Report

## Purpose

Closes out Phase 1 of the personal finance tracking project: what was built, what it verifiably contains, what's unresolved, and what decisions are already locked in. This is a status snapshot, not a plan — it documents actual repo state as inspected on 2026-07-07.

## Status Summary

| Track | State |
|---|---|
| Phase 1 — Excel + Python + HTML dashboard | ✅ Operational, frozen for weekly maintenance |
| Phase 2 — Native Swift rewrite (per `LEIA-ME.md` criteria) | ⏸ Not triggered — criteria unmet |
| FinanceVision CLI prototype (small OCR+LLM parser) | 🟡 Built, functional-looking, **uncommitted, unverified against production data** |
| FinanceVision full native app (`PHASES.md` roadmap) | ⏸ Shelved 2026-07-07 — see `FINANCEVISION_CLOSE_REPORT.md` |

## What Exists (verified inventory)

| Component | Path | Role |
|---|---|---|
| Data entry workbook | `financas2026-DataEntry.xlsx` (11 sheets, hand-maintained) | Primary input surface |
| Rebuild pipeline | `sync.py` | Excel → `dashboard_data.json` → HTML patch (Sunday ritual) |
| Legacy full-rebuild script | `rebuild_all.py` | **Drifted — no longer safe to re-run** (see Known Issues) |
| Dashboard | `html/financas2026-Dashboard.html` (90KB) | 9-tab static HTML, Chart.js, no server |
| Data contract | `dashboard_data.json` | 15 top-level sections: kpis, banks, weekly, monthly, category_totals, subscriptions, cancel_tracker, international, card_transactions, nfce, inflation, mercado, mercado_transactions, mp_withdrawals |
| NFC-e inflation engine | `nfce/` (332MB, 928 XML files, 496 unique receipts post-dedup) | Validated personal inflation methodology — deterministic, documented ground-truth checks |
| Mercado Pago evidence | `mercado_pago/` (extratos + faturas) | CSV/PDF statements |
| Banco Inter evidence | `banco_inter/screenshots/` | Image-based statements |
| BCB Registrato | `bcb_registrato/` | CCS account relationships + Pix keys (2 PDFs) |
| Mercado Livre / iFood | `mercado_livre_ifood/` | Order PDFs + screenshots |
| Operational scripts | `financas-open.sh`, `financas-login.sh`, `financas-close.sh`, `financas.lua` | Workspace open/close automation, Hammerspoon binding |
| Native prototype | `FinanceVision/` (12 Swift files, ~1,019 lines) | Standalone Vision OCR + LLM parser CLI |
| Planning docs | `LEIA-ME.md`, `PHASES.md`, `NATIVE_APP_ARCHITECTURE.md` | Status record + shelved roadmap |

## Data Ingested (by source)

- Mercado Pago: extratos (CSV) + faturas (PDF), `mp_all_data.json`
- Banco Inter: screenshot-based transactions
- BCB Registrato: CCS account relationships + Pix keys, confirmed 2026-06-29
- Mercado Livre / iFood: 13 orders (9 with value), itemized
- NFC-e: 928 XML notes → 496 valid unique receipts (4 cancelled excluded)
- Current dashboard snapshot (`dashboard_data.json`, generated 2026-07-07T05:06): 8 KPIs, 4 banks, 22 weekly records, 6 monthly records, 20 category totals, 15 subscriptions, 72 card transactions, 146 mercado transactions

## Native App Track — Correction

Two separate native-Swift efforts exist in this repo and should not be conflated:

1. **`FinanceVision/` CLI prototype** — a real, working Swift package (Package.swift + 12 source files, Vision OCR → LLM router → JSON transaction output). Built 2026-07-01, **before** the roadmap docs. It is small in scope (single-purpose statement parser), untracked in git, and there's no evidence in the repo of it being run against real production statements or validated. This matches the "Fase 2" concept described in `LEIA-ME.md`.
2. **Full native app roadmap** (`PHASES.md` + `NATIVE_APP_ARCHITECTURE.md`) — the 6-phase SQLite/6-importer/SwiftUI rewrite, shelved 2026-07-07 (see `FINANCEVISION_CLOSE_REPORT.md`).

Correction: `FINANCEVISION_CLOSE_REPORT.md` states "No native build work has started." That's accurate for item 2 (the roadmap) but not for item 1 — the CLI prototype already exists as working code. This report is the record of that correction; the earlier close report has not been edited to preserve its own audit trail. Say the word if you want it amended too.

## Known Issues / Risks (verified from git history and file state)

- `rebuild_all.py` has drifted and is explicitly flagged (in the one existing commit message) as unsafe to re-run — the workbook is now hand-patched via one-off scripts (`fix_dataentry_top3.py`, `fix_dataentry_round2.py`, `patch_dashboard.py`) rather than regenerated.
- Git history is minimal: 1 commit total, no remote, and everything except the just-committed xlsx fix is untracked (`git status` shows the entire repo — including `sync.py`, `nfce/`, `dashboard_data.json` — as `??`). There is no version history for the pipeline or data prior to today.
- Two manual `.xlsx` backups exist in the repo root (`*.backup-20260707-*.xlsx`) from the same-day integrity fix — backup discipline is manual, not automated, and these are git-ignored by pattern.
- `FinanceVision/` Swift prototype is uncommitted and has no associated tests or run logs in the repo — treat as unverified until proven against a real statement.

## Decisions Already Locked In

- Full native app rewrite (`PHASES.md` roadmap) — **shelved 2026-07-07**. Revisit trigger: repeated, named bottleneck in the Excel/Python/HTML workflow, not app-curiosity. Full rationale in `FINANCEVISION_CLOSE_REPORT.md`.
- Phase 2 native criteria (`LEIA-ME.md`) were defined before this session and remain the actual gating conditions: 3 completed weekly manual cycles, an identified pain point (PDF/screenshot ingestion), available build time, and HTML genuinely failing to keep up. None confirmed met as of this report.

## Operational Cadence (unchanged)

Sunday ritual, per `LEIA-ME.md` and `financas-close.sh`:

1. Export MP statement (PDF/CSV)
2. Screenshot BB/Inter transactions if any
3. Upload into this workspace
4. Update CARD_TXS / INTER_TXS
5. Run `sync.py`
6. Save HTML

## Recommendations (not executed — for decision only)

1. Commit the current repo state as a real checkpoint. One commit covering only the xlsx fix means the rest of the pipeline has zero version history — a `rebuild_all.py`-style drift wouldn't be recoverable via git today.
2. Decide the fate of the `FinanceVision/` CLI prototype: either commit it with a note on its actual (unverified) status, or move it to `archive/` if it's not an active line of work. Leaving working code uncommitted and undocumented is the kind of ambiguity that causes confusion later.
3. No other action needed — Phase 1 stands as operational and complete per its own stop condition.

## Validation

- [x] File counts, directory sizes, and JSON/xlsx structure confirmed by direct inspection, not inferred
- [x] Status claims cross-checked against `LEIA-ME.md`'s own Phase 2 criteria
- [x] Native-build status discrepancy identified against the prior close report and corrected here
- [x] No production files modified as part of producing this report

## Risk

None. This is a read-only documentation artifact.

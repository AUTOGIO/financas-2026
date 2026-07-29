# Technical Report — Personal Finance Workspace

> Local-first, single-operator personal finance workspace. Replaces the
> pre-reorganization report of the same name (now at
> `archive/technical-report-2026-07.md`). This version reflects the current
> repo layout and has no PII.

---

## 1. System Overview

A **local-first, offline-capable** personal finance system built from a
handful of standard tools — Python 3, Microsoft Excel, and static HTML/JS
dashboards. No database, no cloud, no build step. All state lives in the
repo (workbooks + JSON artifacts) or on the operator's disk (NFC-e XMLs,
kept out of git; see AUDIT-002).

### Data flow

```
data/financas2026-DataEntry.xlsx  ─►  scripts/analytics_engine.py
                                      ─►  data/insights.json
                                      ─►  src/html/financas2026-Dashboard.html

src/nfce/notas/NFCE_XML_*/*.xml   ─►  src/nfce/personal_inflation.py
                                      ─►  personal_inflation_data.json (+ validation)
                                      ─►  src/nfce/personal_inflation_index.html

src/nfce/notas_litoral/**         ─►  src/nfce/litoral_store_prices.py
                                      ─►  litoral_price_data.json (+ validation)
                                      ─►  src/nfce/litoral_store_prices.html
```

`sync.py` at the repo root is the glue: it runs `analytics_engine.py` so
`data/insights.json` is always fresh before dashboards open.

## 2. Repository Layout

Governed by `AGENTS.md`. Top-level:

| Path | Purpose |
|------|---------|
| `README.md` | Prerequisites, run instructions, developer tasks |
| `AGENTS.md` | Layout rules and hygiene policy |
| `Makefile` | Developer tasks (`install`, `sync`, `test`, `clean`, `lint-paths`) |
| `requirements.txt` | Runtime dependencies (`openpyxl`) |
| `sync.py` | Orchestrator — runs the analytics engine |
| `src/` | Application code (HTML dashboards, NFC-e pipelines) |
| `scripts/` | Runnable helpers (`.sh` launchers, `analytics_engine.py`, `sysmonitor.py`) |
| `data/` | Workbooks, `raw/` bank exports, `insights.json` |
| `docs/` | This report + `docs/prompts/` (AI prompt scaffolds) |
| `config/` | Non-secret project metadata |
| `tests/` | Unit tests (15 tests, ~5 ms wall clock) |
| `archive/` | Obsolete files kept for reference |
| `logs/` | Local runtime logs (gitignored) |

## 3. Runtime Prerequisites

- Python 3.10+
- `openpyxl` (from `requirements.txt`)
- macOS-only for the launcher scripts: Microsoft Excel, Hammerspoon,
  ChatGPT Atlas. The Python pipelines and static HTML dashboards work
  without them.

Install:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# or:  make install
```

## 4. Primary Files

### 4.1 `data/financas2026-DataEntry.xlsx`

Master workbook. Sheets consumed by `scripts/analytics_engine.py`:

- `💳 Transactions` — AI/subscription card charges (72 rows).
- `📅 Weekly` — Weekly card spend across all categories.

Additional sheets (Banks, MP Faturas, International, Subscriptions, Cancel
Tracker, etc.) are read by the operator directly in Excel; the analytics
engine narrates its own scope limits in its module docstring.

### 4.2 `scripts/analytics_engine.py`

Z-score anomaly detection (window = 3 months, threshold = 1.5σ) on the
AI/subscription subset, plus a linear-trend expense projection off weekly
card spend. Writes `data/insights.json`. Refuses to run if a workbook copy
appears at the repo root (AUDIT-003 guard).

Run:

```bash
python3 sync.py         # normal way
python3 scripts/analytics_engine.py  # direct
```

### 4.3 `src/html/financas2026-Dashboard.html`

12-tab dashboard, reads `data/insights.json` on open. Chart.js is loaded
from a CDN — the rest is vanilla JS/SVG. Open with a double-click or via
`scripts/financas-open.sh`.

### 4.4 `src/nfce/personal_inflation.py`

Builds the personal inflation index from Brazilian NFC-e XMLs. Product
identity is EAN when valid, else `CNPJ-root + normalized description`;
prices are median unit prices per month; log-return spread + spend-weighted
aggregation (Tornqvist).

Baseline metrics live in `personal_inflation_baseline.json`. After
intentional data additions, refresh with `--accept-new-baseline`
(AUDIT-016).

Run:

```bash
cd "$(git rev-parse --show-toplevel)/src/nfce"
python3 personal_inflation.py --verify-ground-truth
```

### 4.5 `src/nfce/litoral_store_prices.py`

Parallel pipeline for Supermercado Litoral (CNPJ `08189400000107`,
Cabedelo/PB) — one-day-per-year store price snapshots. Requires the
`notas_litoral` symlink (see `README.md` and `src/nfce/README.md`).

### 4.6 NFC-e XML directories

Personal NFC-e receipts are **not** tracked in git (see AUDIT-002 —
they contain address, phone, and CPF in the `<infCpl>` element). Point
either pipeline at any directory with `--notes-dir`. The default is
`src/nfce/notas/NFCE_XML_*/` which the operator populates locally.

## 5. Tests

15 tests covering both pipelines. Fixtures are synthetic XML/TXT payloads
generated inside `tempfile.TemporaryDirectory` — the tests do not depend
on the operator's real receipts.

```bash
python3 -m unittest tests.test_personal_inflation tests.test_litoral_store_prices
# or:  make test
```

## 6. macOS Launcher Ritual (optional)

The launchers assume Hammerspoon + ChatGPT Atlas + Microsoft Excel. They
prefer a project-local `.venv/bin/python3`, falling back to the caller's
`PYTHON` env-var or `command -v python3` (AUDIT-011).

```bash
bash scripts/financas-open.sh   # sync + open Excel + 3 Atlas windows + Hammerspoon layout
bash scripts/financas-close.sh  # sync + save Excel + close relevant Atlas windows
```

## 7. Non-Goals / Deferred

- **Cash-flow / balance projection.** `analytics_engine.py` produces an
  expense projection only. No income data lives in this repo, so a
  cash-flow view would require a new source.
- **Full-ledger anomaly detection.** Anomaly scan is scoped to the
  AI/subscription subset; extending to the full ledger requires a proper
  month × category matrix.
- **Native app.** A previously planned Swift/FinanceVision app is
  archived (see `archive/scripts/fv.sh` and `archive/FINANCEVISION_CLOSE_REPORT.md`).
- **Orphan workbooks.** Earlier `financeai-tracker`, `wealthcommand`, and
  `subscription-budget-2026` spreadsheets are under `archive/data/` — none are
  consumed by the live analytics path.

## 8. Governance

- `AGENTS.md` is the source of truth for folder layout and hygiene rules.
- `REPOSITORY_AUDIT.md` is the last full audit (2026-07-29); remediation
  status for each finding lives inside that file.
- Make targets provide the safety net: `make test`, `make lint-paths`,
  `make clean` before commits.

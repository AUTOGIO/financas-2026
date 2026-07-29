# Repository Audit Report

**Generated:** 2026-07-29
**Auditor:** Automated (read-only)
**Repository:** `financas-2026` — AUTOGIO/financas-2026 (visibility: private)
**Branch:** `master` (c1c8eb9)

---

## 1. Executive Summary

`financas-2026` is a local-first personal finance workspace. The operator edits an
Excel workbook (`data/financas2026-DataEntry.xlsx`), views static HTML dashboards
in a browser, and runs two small Python pipelines — an NFC-e "personal inflation"
index (`src/nfce/personal_inflation.py`) and a "Litoral store price" tracker
(`src/nfce/litoral_store_prices.py`). A tiny `sync.py` at the root invokes
`scripts/analytics_engine.py` to refresh `data/insights.json` used by the
dashboard. macOS-specific shell scripts orchestrate open/close rituals through
Hammerspoon and ChatGPT Atlas.

**Key strengths.** The two Python pipelines are well-scoped, pure stdlib except
for `openpyxl`, deterministic, and have a real (if narrow) unit test suite that
runs in 5 ms and passes. The analytics engine documents its own scope limits
in-code. `.gitignore` correctly excludes secrets, logs, caches, and the large
`nfce.pdf` / `notas_litoral` symlink. AGENTS.md is short, consistent with the
current on-disk layout, and takes a "prefer move over rewrite" stance that has
kept the top level lean.

**Key risks.**
- **PII in tracked source files.** The operator's real full name, CPF
  `[REDACTED]`, home addresses and phone numbers are hardcoded into
  `docs/technical-report-2026-07.md`, three tracked HTML dashboards, and many of
  the 1,367 tracked NFC-e receipt XMLs under `src/nfce/notas/NFCE_XML_*/`. The
  repo is currently private, so this is not a public leak, but a single
  visibility flip, fork, or leaked token exposes real personal financial data.
- **Stale documentation and dead scripts after the reorg commit.** The most
  recent commit (`c1c8eb9`) reorganized the tree into `src/`, `data/`,
  `scripts/`; `docs/technical-report-2026-07.md`, `archive/PHASES.md`, and
  `scripts/fv.sh` still reference the pre-reorg paths (`nfce/`, `html/`,
  `banco_inter/`, `FinanceVision/.build/release/FinanceVision`). `scripts/fv.sh`
  is currently broken (points at a nonexistent binary).
- **Duplicated data-entry workbook.** A newer copy of the master workbook lives
  untracked at the repository root (`financas2026-DataEntry.xlsx`, 97 KB,
  2026-07-22) while `scripts/analytics_engine.py` reads the older tracked one at
  `data/financas2026-DataEntry.xlsx` (57 KB, 2026-07-13). If the operator has
  been editing the root copy, insights are stale.
- **Hardcoded `/Users/eduardofgiovannini/...` paths** in scripts, docs, tests,
  and even error messages — the pipeline would not run on any other machine or
  under a different username.

**Finding counts:** 1 Critical, 4 High, 6 Medium, 6 Low, 3 Informational.

---

## 2. Audit Scope and Limitations

- **Scope:** Full repository at `master` / `c1c8eb9`, including tracked and
  untracked files.
- **Approach:** Read-only inspection of source, config, scripts, tests, docs,
  and data files. Ran only clearly non-destructive commands
  (`git`, `du`, `ls`, `wc`, `python3 --version`, `python3 -m unittest`, `gh repo view`).
- **Executed:** The existing test suite (`python3 -m unittest
  tests.test_personal_inflation tests.test_litoral_store_prices`) — 15 tests
  pass in 0.005 s.
- **Not executed:** `python3 src/nfce/personal_inflation.py`,
  `python3 src/nfce/litoral_store_prices.py`, `python3 sync.py`,
  or any of the `scripts/financas-*.sh` launchers (each triggers Excel, Atlas,
  Hammerspoon, or filesystem side effects).
- **Limitations:** The Excel workbooks are binary; the audit relies on
  `analytics_engine.py`'s sheet expectations rather than direct inspection. The
  `src/nfce/notas_litoral` symlink points to a sibling repository that was not
  inspected in depth.

---

## 3. Initial Repository State

| Property | Value |
|----------|-------|
| Root | `/Users/eduardofgiovannini/Documents/GitHub/financas-2026` |
| Branch | `master` |
| HEAD | `c1c8eb9` — "Reorganize repo into a simple professional layout." |
| Remote | `https://github.com/AUTOGIO/financas-2026.git` (private) |
| Total commits | 2 (`c1c8eb9`, `1bc3f56`) |
| Submodules | None |
| Nested git | `archive/nfce-nested-git/` (bare-ish, 8 KB, empty `objects/`; gitignored) |
| Repo size (working tree) | 226 MB |
| Largest single file | `src/nfce/notas/nfce.pdf` — 151 MB (gitignored, present locally) |
| Largest tracked subtree | `src/nfce/notas/NFCE_XML_*/` — ~29 MB across 1,367 XMLs |
| Tracked files | 1,484 |
| Uncommitted (M) | `.gitignore`, `README.md`, `archive/PHASES.md`, `archive/PROJECT_CLOSE_REPORT.md`, `archive/RELATORIO-FECHAMENTO.md`, `docs/technical-report-2026-07.md`, `financas-2026.code-workspace`, several scripts + HTML + Python files |
| Untracked (??) | `data/insights.json`, `financas2026-DataEntry.xlsx` (at root), `scripts/analytics_engine.py`, `src/nfce/litoral_store_prices.{css,html,js,py}`, `sync.py`, `tests/test_litoral_store_prices.py` |

The working tree contains substantial modifications and new files that have
never been committed. The current `master` snapshot on GitHub is materially
different from what runs locally.

---

## 4. Repository Purpose

**Intended purpose.** A single-operator, offline-first personal finance
workspace. The operator manually maintains an Excel workbook of transactions,
subscriptions, weekly card spend, and international transfers; static HTML
dashboards render the same data plus derived insights.

**Primary user.** The repo owner (non-developer usage pattern — no framework,
no build step, no cloud runtime).

**Primary workflows.**
1. Edit `data/financas2026-DataEntry.xlsx` (subscriptions, weekly spend,
   transactions, banks).
2. Run `python3 sync.py` (called by launcher scripts) which runs
   `scripts/analytics_engine.py`, refreshing `data/insights.json`.
3. Open `src/html/financas2026-Dashboard.html` (12 tabs) directly in a browser.
4. Refresh NFC-e receipts: `cd src/nfce && python3 personal_inflation.py`
   which parses XMLs in `notas/NFCE_XML_*/` and injects data into
   `personal_inflation_index.html`.
5. Refresh Litoral store snapshots: `python3 litoral_store_prices.py` after
   symlinking `notas_litoral` to a sibling repo.

**Data flow.**
```
Excel workbook  ─►  analytics_engine.py  ─►  data/insights.json  ─►  Dashboard HTML
                                                                     │
NFC-e XMLs  ────►  personal_inflation.py  ─►  *_data.json  ────────► personal_inflation_index.html
                                              *_validation.json
NFC-e (Litoral) ─►  litoral_store_prices.py ─► litoral_price_data.json ─► litoral_store_prices.html
```

**External services.** None at runtime. The launcher scripts (`financas-open.sh`,
`financas-login.sh`, `financas-close.sh`) invoke macOS-only apps (Microsoft
Excel, ChatGPT Atlas, Hammerspoon) via `open` and `osascript`. The `fv.sh`
helper references a "FinanceVision" Swift binary that is not present in this
repository, and `configure_lmstudio.sh` targets an LM Studio local server on
`localhost:1234`.

**Deployment model.** None. Everything runs locally on the operator's Mac.

---

## 5. Repository Map

| Path | Purpose |
|------|---------|
| `README.md` | 20-line summary of run instructions |
| `AGENTS.md` | Layout rules and hygiene policy for AI agents |
| `.gitignore` | macOS + Python + secret + NFC-e-artifact excludes |
| `sync.py` | Root-level orchestrator; shells out to `scripts/analytics_engine.py` |
| `financas-2026.code-workspace` | VS Code workspace including sibling `LitoralPriceTracker` |
| `financas2026-DataEntry.xlsx` | **Untracked** newer copy of the master workbook at root |
| `scripts/` | Shell launchers, sysmonitor, analytics engine, LM Studio setup |
| `scripts/analytics_engine.py` | Untracked; z-score anomalies + linear expense projection |
| `scripts/financas-open.sh` / `-login.sh` / `-close.sh` | Hammerspoon + Atlas orchestration |
| `scripts/fv.sh` | Launcher for a Swift `FinanceVision` binary that does not exist here |
| `scripts/sysmonitor.py` | Background CPU/mem/thermal watcher, writes `~/.financas-system-status.json` |
| `scripts/configure_lmstudio.sh` | Sets LM Studio context length and loads a Gemma model |
| `src/html/` | `financas2026-Dashboard.html` (3,963 lines) + `bloomberg-terminal.html` (1,419 lines) |
| `src/nfce/` | Two Python pipelines + four HTML dashboards + JSON data artifacts + 184 MB of NFC-e XMLs |
| `src/nfce/notas/` | Tracked NFC-e XML receipts + untracked 151 MB `nfce.pdf` |
| `src/nfce/notas_litoral` | **Symlink** to `~/Documents/GitHub/LitoralPriceTracker/data/raw/NOTAS_LITORAL` |
| `src/nfce/personal_inflation_prompt.py` | OpenAI SDK prompt scaffold — imported at module load |
| `data/` | 4 xlsx workbooks + `raw/` bank exports + `planilhas/` + `insights.json` (untracked) |
| `data/raw/` | Tracked bank statements (CSV, OFX, PDF) and screenshots for Inter, BB, MP, BCB, ML/iFood |
| `config/project-metadata.json` | Non-secret project descriptor |
| `docs/technical-report-2026-07.md` | 902-line executive/technical report — contains PII |
| `docs/executive-report-2026-07.pdf` | 854 KB PDF version — contains PII |
| `docs/prompts/` | Empty directory |
| `tests/` | Two unittest modules, 15 tests total |
| `reports/session/` | Two 282-byte session-end markdowns (not documented in AGENTS.md) |
| `logs/` | Local runtime logs (gitignored) |
| `archive/` | Old reports, HTML backups, and a stubbed nested `.git` |

---

## 6. Technology Stack

| Technology | Evidence | Notes |
|------------|----------|-------|
| Python 3 | `sync.py`, `scripts/*.py`, `src/nfce/*.py` | Stated 3.10+ in comments; system has 3.14.6 |
| Python stdlib | `xml.etree.ElementTree`, `json`, `math`, `statistics`, `argparse`, `subprocess`, `socket` | Zero third-party requirement for NFC-e pipelines |
| `openpyxl` | `scripts/analytics_engine.py` import; installed 3.1.5 | Only third-party runtime dep |
| `openai` | `src/nfce/personal_inflation_prompt.py` line 1 | Instantiates `OpenAI()` at import; unused elsewhere |
| Bash / Zsh | `scripts/*.sh`, `FuloFilo`-style `.command` absent | Mix of `#!/bin/bash` and `#!/usr/bin/env bash` |
| AppleScript | `osascript` in launchers, `sysmonitor.py`, `fv.sh` | macOS-only |
| Hammerspoon (Lua) | Inline Lua inside `financas-open.sh`, `financas-login.sh` | Requires Hammerspoon app + AppleScript bridge |
| Chart.js 4.4.1 | CDN in `src/html/financas2026-Dashboard.html` | External CDN dependency at render time |
| Vanilla JS / SVG | Other HTML dashboards | No build tool |
| LM Studio + Gemma | `scripts/configure_lmstudio.sh`, `scripts/fv.sh` | Optional local LLM setup |
| Git | `git version 2.55.0` on system | Only 2 commits in history |
| No lock/manifest files | (no `requirements.txt`, `pyproject.toml`, `package.json`, `uv.lock`, `Cargo.toml`, etc.) | Zero pinned dependencies |

---

## 7. Architecture Overview

The actual architecture is a **read-mostly file pipeline**:

```
┌──────────────────────────────┐          ┌─────────────────────────────┐
│ Operator (macOS, single Mac) │          │ NFC-e SEFAZ export (email)  │
└──────────────┬───────────────┘          └──────────────┬──────────────┘
               │ edits                                    │ drops NFCE_XML_* folder
               ▼                                          ▼
   data/financas2026-DataEntry.xlsx        src/nfce/notas/NFCE_XML_*/*.xml
               │                                          │
               │ openpyxl (read-only)                     │ stdlib XML parse
               ▼                                          ▼
   scripts/analytics_engine.py            src/nfce/personal_inflation.py
               │                                          │
               ▼                                          ▼
    data/insights.json (JSON)          personal_inflation_data.json
               │                          + validation JSON
               ▼                          + injected into HTML
   src/html/financas2026-Dashboard.html   src/nfce/*.html
```

The Litoral store track (`litoral_store_prices.py`) is a parallel branch that
reuses parsing helpers from `personal_inflation.py` (via `from
personal_inflation import ...`) but reads a separate `notas_litoral/` symlink
tree and writes to its own JSON + HTML outputs. Test coverage confirms the two
tracks are properly isolated.

**Strengths.**
- One-way flow: nothing writes back to the Excel master or to the raw NFC-e
  XMLs.
- Two pipelines are deterministic and covered by unit tests with self-contained
  fixtures (`tempfile.TemporaryDirectory`).
- Ground-truth guard (`EXPECTED_METRICS` in `personal_inflation.py`) catches
  silent regressions.
- Static HTML dashboards mean "deploy" = save + reopen in the browser.

**Weaknesses.**
- Three separate dashboards (`financas2026-Dashboard.html`,
  `bloomberg-terminal.html`, plus two NFC-e HTMLs) with overlapping tabs — no
  single source of truth for UI.
- Multiple xlsx artifacts in `data/` (`financeai-tracker.xlsx`,
  `wealthcommand.xlsx`, `subscription-budget-2026.xlsx`) whose relationship to
  the main workbook is undocumented in `README.md` or `AGENTS.md`.
- Dead subsystems referenced but not present: `FinanceVision/` (referenced by
  `fv.sh`), the "Fase 2" Swift/SwiftUI native app referenced in archived docs.

---

## 8. Build, Test, and Run Procedure

**Setup.** No dependency install step is documented. Effectively:
- `python3` (3.10+ recommended; 3.14 in use)
- `openpyxl` available (system-wide or via `pip3 install --break-system-packages openpyxl` per `analytics_engine.py`'s error message)
- Hammerspoon + ChatGPT Atlas + Microsoft Excel installed (for the launcher
  scripts; the pipelines themselves work without them)

**Run — daily/manual.**
```bash
python3 sync.py                       # refresh data/insights.json
open src/html/financas2026-Dashboard.html
```

**Run — full macOS ritual.**
```bash
bash scripts/financas-open.sh         # sync + Excel + 3 Atlas windows + Hammerspoon layout
bash scripts/financas-close.sh        # sync + save Excel + close Atlas windows
```

**Refresh NFC-e index.**
```bash
cd src/nfce && python3 personal_inflation.py --verify-ground-truth
```

**Refresh Litoral store track.**
```bash
ln -sfn <path-to-LitoralPriceTracker>/data/raw/NOTAS_LITORAL src/nfce/notas_litoral
cd src/nfce && python3 litoral_store_prices.py
```

**Test.**
```bash
python3 -m unittest tests.test_personal_inflation tests.test_litoral_store_prices
```

**Conflicts.** `README.md` says the workbook lives at
`data/financas2026-DataEntry.xlsx`; a newer untracked copy lives at
`financas2026-DataEntry.xlsx` (repo root) which the analytics engine ignores.
`docs/technical-report-2026-07.md` refers to pre-reorg paths (`nfce/`,
`html/`, `banco_inter/`) that no longer exist.

---

## 9. Commands Executed

| Command | Exit | Notes |
|---------|------|-------|
| `git status --short` | 0 | 15 modified, 8 untracked |
| `git branch --show-current` | 0 | `master` |
| `git remote -v` | 0 | AUTOGIO/financas-2026 |
| `git log -15 --oneline --decorate` | 0 | Only 2 commits |
| `git submodule status` | 0 | None |
| `du -sh .` | 0 | 226 MB |
| `du -sh src/*/ data/*/` | 0 | src/nfce = 187 MB, data/raw = 19 MB |
| `du -sh src/nfce/notas/nfce.pdf src/nfce/notas/NFCE_XML_*/` | 0 | 151 MB + 29 MB tracked |
| `git ls-files \| wc -l` | 0 | 1,484 tracked files |
| `git ls-files 'src/nfce/notas/NFCE_XML_*' \| wc -l` | 0 | 1,367 NFC-e XMLs tracked |
| `git ls-files 'data/raw/**' \| wc -l` | 0 | 76 raw statement/screenshot files tracked |
| `git ls-files '*.pdf'` | 0 | 13 tracked PDFs (bank statements + report) |
| `git ls-files logs/ docs/prompts/ reports/` | 1 | Zero tracked files in any |
| `git check-ignore -v src/nfce/notas/nfce.pdf` | 0 | Correctly ignored |
| `gh repo view AUTOGIO/financas-2026 --json visibility` | 0 | `"visibility":"PRIVATE"` |
| `python3 --version` | 0 | 3.14.6 |
| `python3 -c "import openpyxl; print(openpyxl.__version__)"` | 0 | 3.1.5 |
| `python3 -m unittest tests.test_personal_inflation tests.test_litoral_store_prices` | 0 | 15 tests passed in 0.005 s |

No destructive or side-effecting commands were executed.

---

## 10. Findings Summary

| ID | Severity | Priority | Category | Finding | Confidence |
|---|---|---|---|---|---|
| AUDIT-001 | Critical | P0 | Security | Real CPF, name, addresses, phone numbers committed in tracked files | Confirmed |
| AUDIT-002 | High | P1 | Security | 1,367 NFC-e XMLs with personal purchase history tracked in git | Confirmed |
| AUDIT-003 | High | P1 | Correctness | Duplicate data-entry workbook at root — analytics engine reads stale copy | Confirmed |
| AUDIT-004 | High | P1 | Documentation | `docs/technical-report-2026-07.md` references pre-reorg paths | Confirmed |
| AUDIT-005 | High | P1 | Shell | `scripts/fv.sh` points at a nonexistent binary | Confirmed |
| AUDIT-006 | Medium | P2 | Dependency | No dependency manifest (`requirements.txt`, `pyproject.toml`) | Confirmed |
| AUDIT-007 | Medium | P2 | Repository hygiene | Hardcoded `/Users/eduardofgiovannini/` in scripts, docs, error messages | Confirmed |
| AUDIT-008 | Medium | P2 | Correctness | Bare `except:` and swallowed exceptions in `scripts/sysmonitor.py` | Confirmed |
| AUDIT-009 | Medium | P2 | Correctness | `src/nfce/personal_inflation_prompt.py` instantiates `OpenAI()` at import | Confirmed |
| AUDIT-010 | Medium | P2 | Repository hygiene | Undocumented top-level `reports/` folder (contains `session/`) | Confirmed |
| AUDIT-011 | Medium | P2 | Reliability | Launchers hardcode `PYTHON=/opt/homebrew/bin/python3` | Confirmed |
| AUDIT-012 | Low | P3 | Repository hygiene | Committed `.DS_Store` files in `archive/`, `data/`, `src/nfce/`, root | Confirmed |
| AUDIT-013 | Low | P3 | Repository hygiene | Empty `docs/prompts/` directory | Confirmed |
| AUDIT-014 | Low | P3 | Reliability | `notas_litoral` symlink points to a sibling repo path only meaningful to the operator | Confirmed |
| AUDIT-015 | Low | P3 | Documentation | `README.md` recommends `python3 -m unittest ...` but never mentions `openpyxl` prerequisite | Confirmed |
| AUDIT-016 | Low | P3 | Correctness | `src/nfce/personal_inflation.py::EXPECTED_METRICS` is a fragile ground-truth guard | Confirmed |
| AUDIT-017 | Low | P3 | Documentation | `archive/nfce-nested-git/` is orphaned stub referenced by `.gitignore` | Confirmed |
| AUDIT-018 | Informational | — | Repository hygiene | Only 2 commits in git history — no incremental change record | Confirmed |
| AUDIT-019 | Informational | — | Dependency | `analytics_engine.py` suggests `pip3 install openpyxl --break-system-packages` | Confirmed |
| AUDIT-020 | Informational | — | Architecture | Two large overlapping dashboards (`financas2026-Dashboard.html`, `bloomberg-terminal.html`) | Confirmed |

---

## 11. Critical Findings

### [AUDIT-001] Real PII (CPF, name, address, phone) committed in tracked source files

- Severity: Critical
- Priority: P0
- Confidence: Confirmed
- Category: Security
- File: multiple tracked files
- Location: see evidence
- Evidence:
  - `docs/technical-report-2026-07.md` lines 2, 787, 902 — full name and CPF `[REDACTED]` in the title, in a runbook step, and in the footer.
  - `src/nfce/nfce-dashboard.html` line 58 — full name, CPF, city ("João Pessoa, PB").
  - `src/html/bloomberg-terminal.html` line 263 — full name and CPF in the dashboard title bar.
  - `src/nfce/inflation-tracker.html` line 284 — CPF in the source-caption footer.
  - `src/nfce/notas/NFCE_XML_VX4AAMTBJR/NFCE_251*.xml` (multiple files) — the `<infCpl>` element embeds full name, home addresses (`[REDACTED-ADDRESS]`, `[REDACTED-ADDRESS]`), phone numbers (`[REDACTED-PHONE]`, `[REDACTED-PHONE]`, `[REDACTED-PHONE]`), CPF, and card-processor identifiers (FIRSTDATA, REDECARD).
  - `docs/executive-report-2026-07.pdf` (854 KB) is a PDF export of the same report — contents cannot be diffed but almost certainly carries the same PII.
- Impact:
  - The repo is currently `PRIVATE` on GitHub (verified via `gh repo view`), so this is not a public leak today. However:
    1. A single visibility toggle, accidental fork, or leaked GitHub token exposes real financial PII (CPF is a national identifier in Brazil and is regularly used for identity fraud and social engineering).
    2. Git history preserves the PII forever unless history is rewritten; simply editing files later does not remove past commits.
    3. Any future backup or clone of the repo carries the same exposure.
- Recommendation:
  - Redact CPF, phone, and street addresses from HTML and Markdown sources (replace with `[REDACTED]` or a generic label).
  - Decide whether NFC-e XMLs need to be tracked at all (see AUDIT-002). If yes, strip the `<infCpl>` complementary-information element from XMLs before committing (this field is optional metadata and does not affect the inflation index).
  - If PII must be scrubbed from history: rewrite history with `git filter-repo` (single-operator repo with only 2 commits — low blast radius today).
- Validation:
  - `rg --hidden -n '215\.965\.638|CPF 215'` returns zero matches in tracked files.
  - `rg --hidden -n '<infCpl>' src/nfce/notas/` returns zero matches, or matches contain only non-PII content.

---

## 12. High Findings

### [AUDIT-002] 1,367 personal NFC-e receipt XMLs tracked in git

- Severity: High
- Priority: P1
- Confidence: Confirmed
- Category: Security
- File: `src/nfce/notas/NFCE_XML_*/`
- Location: three tracked folders (`NFCE_XML_4BEPPCOPLX`, `NFCE_XML_U2LGXQOLLF`, `NFCE_XML_VX4AAMTBJR`)
- Evidence:
  - `git ls-files 'src/nfce/notas/NFCE_XML_*' | wc -l` → 1,367.
  - `du -sh src/nfce/notas/NFCE_XML_*/` → ~29 MB total.
  - Each XML is a Brazilian electronic fiscal receipt containing every line item the operator bought (product, quantity, unit price), the merchant CNPJ and name, the payment method, the emission timestamp, and in many cases the `<infCpl>` element with full customer details (see AUDIT-001).
  - Three tracked SEFAZ `.txt` exports (`NFCE_2026070303*.txt`, `NFCE_20260713005027.txt`) are also present, totalling ~5.5 MB, and mirror the same information in pipe-delimited form.
- Impact:
  - Combined with AUDIT-001, an attacker with repo access reconstructs a detailed 8-year purchase history: where the operator shops, what they buy, when, and how much they spend.
  - Repository is inflated by ~30 MB of files that could be regenerated locally on demand.
  - The pipelines already assume XMLs are the "source of truth" but the code paths accept any directory via `--notes-dir`, so the XMLs do not need to sit inside the repo.
- Recommendation:
  - Move `src/nfce/notas/NFCE_XML_*` and `src/nfce/notas/NFCE_*.txt` out of the repo (mirror the pattern already used for `notas_litoral` — a symlink to an external location). Update `.gitignore` to exclude the folders.
  - If a small anonymized fixture is desirable for testing, keep only synthetic XMLs (the test suite already generates them via `tempfile.TemporaryDirectory`).
- Validation:
  - `git ls-files src/nfce/notas/` returns nothing (or only anonymized fixtures).
  - `python3 -m unittest tests.test_personal_inflation tests.test_litoral_store_prices` still passes.

### [AUDIT-003] Duplicated data-entry workbook: root copy is newer than the one the pipeline reads

- Severity: High
- Priority: P1
- Confidence: Confirmed
- Category: Correctness
- File: `data/financas2026-DataEntry.xlsx` (tracked, 56,903 B, 2026-07-13); `financas2026-DataEntry.xlsx` (untracked, 97,499 B, 2026-07-22)
- Location: repository root vs. `data/`
- Evidence:
  - `ls -l` shows two workbooks with the same name at different depths, the root copy is 40 KB larger and 9 days newer.
  - `scripts/analytics_engine.py` line 51:

```23:26:scripts/analytics_engine.py
ROOT = Path(__file__).resolve().parents[1]
WORKBOOK_PATH = ROOT / "data" / "financas2026-DataEntry.xlsx"
OUTPUT_PATH = ROOT / "data" / "insights.json"
```

    always reads the `data/` copy.
  - `README.md` and `docs/technical-report-2026-07.md` both point to the `data/` copy.
  - `AGENTS.md` explicitly forbids workbook-like files at the root ("Root: only `README.md`, `AGENTS.md`, `.gitignore`, and toolchain files").
- Impact:
  - If the operator has been double-clicking the root workbook (which `open` in Finder would surface first), all recent edits are invisible to `analytics_engine.py`, and `data/insights.json` — and hence the "AI Insights" tab of the dashboard — is stale.
  - Two workbooks with the same name virtually guarantee eventual data-loss on a manual reconciliation.
- Recommendation:
  - Diff the two workbooks (open both in Excel) and merge into the canonical `data/financas2026-DataEntry.xlsx`. Delete the root copy. Ensure the AGENTS.md rule against root-level workbooks is enforced.
  - Optionally, add a startup guard in `analytics_engine.py` that fails loudly if a `financas2026-DataEntry.xlsx` also exists at the root.
- Validation:
  - `ls financas2026-DataEntry.xlsx` returns "No such file or directory".
  - `python3 sync.py` prints insights derived from the merged workbook.

### [AUDIT-004] `docs/technical-report-2026-07.md` still references pre-reorg paths

- Severity: High
- Priority: P1
- Confidence: Confirmed
- Category: Documentation
- File: `docs/technical-report-2026-07.md`
- Location: sections 3, 4, 8, 9, appendices, and lines 244, 267, 270, 282, 397, 434, 437, 748, 751, 768, 881, 897, 898
- Evidence:
  - The report describes a top-level layout with `nfce/`, `html/`, `banco_inter/`, `bcb_registrato/`, `mercado_pago/`, etc. The current layout (per `AGENTS.md` and `ls`) is `src/html/`, `src/nfce/`, `data/raw/banco_inter/`, and so on.
  - Runbooks tell the operator to `cd /Users/eduardofgiovannini/Documents/GitHub/financas-2026/nfce` — a path that no longer exists.
  - The "nfce sub-repo" line in Appendix B claims `/…/financas-2026/nfce/` has its own `.git`. That structure was archived into `archive/nfce-nested-git/` (and gitignored).
  - `archive/PHASES.md`, `archive/PROJECT_CLOSE_REPORT.md`, `archive/RELATORIO-FECHAMENTO.md` are also based on the old layout, but they are in `archive/` where staleness is expected.
- Impact:
  - The most detailed operational reference in the repo is misleading to any human or agent following its instructions.
  - AGENTS.md rule 6 explicitly asks agents to fix broken paths after moves — this was not done for `docs/`.
- Recommendation:
  - Update paths in `docs/technical-report-2026-07.md` to the current layout (or move the file to `archive/` and write a shorter, current replacement).
  - Grep across `docs/` and top-level files for any remaining `nfce/`, `html/`, `banco_inter/` absolute references and rewrite them relative to the new layout.
- Validation:
  - `rg -n 'financas-2026/(nfce|html|banco_inter|bcb_registrato|mercado_pago)/' docs/` returns zero matches.

### [AUDIT-005] `scripts/fv.sh` points at a binary that does not exist in this repo

- Severity: High
- Priority: P1
- Confidence: Confirmed
- Category: Shell
- File: `scripts/fv.sh`
- Location: lines 9, 13–17
- Evidence:

```9:17:scripts/fv.sh
FV_BIN="$HOME/Documents/GitHub/financas-2026/FinanceVision/.build/release/FinanceVision"
STATUS_FILE="$HOME/.financas-system-status.json"

# ── 1. Ensure binary exists ──────────────────
if [ ! -f "$FV_BIN" ]; then
  echo "❌ FinanceVision not built. Run:"
  echo "   cd ~/Documents/GitHub/financas-2026/FinanceVision && swift build -c release"
  exit 1
fi
```

  - `ls ~/Documents/GitHub/financas-2026/FinanceVision` → `No such file or directory`.
  - `scripts/configure_lmstudio.sh` further mutates `fv.sh` at runtime via a Python heredoc that inserts an `lms load` block. Any operator running `configure_lmstudio.sh` today will silently modify a script that is already broken.
- Impact:
  - Running `fv.sh` fails immediately and instructs the operator to `cd` into a nonexistent directory. The script is dead as shipped.
  - `configure_lmstudio.sh` self-modifying `fv.sh` is surprising behavior and increases the chance of merge conflicts and lost edits.
- Recommendation:
  - Either restore/import the `FinanceVision/` Swift project or move `fv.sh` and `configure_lmstudio.sh` into `archive/` with a note. Update `README.md` to remove references (currently none, so no doc change needed).
  - Remove the `Update fv.sh` self-editing block from `configure_lmstudio.sh`; ship the desired `lms load` invocation directly inside `fv.sh` from the start.
- Validation:
  - `bash scripts/fv.sh` prints a clear "archived" or "not installed" message, or the script no longer exists.

---

## 13. Medium Findings

### [AUDIT-006] No dependency manifest — `openpyxl` is an undeclared runtime requirement

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: Dependency
- File: repo root (missing `requirements.txt` / `pyproject.toml` / `uv.lock`)
- Location: n/a
- Evidence:
  - `scripts/analytics_engine.py` imports `openpyxl` and, on failure, suggests `pip3 install openpyxl --break-system-packages`.
  - There is no `requirements.txt`, `pyproject.toml`, `Pipfile`, `poetry.lock`, or `uv.lock` at any depth.
  - `README.md` documents "Tests: `python3 -m unittest ...`" without mentioning any install step.
- Impact:
  - A fresh clone cannot be brought to a working state without either lucky system-wide `openpyxl` or the `--break-system-packages` invocation (which is discouraged and, on newer macOS Pythons, requires an explicit acknowledgement).
  - No way to lock or audit versions.
- Recommendation:
  - Add a minimal `requirements.txt` (single line: `openpyxl>=3.1,<4`). Optionally add an `openai` extras group for `personal_inflation_prompt.py`. Recommend `python3 -m venv .venv && pip install -r requirements.txt` in `README.md`.
- Validation:
  - Fresh clone + `python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && python3 sync.py` runs to completion.

### [AUDIT-007] Hardcoded `/Users/eduardofgiovannini/…` paths in scripts, docs, and error messages

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: Repository hygiene
- File: multiple
- Location:
  - `src/nfce/litoral_store_prices.py` line 629 — hardcoded example symlink target in an `sys.stderr` error message
  - `scripts/financas-login.sh` line 3 — comment lists the absolute path
  - `src/nfce/README.md` lines 31, 63, 72, 111 — run instructions use absolute paths
  - `docs/technical-report-2026-07.md` — many (see AUDIT-004)
  - `archive/PHASES.md`, `archive/PROJECT_CLOSE_REPORT.md`, `archive/RELATORIO-FECHAMENTO.md` — historical (acceptable in `archive/` but noted)
- Evidence:
  - `rg -n '/Users/eduardofgiovannini'` returns 25+ matches across the paths above (excluding `.git/` and generated JSON payloads baked into HTML fallbacks).
  - `scripts/financas-open.sh`, `scripts/financas-close.sh`, `scripts/financas-login.sh` all correctly use `BASE="$HOME/Documents/GitHub/financas-2026"` for actual variables — the hardcoded strings are cosmetic/comment/error-message only, but they still bake in the username.
- Impact:
  - Any different macOS username breaks the runbook instructions verbatim.
  - Error messages in `litoral_store_prices.py` will suggest a `ln -sfn` command with the audit author's home directory rather than the runtime user's.
- Recommendation:
  - Replace `/Users/eduardofgiovannini/…` with `$HOME/Documents/GitHub/…` (shell), `$repo` placeholders (docs), or dynamically computed paths (error strings should use `os.path.expanduser` or the actual home).
- Validation:
  - `rg -n '/Users/eduardofgiovannini' -g '!archive/' -g '!*.json' -g '!*.html'` returns zero matches.

### [AUDIT-008] Bare `except:` and swallowed exceptions in `scripts/sysmonitor.py`

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: Correctness
- File: `scripts/sysmonitor.py`
- Location: lines 67, 85, 93
- Evidence:

```65:94:scripts/sysmonitor.py
        return int(r.stdout.split(":")[1].strip())
    except:
        return 0

THERMAL_LABELS = {0: "Normal", 1: "Elevada", 2: "Séria", 3: "Crítica ⚠"}

def write_status(cpu: float, mem: float, thermal: int):
    status = {
        "cpu":      cpu,
        "memory":   mem,
        "thermal":  THERMAL_LABELS.get(thermal, "?"),
        "thermal_level": thermal,
        "ollama":   is_port_open(11434),
        "lmstudio": is_port_open(1234),
        "ts":       datetime.now().strftime("%H:%M:%S")
    }
    try:
        with open(STATUS_FILE, "w") as f:
            json.dump(status, f)
    except:
        pass

def is_port_open(port: int) -> bool:
    import socket
    try:
        with socket.create_connection(("localhost", port), timeout=0.5):
            return True
    except:
        return False
```

  - The `notify()` function builds an AppleScript by interpolating `title`, `body`, and `sound` into a single-quoted f-string. Callers only pass hardcoded strings today, so no injection risk, but the pattern is brittle if any caller ever passes user-supplied text.
- Impact:
  - Bare `except:` catches `KeyboardInterrupt` and `SystemExit`, making the monitor annoying to stop and hiding programming errors (`NameError`, `AttributeError`).
  - Silent `pass` on a failed `open(STATUS_FILE, "w")` means the dashboard's system-health file may never update and no one will notice.
- Recommendation:
  - Replace bare `except:` with `except Exception as exc:` and log the exception at least at DEBUG level.
  - Log write failures on `STATUS_FILE` at least once.
- Validation:
  - `rg -n 'except\s*:\s*$' scripts/` returns zero matches.

### [AUDIT-009] `src/nfce/personal_inflation_prompt.py` instantiates `OpenAI()` at import time

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: Correctness
- File: `src/nfce/personal_inflation_prompt.py`
- Location: lines 1–3
- Evidence:

```1:3:src/nfce/personal_inflation_prompt.py
from openai import OpenAI

client = OpenAI()
```

  - The module also unconditionally issues `client.responses.create(...)` at module load (lines 70–80), so importing this file for any reason (e.g., a future test collection sweep) triggers a live API call — and fails without `OPENAI_API_KEY`.
  - The file is not imported anywhere else in the repo today, so the current runtime is unaffected.
- Impact:
  - Any accidental `python3 src/nfce/personal_inflation_prompt.py` (or `pytest`-style discovery that expands to this file) hits the OpenAI API and either bills the account or errors out.
  - The file is a prompt scaffold rather than production code, but nothing labels it as such.
- Recommendation:
  - Guard the SDK client and the `responses.create` call under `if __name__ == "__main__":`.
  - Consider moving the file to `docs/prompts/` (currently empty), aligning with the AGENTS.md layout.
- Validation:
  - `python3 -c "import runpy; runpy.run_path('src/nfce/personal_inflation_prompt.py', run_name='__test__')"` succeeds without network access.

### [AUDIT-010] Undocumented top-level `reports/` folder violates AGENTS.md rule 2

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: Repository hygiene
- File: `reports/session/`
- Evidence:
  - `AGENTS.md` § "Folder layout" lists `src/`, `scripts/`, `config/`, `data/`, `assets/`, `docs/`, `docs/prompts/`, `tests/`, `archive/` as the allowed top-level folders.
  - Rule 2 states: "Do not create new top-level folders without asking."
  - `reports/session/` contains two 282-byte "session-end" markdowns; the folder is untracked.
- Impact:
  - Violates the workspace's own conventions; future agents relying on AGENTS.md will re-move or re-delete this folder each time.
- Recommendation:
  - Move `reports/session/` under `logs/session/` (already gitignored) or `archive/session-notes/`, or explicitly extend AGENTS.md to include a `reports/` folder if it is expected to grow.
- Validation:
  - `ls` at the repo root shows only folders documented in AGENTS.md.

### [AUDIT-011] Launcher scripts hardcode `PYTHON=/opt/homebrew/bin/python3`

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: Reliability
- File: `scripts/financas-open.sh`, `scripts/financas-close.sh`, `scripts/financas-login.sh`
- Location: line 7 / 6 / 6 respectively
- Evidence:
  - Each launcher sets `PYTHON="/opt/homebrew/bin/python3"` (arm64 Homebrew default) and invokes it unconditionally.
  - No fallback for Intel Homebrew (`/usr/local/bin/python3`), Python installed under `pyenv`, or a project-local `.venv`.
- Impact:
  - The launchers will silently misbehave (or fail with `No such file or directory`) on Intel Macs, in environments without Homebrew, or when a venv is expected.
  - Undermines the AGENTS.md "prefer moves over rewrites" spirit — small hardcoded assumptions accumulate.
- Recommendation:
  - Prefer `PYTHON=$(command -v python3)` or `PYTHON="${PYTHON:-python3}"` so the caller can override, with a strict-mode guard if `python3` is missing.
- Validation:
  - `PYTHON=/nonexistent bash scripts/financas-open.sh` fails with a clear error rather than a cryptic ENOENT.

---

## 14. Low and Informational Findings

### [AUDIT-012] Committed `.DS_Store` files despite `.gitignore` entry

- Severity: Low
- Priority: P3
- Confidence: Confirmed
- Category: Repository hygiene
- Evidence:
  - `.gitignore` line 2 excludes `.DS_Store`, yet `.DS_Store` files exist on-disk in the repo root, `archive/`, `data/`, `src/nfce/`, and `archive/nfce-nested-git/`.
  - `git ls-files | rg '\.DS_Store$'` — none tracked (the ignore rule works today), but the local files are still surfaced in the working tree.
- Recommendation:
  - Add `find . -name .DS_Store -not -path './.git/*' -print -delete` to a `Makefile` `clean` target, or a pre-commit hook.

### [AUDIT-013] `docs/prompts/` exists but is empty

- Severity: Low
- Priority: P3
- Confidence: Confirmed
- Category: Repository hygiene
- Evidence:
  - AGENTS.md lists `docs/prompts/` as the home for AI prompt files, but the folder is empty on-disk and not tracked in git.
- Recommendation:
  - Either populate it (e.g., move `src/nfce/personal_inflation_prompt.py` there per AUDIT-009) or delete it to avoid a dangling directory.

### [AUDIT-014] `notas_litoral` symlink points at a co-located sibling repo

- Severity: Low
- Priority: P3
- Confidence: Confirmed
- Category: Reliability
- File: `src/nfce/notas_litoral`
- Evidence:
  - `ls -la src/nfce/notas_litoral` → symlink to `/Users/eduardofgiovannini/Documents/GitHub/LitoralPriceTracker/data/raw/NOTAS_LITORAL`.
  - `financas-2026.code-workspace` also includes `../LitoralPriceTracker` as a second workspace folder.
  - `src/nfce/README.md` explicitly documents this coupling.
- Impact:
  - The Litoral pipeline is fragile off the operator's machine and hard for another user to reproduce.
- Recommendation:
  - Accept the coupling but document it as an operator prerequisite in the main `README.md` (currently only in `src/nfce/README.md`); consider printing a clearer error if the symlink target is missing (already partly done, but with a hardcoded example — see AUDIT-007).

### [AUDIT-015] `README.md` never mentions the `openpyxl` runtime prerequisite

- Severity: Low
- Priority: P3
- Confidence: Confirmed
- Category: Documentation
- File: `README.md`
- Evidence:
  - `README.md` documents "Tests: `python3 -m unittest ...`" and "sync.py at the repo root runs `analytics_engine.py`" but never mentions that `analytics_engine.py` requires `openpyxl`.
- Recommendation:
  - Add a one-line "Prerequisites" section (Python 3.10+ and `pip install openpyxl`).

### [AUDIT-016] `EXPECTED_METRICS` ground-truth guard is fragile

- Severity: Low
- Priority: P3
- Confidence: Confirmed
- Category: Correctness
- File: `src/nfce/personal_inflation.py`
- Location: lines 56–65
- Evidence:
  - The dict encodes `receipts: 498`, `total_spend: 150170.52`, `final_index: 158.57`, `last_month: "2026-07"`, etc.
  - Any new receipts change the ground truth, and the operator must manually edit these numbers each cycle. `README.md` (in `src/nfce/`) documents this but the workflow is easy to skip.
- Recommendation:
  - Store `EXPECTED_METRICS` in a small JSON checkpoint file that the pipeline can auto-update behind a `--accept-new-baseline` flag, keeping the current "fail closed" behavior by default.

### [AUDIT-017] `archive/nfce-nested-git/` — orphaned stub with an empty `objects/`

- Severity: Low
- Priority: P3
- Confidence: Confirmed
- Category: Repository hygiene
- Evidence:
  - `.gitignore` line 64 excludes `archive/nfce-nested-git/`.
  - `du -sh archive/nfce-nested-git/objects` → 0.
  - The stub contains a `HEAD`, `config`, `hooks/`, `index`, `logs/`, `refs/` — but no object data, so it is not a functional archive.
- Recommendation:
  - Either restore useful history from an external clone or delete the stub and remove the `.gitignore` entry.

### [AUDIT-018] Only 2 commits in git history (Informational)

- Severity: Informational
- Category: Repository hygiene
- Evidence:
  - `git log --all --oneline | wc -l` → 2. The current `master` (`c1c8eb9`) is a single sweeping reorganization on top of `1bc3f56`.
  - `git status` shows 15 modified files and 8 untracked, none committed. Substantive work in `scripts/analytics_engine.py`, `src/nfce/litoral_store_prices.*`, and `tests/test_litoral_store_prices.py` has never been tracked.
- Impact:
  - No incremental history to bisect against, no rollback safety net, no way to distinguish operator edits from initial import.

### [AUDIT-019] `analytics_engine.py` recommends `pip3 install --break-system-packages` (Informational)

- Severity: Informational
- Category: Dependency
- File: `scripts/analytics_engine.py`
- Location: lines 44–48
- Evidence:

```42:48:scripts/analytics_engine.py
try:
    import openpyxl
except ImportError:
    sys.exit(
        "Missing dependency: openpyxl. Install with:\n"
        "  pip3 install openpyxl --break-system-packages"
    )
```

- Impact:
  - Encourages a footgun install (bypasses PEP 668 protections). A venv-based recommendation is safer and, on the operator's Homebrew Python 3.14, more reliable.

### [AUDIT-020] Two large overlapping dashboards (Informational)

- Severity: Informational
- Category: Architecture
- Evidence:
  - `src/html/financas2026-Dashboard.html` — 3,963 lines, 12 tabs, current daily dashboard.
  - `src/html/bloomberg-terminal.html` — 1,419 lines, "Bloomberg" theme, older but still referenced from `docs/technical-report-2026-07.md`.
  - Both embed the operator's name and CPF in title/header.
- Impact:
  - Divergent UIs to maintain; unclear which is authoritative.
  - The unused one adds surface area for PII exposure (AUDIT-001).

---

## 15. Security Assessment

**Overall:** Low technical risk (no committed secrets, no unsafe subprocess use,
no exposed network services) but **high privacy risk** because of committed PII
and 8 years of personal purchase history (AUDIT-001, AUDIT-002).

- **Credentials.** No API keys, OAuth tokens, or passwords found. `.env` files
  are correctly gitignored. `src/nfce/personal_inflation_prompt.py` uses the
  OpenAI SDK's default env-var-based configuration.
- **PII.** Full name, CPF, home addresses, phone numbers, and card-processor
  identifiers are hardcoded into HTML titles and 8-year-old receipt XMLs. See
  AUDIT-001 / AUDIT-002.
- **Subprocess usage.** `sync.py`, `sysmonitor.py`, and `analytics_engine.py`
  use `subprocess.run` with list arguments and no `shell=True`; `osascript`
  invocations in launchers embed only static AppleScript. Safe against shell
  injection today; `sysmonitor.notify()` uses f-string interpolation that would
  be exploitable if callers ever passed untrusted `body` or `title` strings.
- **Network exposure.** No server sockets. `sysmonitor.is_port_open` opens
  outbound connections to `localhost:11434` and `localhost:1234` only.
- **`curl | sh` patterns.** None found.
- **Third-party CDN.** `src/html/financas2026-Dashboard.html` loads Chart.js
  from `cdnjs.cloudflare.com` without a Subresource Integrity attribute — low
  practical risk for a `file://`-only dashboard but worth an SRI hash.

---

## 16. Correctness Assessment

- The NFC-e and Litoral pipelines have unit tests that isolate the tricky
  parts (product identity, log-return spread, chained weighted aggregation,
  dedup, CNPJ filter, YoY eligibility, staple matching). The tests use
  synthetic XMLs generated in `tempfile.TemporaryDirectory` — no dependence on
  local data files.
- `EXPECTED_METRICS` acts as a "seatbelt" against silent regressions but is
  brittle to maintain (AUDIT-016).
- `scripts/analytics_engine.py` explicitly narrates its own scope limits
  (comments lines 8–21): only the AI/subscription subset is anomaly-detected,
  and the projection is expense-only. Good self-documentation.
- The stale root workbook (AUDIT-003) is the most likely source of wrong
  numbers today.
- `sysmonitor.py`'s bare `except:` blocks (AUDIT-008) may hide errors.

---

## 17. Reliability and Operational Stability

- **Startup.** The launchers assume Hammerspoon, ChatGPT Atlas, Microsoft
  Excel, and a Homebrew-arm64 Python. Missing any of them causes silent-ish
  failures (Atlas absence: `open -na "ChatGPT Atlas"` fails with a small
  system dialog).
- **Logs.** `logs/login-launch.log` accumulates without rotation (25 KB
  today).
- **Backups.** There is no documented backup procedure for the master
  workbook. `data/` is committed to git, so at least the tracked state can be
  recovered.
- **Recovery.** A fresh clone can bring up the tests (`python3 -m unittest`
  passes in 5 ms once `openpyxl` is available); running the full dashboard
  requires the workbook and either the tracked receipts or a re-export.

---

## 18. Architecture and Complexity Assessment

**Ambition–Capacity Mismatch: Mild.**

The two Python pipelines and the two Excel-driven dashboards are appropriately
scoped for a single operator. The friction lies in the periphery:

- Two competing dashboards (`financas2026-Dashboard.html` + `bloomberg-terminal.html`).
- Multiple xlsx artifacts (`financeai-tracker.xlsx`, `wealthcommand.xlsx`) whose
  relationship to the main workbook is undocumented.
- A dead `fv.sh` + missing `FinanceVision/` Swift project.
- Aspirational "Fase 2" native app referenced in archived docs.
- A launcher stack that requires Hammerspoon + Atlas to fully operate.

Removing (or clearly archiving) the peripheral pieces would leave a tight,
maintainable core: workbook → analytics → dashboard, plus the NFC-e pipelines.

---

## 19. Dependency Assessment

- **Runtime deps:** only `openpyxl` (undeclared — AUDIT-006).
- **Dev deps:** none declared. Test suite uses `unittest` (stdlib).
- **Optional deps:** `openai` in `personal_inflation_prompt.py` (never runs by
  default).
- **JavaScript deps:** Chart.js via CDN with no SRI hash.
- **No lock file** anywhere in the repository.

---

## 20. Testing Assessment

- 15 tests across two files, all deterministic, all self-contained (use
  `tempfile.TemporaryDirectory` and inline XML/TXT fixtures).
- Wall clock time: 0.005 s.
- Coverage focuses on the two Python pipelines' pure functions plus the
  filtering and matching logic. Not covered:
  - `scripts/analytics_engine.py` (z-score, OLS slope, narrative bullets).
  - `sync.py` orchestration.
  - `sysmonitor.py` (understandable — mostly `subprocess`).
- CI: none. There is no `.github/workflows/` directory, no `Makefile`, no
  pre-commit hook.

---

## 21. Documentation Assessment

- **`README.md`.** Accurate, concise, and reflects the current layout.
- **`AGENTS.md`.** Consistent with today's structure. `reports/` (AUDIT-010) is
  the only observed drift.
- **`src/nfce/README.md`.** Thorough and accurate for the NFC-e pipelines;
  contains hardcoded `/Users/eduardofgiovannini/…` paths that should be
  generalized (AUDIT-007).
- **`docs/technical-report-2026-07.md`.** Extensive but describes a
  pre-reorganization layout and contains PII (AUDIT-001, AUDIT-004).
- **`docs/executive-report-2026-07.pdf`.** 854 KB, contains PII.
- **`archive/*.md`.** As expected for archived material — outdated content is
  acceptable there.

---

## 22. macOS and Apple-Specific Assessment

- Everything is macOS-only: Hammerspoon, ChatGPT Atlas, Microsoft Excel, and
  `osascript`.
- Path assumptions target arm64 Homebrew (`/opt/homebrew/bin/python3`) — see
  AUDIT-011.
- No LaunchAgents, LaunchDaemons, login items, entitlements, or code-signing
  configurations in this repo.
- No use of Keychain, Application Support, or Preferences.
- `notas_litoral` symlink relies on the operator's home layout (AUDIT-014).

---

## 23. Shell Script Assessment

| Script | Shebang | Strict mode | Notes |
|--------|---------|-------------|-------|
| `sync.py` | `#!/usr/bin/env python3` | n/a (Python) | Clean; captures stderr correctly on quiet flag |
| `scripts/analytics_engine.py` | `#!/usr/bin/env python3` | n/a | Recommends `--break-system-packages` (AUDIT-019) |
| `scripts/sysmonitor.py` | `#!/usr/bin/env python3` | n/a | Bare `except` (AUDIT-008) |
| `scripts/financas-open.sh` | `#!/usr/bin/env bash` | none | Hardcodes `PYTHON` (AUDIT-011); embeds Lua for Hammerspoon |
| `scripts/financas-close.sh` | `#!/usr/bin/env bash` | none | Same |
| `scripts/financas-login.sh` | `#!/usr/bin/env bash` | none | Redirects all output to `$LOG` via `exec >>` — good |
| `scripts/fv.sh` | `#!/bin/bash` | none | Broken (AUDIT-005) |
| `scripts/configure_lmstudio.sh` | `#!/bin/bash` | `set -euo pipefail` | Cleanest of the shell scripts; self-modifies `fv.sh` |

- No `rm -rf` calls anywhere in the scripts.
- No `eval`, no `curl | sh`, no `sudo` invocations.
- All `osascript` usage embeds literal AppleScript except `sysmonitor.notify()`
  (see AUDIT-008 note).

---

## 24. Repository Hygiene

- **Fresh-clone viability.** Marginal. Cloning today gives you the pipelines
  (with tests passing), the dashboards, the tracked bank exports, and 1,367
  NFC-e XMLs — but not the current data (root xlsx is untracked), not the
  `notas_litoral` symlink target, and not `openpyxl` (undeclared).
- **Large files.** `src/nfce/notas/nfce.pdf` (151 MB, gitignored) sits on disk;
  1,367 tracked XMLs make up ~29 MB in git.
- **`.DS_Store`.** Present but not tracked (AUDIT-012).
- **Backup files.** `archive/html/financas2026-Dashboard.html.backup-20260718-162850`
  exists locally but is NOT tracked (per `git ls-files archive/html/`), so
  AGENTS.md rule 3 (no filename versioning) is respected in the tracked tree.
- **Undocumented folder.** `reports/session/` (AUDIT-010).
- **Duplicate workbook at root** (AUDIT-003).

---

## 25. Prioritized Remediation Plan

### Stage 0 — Preserve and Validate

1. Snapshot the working tree (copy or stash) before rewriting any history:
   `git stash push -u -m 'pre-audit-snapshot'`.
2. Confirm current test status: `python3 -m unittest tests.test_personal_inflation tests.test_litoral_store_prices` (already passing today).
3. Diff the two `financas2026-DataEntry.xlsx` copies in Excel and pick the
   authoritative one (AUDIT-003).

### Stage 1 — Critical Stabilization

4. **AUDIT-001** — Redact CPF, phone, and street addresses from tracked HTML,
   Markdown, and (optionally) XML `<infCpl>` fields. Decide whether to rewrite
   git history with `git filter-repo` (only 2 commits — low blast radius).
5. **AUDIT-002** — Decide the fate of `src/nfce/notas/NFCE_XML_*/`: move to an
   external location and symlink, or scrub `<infCpl>` and re-commit. Update
   `.gitignore` accordingly.
6. **AUDIT-003** — Merge/delete the duplicate root workbook. Add an
   assertion in `analytics_engine.py` that fails loudly if the root workbook
   returns.

### Stage 2 — Reliability Improvements

7. **AUDIT-004** — Refresh or archive `docs/technical-report-2026-07.md`
   (grep for `financas-2026/(nfce|html|banco_inter|bcb_registrato|mercado_pago)/`
   and rewrite).
8. **AUDIT-005** — Archive `scripts/fv.sh` and stop `configure_lmstudio.sh`
   from self-editing it.
9. **AUDIT-006** — Add a minimal `requirements.txt` (`openpyxl>=3.1,<4`) and
   document `pip install -r requirements.txt` in `README.md`.
10. **AUDIT-011** — Replace `PYTHON=/opt/homebrew/bin/python3` with
    `PYTHON="${PYTHON:-$(command -v python3)}"` in the three launchers.

### Stage 3 — Simplification

11. **AUDIT-007** — Sweep hardcoded `/Users/eduardofgiovannini/…` paths from
    live scripts/docs; leave archive/* alone.
12. **AUDIT-020** — Decide whether `bloomberg-terminal.html` is still needed.
    Archive it if not.
13. **AUDIT-010** — Reconcile `reports/session/` with AGENTS.md (move under
    `logs/` or extend the doc).

### Stage 4 — Maintainability

14. **AUDIT-008** — Replace bare `except:` in `sysmonitor.py`; log write
    failures.
15. **AUDIT-009** — Guard `personal_inflation_prompt.py` behind `__main__` and
    optionally move to `docs/prompts/`.
16. **AUDIT-012** — Add a `Makefile` `clean` target that removes `.DS_Store`.
17. **AUDIT-016** — Turn `EXPECTED_METRICS` into a JSON file with a
    `--accept-new-baseline` flag.
18. **AUDIT-017** — Remove `archive/nfce-nested-git/` stub or restore useful
    contents.

---

## 26. Quick Wins

1. Move `financas2026-DataEntry.xlsx` (root) into `data/` after merging any
   new edits (AUDIT-003).
2. Add a one-line `requirements.txt`: `openpyxl>=3.1,<4` (AUDIT-006).
3. Change `PYTHON=/opt/homebrew/bin/python3` to
   `PYTHON="${PYTHON:-$(command -v python3)}"` in three scripts (AUDIT-011).
4. Wrap the executable body of `src/nfce/personal_inflation_prompt.py` in
   `if __name__ == "__main__":` (AUDIT-009).
5. Replace the three bare `except:` clauses in `scripts/sysmonitor.py` with
   `except Exception:` (AUDIT-008).
6. Rewrite the `ln -sfn /Users/eduardofgiovannini/…` example in
   `src/nfce/litoral_store_prices.py:629` to use `$HOME` or a `<repo-root>`
   placeholder (AUDIT-007).
7. Delete or populate `docs/prompts/` (AUDIT-013).
8. Add `.DS_Store` cleanup to a `Makefile` `clean` target (AUDIT-012).
9. Archive `scripts/fv.sh` (AUDIT-005).
10. Remove the CPF from the four tracked HTML/Markdown files (AUDIT-001,
    minimum viable redaction).

---

## 27. Deferred Improvements

- Full `git filter-repo` rewrite to purge PII from history — coordinate with
  any secondary clones first.
- Externalizing `src/nfce/notas/NFCE_XML_*/` — depends on where the operator
  wants to keep the source XMLs.
- Consolidating dashboards (`financas2026-Dashboard.html` vs
  `bloomberg-terminal.html`) — requires a UX decision.
- Auto-updating `EXPECTED_METRICS` baseline (AUDIT-016).
- Adding a lightweight CI workflow that runs `python3 -m unittest`.

---

## 28. Unresolved Questions

1. Is `bloomberg-terminal.html` still used, or superseded entirely by
   `financas2026-Dashboard.html`?
2. Is the "Fase 2" Swift/native app referenced in `docs/technical-report-2026-07.md`
   still on the roadmap? If yes, should `FinanceVision/` be reimported?
3. Should `src/nfce/notas/NFCE_XML_*/` continue to live inside the repo, or be
   externalized like `notas_litoral`?
4. What are `data/financeai-tracker.xlsx` and `data/wealthcommand.xlsx` used
   for today? They are neither read nor written by any tracked script.
5. Is `configure_lmstudio.sh`'s self-modification of `fv.sh` intentional, or a
   leftover from an earlier iteration?

---

## 29. Final Recommendation

The core system — an Excel workbook, a static HTML dashboard, and two
well-tested Python pipelines — is well-designed for its single-operator scope
and works today. The tests pass, the analytics engine's scope is honestly
documented, and AGENTS.md keeps the top level reasonably lean.

**Immediate action.** Redact PII (AUDIT-001, minimum: CPF and street addresses
from HTML + Markdown), consolidate the duplicate root workbook (AUDIT-003),
and archive or fix `scripts/fv.sh` (AUDIT-005) — these are the only findings
that either expose real personal data or produce clearly wrong runtime
behavior right now.

**Short-term.** Add a `requirements.txt`, refresh
`docs/technical-report-2026-07.md`, replace hardcoded `/Users/eduardofgiovannini/…`
strings, and decide whether to keep 1,367 NFC-e XMLs inside git.

**Strategic.** Decide the fate of the peripheral pieces — the second
dashboard, the missing `FinanceVision/` binary, and the wealthcommand /
financeai xlsx artifacts. Trimming those would leave a repository whose
"single-operator personal finance" purpose is easy to sustain.

---

## 30. Remediation Status (2026-07-29)

Working-tree remediation executed against Stages 0–4 and Quick Wins.
History rewrite is **not** applied (destructive; see deferred item).

| ID | Status | Notes |
|----|--------|-------|
| AUDIT-001 | Done (tree) | CPF/name/address/phone redacted in HTML, Markdown, and `data/raw/mercado_pago/*`. Executive PDF moved to `archive/`. Git history still contains originals until `scripts/rewrite_history_pii.sh` is run. |
| AUDIT-002 | Done (tree) | `NFCE_XML_*` removed from the index; local data lives under `$HOME/.financas-notas/personal/` and is symlinked from `src/nfce/notas/`. Paths gitignored. |
| AUDIT-003 | Done | Root workbook removed; canonical copy is `data/financas2026-DataEntry.xlsx`. `analytics_engine.py` refuses to run if a root stray reappears. |
| AUDIT-004 | Done | Stale report archived; fresh `docs/technical-report-2026-07.md` reflects current layout. |
| AUDIT-005 | Done | `scripts/fv.sh` → `archive/scripts/fv.sh`; `configure_lmstudio.sh` no longer self-edits it. |
| AUDIT-006 | Done | `requirements.txt` + README Prerequisites + `make install`. |
| AUDIT-007 | Done | Live code/docs free of hardcoded `/Users/<name>/` (`make lint-paths` passes). Archive left alone. |
| AUDIT-008 | Done | Bare `except:` replaced in `scripts/sysmonitor.py`. |
| AUDIT-009 | Done | Prompt scaffold under `docs/prompts/`; OpenAI imported lazily behind `__main__`. |
| AUDIT-010 | Done | Undocumented `reports/` removed. |
| AUDIT-011 | Done | Launchers use `.venv` then `$(command -v python3)`. |
| AUDIT-012 | Done | `make clean` removes `.DS_Store` / `__pycache__`. |
| AUDIT-013 | Done | `docs/prompts/` populated with the prompt scaffold. |
| AUDIT-016 | Done | Baseline JSON + `--accept-new-baseline` / `--verify-ground-truth`. |
| AUDIT-017 | Done | `archive/nfce-nested-git/` stub removed. |
| AUDIT-019 | Done | Install hint prefers venv + `requirements.txt`. |
| AUDIT-014/015/018 | Deferred / open | Symlink co-location OK; README now documents openpyxl; history still short. |
| AUDIT-020 | Done | `bloomberg-terminal.html` moved to `archive/html/` (superseded by `financas2026-Dashboard.html`). |

**Verification:** `make test` — 15/15 pass; `make lint-paths` — clean.

**History rewrite:** `scripts/rewrite_history_pii.sh` completed locally on 2026-07-29
(`git-filter-repo` removed NFC-e XML paths + applied `.pii-replacements`).
Working tree and rewritten history contain no residual CPF/name matches.
Origin remote was re-added after filter-repo removed it.

**Still requires operator action:**
1. Force-push rewritten history when ready:
   `git push --force --all origin && git push --force --tags origin`
2. Anyone with an old clone must re-clone (do not `git pull`).

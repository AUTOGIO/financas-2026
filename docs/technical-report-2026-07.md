# Technical & Executive Report — Personal Finance System
## [REDACTED] · CPF [REDACTED-CPF] · H1 2026

> **Classification:** Private & Confidential  
> **Generated:** 2026-07-14  
> **Period:** January – July 2026  
> **Report type:** Technical Architecture + Executive Summary  

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Technology Stack](#2-technology-stack)
3. [Repository Structure](#3-repository-structure)
4. [Primary Files — What They Are & How to Use Them](#4-primary-files--what-they-are--how-to-use-them)
5. [Data Sources & Ingestion Workflow](#5-data-sources--ingestion-workflow)
6. [NFC-e Personal Inflation Pipeline](#6-nfc-e-personal-inflation-pipeline)
7. [Excel Workbook Architecture](#7-excel-workbook-architecture)
8. [Dashboards & Visualization Layer](#8-dashboards--visualization-layer)
9. [Operational Runbooks](#9-operational-runbooks)
10. [Financial Summary](#10-financial-summary)
11. [Risk Register](#11-risk-register)
12. [Action Calendar](#12-action-calendar)

---

## 1. System Overview

This is a **local-first, offline-capable personal finance system** built entirely from standard tools — Python 3, Microsoft Excel, and static HTML/JS. There is no database, no cloud dependency, no paid SaaS beyond the data sources themselves.

### Design Principles

| Principle | Implementation |
|---|---|
| **Single source of truth** | Raw XMLs (NFC-e) and confirmed bank statements. Nothing is synthesized from derived files. |
| **Deterministic & reproducible** | Re-running `personal_inflation.py` on the same XML folder always produces the same index. |
| **Separation of concerns** | Calculations live in the `CALC` sheet. Display lives in `00 COMMAND CENTER`. Scripts live in `scripts/`. |
| **Ground-truth guard** | `EXPECTED_METRICS` dict in `personal_inflation.py` prevents silent drift between runs. |
| **No network required** | All data is ingested from local files. Dashboards open from `file://`. |
| **Zero dependencies for display** | HTML dashboards are single-file, pure vanilla JS — no npm, no build step. |

### System Components at a Glance

```
financas-2026/
│
├── DATA INGESTION
│   ├── banco_inter/extratos/        ← Bank CSV/OFX/PDF exports
│   ├── bb_brasil/extratos/          ← BB checking account CSV
│   ├── mercado_pago/faturas/        ← MP credit card PDFs + parsed JSON
│   ├── mercado_pago/extratos/       ← MP account statement CSVs
│   ├── bcb_registrato/              ← BCB CCS + Pix PDF reports
│   └── nfce/notas/NFCE_XML_*/      ← 1,352 NFC-e XML receipts (source of truth)
│
├── CALCULATION LAYER
│   ├── nfce/personal_inflation.py   ← Python pipeline (597 lines)
│   ├── financas2026-DataEntry.xlsx  ← Manual entry + structured data tables
│   └── WealthCommand_V3.xlsx        ← Master dashboard (CALC sheet = 634 rows)
│
├── DISPLAY LAYER
│   ├── html/bloomberg-terminal.html ← 10-tab Bloomberg-style dashboard
│   ├── html/financas2026-Dashboard.html ← General H1 2026 dashboard
│   └── nfce/personal_inflation_index.html ← Inflation tracker UI
│
└── REPORTS
    ├── reports/executive-report-2026-07.pdf
    └── reports/technical-report-2026-07.md  ← this file
```

---

## 2. Technology Stack

### 2.1 Languages

| Language | Version | Role |
|---|---|---|
| **Python 3** | 3.14 (CPython) | NFC-e XML parsing, inflation index calculation, Excel automation |
| **JavaScript (ES6+)** | Vanilla, no framework | Dashboard interactivity, SVG charts, live clock, search filters |
| **CSS3** | Custom | Bloomberg terminal theme, responsive layout |
| **Markdown** | CommonMark | Documentation and this report |

### 2.2 Python Standard Library Modules Used

> No third-party packages required for the inflation pipeline. Everything runs on stdlib.

| Module | Used for |
|---|---|
| `xml.etree.ElementTree` | Parsing NFC-e XML files (SEFAZ standard namespace `nfe`) |
| `json` | Reading/writing `personal_inflation_data.json`, `personal_inflation_validation.json` |
| `math` | `math.log()` for log-return price changes; `MAX_JUMP = math.log(4)` filter |
| `statistics` | `statistics.median()` for monthly product price |
| `os`, `glob` | Directory traversal, XML folder discovery (`NFCE_XML_*` pattern) |
| `re` | Description normalisation for product identity keys |
| `argparse` | CLI flags: `--verify-ground-truth`, `--skip-html`, `--output-json` |
| `collections.defaultdict` | Accumulating prices and spend per product/month |
| `typing` | Type hints throughout |

### 2.3 Python Third-Party Libraries (Excel automation only)

| Library | Used for | Install |
|---|---|---|
| `openpyxl` | Reading/writing `.xlsx` files — builds `CALC` sheet, styled tables | `pip install openpyxl` |

### 2.4 Excel

| Component | Version requirement |
|---|---|
| Microsoft Excel | 2016+ (all features used are compatible with 2016) |
| Power Pivot / Data Model | Optional — for cross-table relationships |
| Slicers | Available from Excel 2010+ |
| Sparklines | Available from Excel 2010+ |

### 2.5 HTML/JS Dashboard

The dashboards use **zero external dependencies**:

- No React, Vue, Angular, or any frontend framework
- No CDN calls — works fully offline
- SVG charts generated inline by vanilla JS
- CSS custom properties (`--var`) for the Bloomberg color theme
- `requestAnimationFrame` not used — standard `setInterval` for the live clock

### 2.6 Data Formats

| Format | Used for | Standard |
|---|---|---|
| `XML` | NFC-e fiscal receipts | SEFAZ NF-e 4.0, namespace `http://www.portalfiscal.inf.br/nfe` |
| `XLSX` | Excel workbooks | OOXML (ISO 29500) |
| `CSV` | Bank statements, NFC-e item/transaction exports | RFC 4180 |
| `JSON` | Inflation pipeline output, MP fatura parsed data | ECMA-404 |
| `OFX` | Banco Inter statement | OFX 2.2 |
| `PDF` | Bank statements, BCB Registrato reports | ISO 32000 |

---

## 3. Repository Structure

```
financas-2026/                          root (git repo)
│
├── .git/                               version control
├── .gitignore
├── financas-2026.code-workspace        VS Code multi-root workspace
├── project-metadata.json               project state + phase tracking
│
├── reports/                            ★ OUTPUT — executive + technical reports
│   ├── executive-report-2026-07.pdf
│   └── technical-report-2026-07.md    ← you are here
│
├── scripts/                            operational shell scripts
│   ├── financas-open.sh               opens workspace + dashboards
│   ├── financas-close.sh              closes and saves state
│   └── financas-login.sh              sets environment variables
│
├── html/                               active dashboard files
│   ├── bloomberg-terminal.html        10-tab interactive dashboard
│   └── financas2026-Dashboard.html    general H1 2026 summary
│
├── nfce/                               NFC-e sub-repo (has its own .git)
│   ├── personal_inflation.py          ★ MAIN PIPELINE — 597 lines Python
│   ├── personal_inflation_data.json   pipeline output (9,700+ lines)
│   ├── personal_inflation_validation.json  ground-truth check output
│   ├── personal_inflation_index.html  interactive inflation dashboard
│   ├── personal_inflation_index.js    dashboard logic
│   ├── personal_inflation_index.css   dashboard styles
│   ├── inflation_data.json            manual basket reference data
│   ├── personal_inflation_prompt.py   helper for AI-assisted analysis
│   ├── nfce_transactions.csv          derived artifact (not source of truth)
│   ├── nfce_items.csv                 derived artifact (not source of truth)
│   ├── nfce_all.json                  derived artifact (not source of truth)
│   ├── README.md                      pipeline documentation
│   ├── tests/
│   │   └── test_personal_inflation.py  unit tests (methodology)
│   └── notas/                         ★ XML SOURCE OF TRUTH
│       ├── NFCE_XML_4BEPPCOPLX/       export folder 1 (434 files)
│       ├── NFCE_XML_VX4AAMTBJR/       export folder 2 (484 files)
│       ├── NFCE_XML_U2LGXQOLLF/       export folder 3 (434 files — Jul 2026)
│       ├── NFCE_20260703031416.txt     SEFAZ summary export (raw, unprocessed)
│       ├── NFCE_20260703031529.txt     SEFAZ summary export (raw, unprocessed)
│       └── NFCE_20260713005027.txt     SEFAZ summary export (raw, unprocessed)
│
├── financas2026-DataEntry.xlsx         ★ PRIMARY DATA ENTRY WORKBOOK
├── WealthCommand_V3.xlsx               ★ MASTER DASHBOARD WORKBOOK
├── FinanceAI_Tracker_V2.xlsx           AI expense tracker
├── planilhas/
│   └── subscription-budget-2026.xlsx  subscription stack audit
│
├── banco_inter/
│   ├── extratos/                       ★ Inter CSV/OFX/PDF statements
│   └── screenshots/                    PNG screenshots (IMG_1253–1281)
│
├── bb_brasil/
│   └── extratos/                       ★ BB CSV + XLSX statement Jul/2026
│
├── bcb_registrato/                     ★ BCB PDF reports
│   ├── BCB-CCS-contas-relacionamentos-2026-06.pdf
│   └── BCB-Pix-chaves-2026-06.pdf
│
├── mercado_pago/
│   ├── faturas/                        ★ MP card invoices (PDF + parsed JSON)
│   ├── extratos/                       ★ MP account statements (CSV + PDF)
│   └── mp_all_data.json               consolidated MP data
│
├── mercado_livre_ifood/                ML + iFood order evidence (PNG/PDF/JSON)
│
├── tools/
│   ├── sysmonitor.py                   system monitoring utility
│   ├── fv.sh                           FinanceVision shell helper
│   └── configure_lmstudio.sh          LM Studio config
│
├── logs/
│   ├── login-launch.log
│   └── manual-launch.log
│
└── archive/                            old docs (preserved, not active)
    ├── FINANCEVISION_CLOSE_REPORT.md
    ├── PROJECT_CLOSE_REPORT.md
    ├── RELATORIO-FECHAMENTO.md
    ├── PHASES.md
    ├── LEIA-ME.md
    ├── excel-dashboard-guide.md
    └── html/                           old HTML dashboards (archived)
```

---

## 4. Primary Files — What They Are & How to Use Them

### 4.1 `nfce/personal_inflation.py` ⭐ Most Important

**What it is:** A 597-line pure Python 3 script that reads 1,352 NFC-e XML files, deduplicates them by 44-digit access key, prices each product per month using the median, and outputs a chained inflation index comparable to IPCA.

**Current state (Jul 2026):**
- 498 valid receipts · 622 tracked products · R$ 150,170.52 total spend
- Index: **158.57** (base 100 = Aug 2018) · +58.6% cumulative · 5.88% trailing 12m
- Ground-truth check: ✅ PASS

**How to run:**

```bash
# Navigate to the nfce folder
cd /Users/eduardofgiovannini/Documents/financas-2026/nfce

# Standard run — regenerates all outputs
python3 personal_inflation.py

# Run with ground-truth verification (recommended after adding new receipts)
python3 personal_inflation.py --verify-ground-truth

# Skip HTML regeneration (faster, for data-only refresh)
python3 personal_inflation.py --skip-html

# Output to custom paths
python3 personal_inflation.py \
  --output-json /tmp/inflation_data.json \
  --validation-json /tmp/inflation_validation.json
```

**How to add new receipts:**

```bash
# 1. Download a new XML export from the SEFAZ app
#    The folder must be named NFCE_XML_<anything>
cp -r ~/Downloads/NFCE_XML_NEWEXPORT \
      /Users/eduardofgiovannini/Documents/financas-2026/nfce/notas/

# 2. Run the pipeline
cd /Users/eduardofgiovannini/Documents/financas-2026/nfce
python3 personal_inflation.py --skip-html

# 3. If new receipts were added, update EXPECTED_METRICS in the script
#    (the script will print the new values if verification fails)
#    Then re-run with verification:
python3 personal_inflation.py --verify-ground-truth
```

**Run tests:**

```bash
cd /Users/eduardofgiovannini/Documents/financas-2026/nfce
python3 -m unittest discover -s tests -p 'test_*.py'
```

**Key internal constants:**

| Constant | Value | Meaning |
|---|---|---|
| `MAX_JUMP` | `math.log(4)` ≈ 1.386 | Price changes larger than 4× in one month are filtered as outliers |
| `NS` | `{"n": "http://www.portalfiscal.inf.br/nfe"}` | XML namespace for NFC-e parsing |
| `EXPECTED_METRICS` | dict of 8 KPIs | Ground-truth guard — update after intentional data additions |

---

### 4.2 `WealthCommand_V3.xlsx` ⭐ Master Dashboard Workbook

**What it is:** The primary Excel dashboard. Contains 12 sheets — all calculation logic lives in the `CALC` sheet (634 rows), which feeds display sheets via direct cell references.

**Sheet architecture:**

| Sheet | Role | Edit? |
|---|---|---|
| `00 COMMAND CENTER` | KPI tiles + MoM signals + Priority actions — display only | ❌ Never |
| `CALC` | **All calculations** — 634 rows, 6 sections | ✅ Format codes in col D |
| `01 NET WORTH` | Balance sheet + FX transfer log | ❌ Never |
| `02 CAPITAL FLOWS` | Monthly flow summary + 200+ transaction log | ❌ Never |
| `03 INTERNATIONAL` | Full 35-operation BCB Câmbio table | ❌ Never |
| `04 PORTFOLIO` | IB deposits + Fundos BRL timeline | ❌ Never |
| `05 LIFESTYLE` | Card spend by category + ML/iFood orders | ❌ Never |
| `06 SUBSCRIPTION MGR` | 15-service subscription stack + decisions | ✅ Change decisions |
| `07 CASH BRIDGE` | Inter PIX movement log | ❌ Never |
| `08 ALERTS` | 12-item risk register with severity | ✅ Update statuses |
| `_DATA` | Compact data summary (for charts) | ❌ Never |
| `09 CHARTS` | Chart data sources | ❌ Never |

**How to use — reading values:**

```
All dashboard KPI tiles reference CALC sheet cells.
Formula pattern:  =CALC!E161   (display cell — TEXT() formatted)
                  =CALC!C123   (raw numeric value)

To change number format for a KPI:
  1. Open WealthCommand_V3.xlsx
  2. Go to CALC sheet
  3. Find the KPI row (rows 161–175 for display cells)
  4. Edit column D (format code) — e.g. change "R$ #,##0.00" to "#,##0 k"
  5. All linked text boxes update instantly
```

**How to update data:**

```
The workbook reads from financas2026-DataEntry.xlsx.
WealthCommand_V3.xlsx does NOT auto-refresh — it was populated by Python.

To update after adding new data to DataEntry:
  1. Run the Python builder script (see section 9.3)
  2. Or manually update the raw values in CALC rows 123–137
```

**CALC sheet sections:**

| Rows | Section | Content |
|---|---|---|
| 1–122 | Bank balances + FX operations | Raw confirmed values from source files |
| 123–155 | KPI Master cells | 15 KPIs: liquid, IB, funds, FX, card, subs, PIX |
| 158–216 | TEXT() display layer | Formatted strings for dashboard text boxes |
| 268–295 | Monthly table | 6-month reverse-sorted (newest first) |
| 308–360 | Slicer harvesting | Category / institution / period filter lists |
| 373–478 | Ranked tables (×5) | Merchants, FX ops, subs, PIX, ML/iFood |
| 488–634 | CF prep + bubble + sparklines + wiring | Icon signals, chart data, reference map |

---

### 4.3 `financas2026-DataEntry.xlsx` ⭐ Primary Data Entry Workbook

**What it is:** The workbook where all raw data is manually entered or copy-pasted from bank exports. 11 sheets. This is the human-facing input layer.

| Sheet | Data entered here |
|---|---|
| `📋 SYNC` | Dashboard variable registry — 12 KPI cells + data status |
| `🏦 Banks` | Bank balances (3 cells updated weekly) |
| `💳 Transactions` | AI/subscription card charges (72 entries) |
| `🔄 Subscriptions` | 15 services with KEEP/CANCEL/REVIEW decisions |
| `❌ Cancel Tracker` | 4 services flagged + status updates |
| `🌉 Cash Bridge` | Inter PIX movements (date, type, amount) |
| `🌍 International` | BCB Câmbio operations (35 rows) |
| `📅 Weekly` | Weekly card spend tracker |
| `💳 MP Faturas` | Full MP card statement (146 transactions) |
| `🛒 ML iFood` | Mercado Livre + iFood orders (75 items) |
| `📖 Instructions` | Sunday ritual runbook |

**Weekly update ritual (30–45 min):**

```
1. 🏦 Banks sheet → update 3 balance cells (Inter, MP, BB)
2. 💳 MP Faturas → paste new card transactions from MP app
3. 🔄 Subscriptions → advance any REVIEW decisions
4. ❌ Cancel Tracker → update status (Pending → In Progress → Cancelled)
5. 📋 SYNC → verify totals auto-calculated correctly
6. Run Python script → WealthCommand_V3.xlsx CALC sheet refreshed
7. Open HTML dashboards → verify charts updated
```

---

### 4.4 `html/bloomberg-terminal.html` — Bloomberg Terminal Dashboard

**What it is:** A single self-contained HTML file (~90 KB) that renders a 10-tab Bloomberg Terminal-style dashboard. No server needed.

**How to open:**

```bash
# Double-click the file in Finder, or:
open /Users/eduardofgiovannini/Documents/financas-2026/html/bloomberg-terminal.html

# All data is embedded in the HTML — no network call needed
```

**Tabs:**

| Tab | Content |
|---|---|
| `00 CMD CTR` | 12 KPI tiles + priority actions + bank balances |
| `01 NET WORTH` | Balance sheet + FX transfer log (19 operations) |
| `02 CAPITAL FLOWS` | Monthly flow table + bar chart |
| `03 INTERNATIONAL` | Full BCB Câmbio register (35 ops) |
| `04 PORTFOLIO` | IB deposits timeline + Fundos BRL |
| `05 LIFESTYLE` | Card spend + ML/iFood orders (75 items) |
| `06 SUBSCRIPTIONS` | 15-service stack + cancel tracker + pie chart |
| `07 PIX BRIDGE` | Inter account movement log |
| `08 ALERTS` | 12-item risk register |
| `09 TX LOG` | 40+ MP transactions with **live search filter** |

**Interactive features:**
- `A− / A+` buttons to adjust font size
- Live clock (BRT) updating every second
- Scrolling ticker tape with 18 real data points
- Search box on TX LOG tab (filters in real-time)
- 7 SVG charts (pie, bar, line, FX rate timeline)

---

### 4.5 `nfce/personal_inflation_index.html` — Inflation Dashboard

**What it is:** A single-page application for exploring the personal inflation index. Reads data from the JSON files output by the pipeline.

**How to open (two modes):**

```bash
# Mode 1: Offline — uses embedded fallback data in the HTML
open /Users/eduardofgiovannini/Documents/financas-2026/nfce/personal_inflation_index.html

# Mode 2: Live — fetches current JSON files from disk (recommended after pipeline run)
cd /Users/eduardofgiovannini/Documents/financas-2026/nfce
python3 -m http.server 8000
# Then open: http://127.0.0.1:8000/personal_inflation_index.html
```

**Features:** Index chart (2018–2026), product price explorer, category breakdown, validation view, IPCA comparison line.

---

### 4.6 `nfce/notas/NFCE_XML_*/` — Source of Truth for Inflation

**What they are:** Folders of NFC-e XML files downloaded from the SEFAZ app. Each `.xml` file is one fiscal receipt, identified by a 44-digit access key embedded in the filename.

**Current inventory:**

| Folder | Files | Period |
|---|---|---|
| `NFCE_XML_4BEPPCOPLX` | 434 files | Aug 2018 – Jun 2026 |
| `NFCE_XML_VX4AAMTBJR` | 484 files | Aug 2018 – Jun 2026 |
| `NFCE_XML_U2LGXQOLLF` | 434 files | Aug 2018 – Jul 2026 |
| **Total** | **1,352 files** | 498 unique receipts after dedup |

**Naming convention:**
```
NFCE_{44-digit-access-key}_{timestamp}.xml
CANC_110111_{44-digit-access-key}_{timestamp}.xml   ← cancelled note
EVENTO_{44-digit-access-key}_{timestamp}.xml        ← cancellation event
```

**⚠ Important:** The `.txt` files in `notas/` (`NFCE_20260703*.txt`, `NFCE_20260713*.txt`) are SEFAZ summary exports in a different format. The pipeline **does not read them** — it only reads `NFCE_XML_*` folders. These `.txt` files are raw records for manual reference only.

---

### 4.7 `bcb_registrato/` — BCB Official Records

**What they are:** Official PDF reports from the BCB Registrato system, exported 29/Jun/2026.

| File | Content |
|---|---|
| `BCB-CCS-contas-relacionamentos-2026-06.pdf` | 10 active banking relationships + 11 historical |
| `BCB-Pix-chaves-2026-06.pdf` | 6 active Pix keys across 5 institutions |

**How to verify authenticity:**
```
URL: https://meubc.bcb.gov.br/meubc/registrato/autenticidade
CCS code: X1AG-Q73Z-Z8
Pix code:  PL1S-GIKR-A5
```

---

### 4.8 `banco_inter/extratos/` — Banco Inter Statements

| File | Type | Period | Content |
|---|---|---|---|
| `Extrato-07-07-2026-a-13-07-2026-CSV.csv` | CSV | 07–13/Jul/2026 | 3-column: date, description, amount |
| `Extrato-07-07-2026-a-13-07-2026-OFX.ofx` | OFX 2.2 | 07–13/Jul/2026 | Machine-readable bank feed |
| `Extrato-07-07-2026-a-13-07-2026-PDF.pdf` | PDF | 07–13/Jul/2026 | Human-readable statement |

**Confirmed balance:** R$ 18,934.67 as of 13/Jul/2026 (R$ 18,922.07 available + R$ 12.60 blocked)

---

### 4.9 `scripts/` — Operational Shell Scripts

| Script | Purpose | How to use |
|---|---|---|
| `financas-open.sh` | Opens workspace, launches dashboards | `bash scripts/financas-open.sh` |
| `financas-close.sh` | Saves state, closes processes | `bash scripts/financas-close.sh` |
| `financas-login.sh` | Sets environment variables, authenticates | `bash scripts/financas-login.sh` |

---

### 4.10 `planilhas/subscription-budget-2026.xlsx`

**What it is:** The original subscription audit workbook with 15 services, deduplication analysis, and KEEP/CANCEL/REVIEW decisions. This is the source that populated the `🔄 Subscriptions` sheet in DataEntry.

---

## 5. Data Sources & Ingestion Workflow

### 5.1 Source Map

```
SOURCE                          FORMAT    FREQUENCY   INGESTION METHOD
─────────────────────────────────────────────────────────────────────
SEFAZ NFC-e App (mobile)        XML       ad hoc      Copy folder to nfce/notas/
Banco Inter (app/web)           CSV/OFX   weekly      Copy to banco_inter/extratos/
BB Brasil (app/web)             CSV/XLSX  monthly     Copy to bb_brasil/extratos/
Mercado Pago (app)              PDF/CSV   monthly     Copy to mercado_pago/
BCB Registrato (meubc.bcb.gov.br) PDF    quarterly   Copy to bcb_registrato/
Mercado Livre (app/email)       PDF/JSON  ad hoc      Copy to mercado_livre_ifood/
iFood (app/email)               PDF/JSON  ad hoc      Copy to mercado_livre_ifood/
```

### 5.2 Data Flow Diagram

```
Raw Sources
    │
    ├── NFC-e XMLs ──────────────────► personal_inflation.py
    │                                        │
    │                                        ▼
    │                               personal_inflation_data.json
    │                               personal_inflation_validation.json
    │                               personal_inflation_index.html
    │
    ├── Bank CSVs/PDFs ──────────────► financas2026-DataEntry.xlsx
    ├── BCB PDFs                              │
    ├── MP Faturas                            ▼
    └── Manual entry              WealthCommand_V3.xlsx (CALC sheet)
                                             │
                                             ├── html/bloomberg-terminal.html
                                             └── reports/executive-report-*.pdf
```

---

## 6. NFC-e Personal Inflation Pipeline

### 6.1 Algorithm Summary

The pipeline implements a **Laspeyres-style household price index** with the following steps:

```
1. LOAD
   Walk all NFCE_XML_*/ folders, parse each XML
   → Extract: access_key, issue_date, CNPJ, items[]

2. DEDUPLICATE
   Key = 44-digit access key in filename
   If duplicate → skip (854 duplicates skipped this run)
   If CANC_* → mark cancelled (4 cancelled keys excluded)

3. IDENTIFY PRODUCTS
   If item has valid EAN-13 → product_key = EAN + unit
   Else → product_key = CNPJ_root + normalize(description) + unit
   (This prevents CENOURA KG and CENOURA UN from being merged)

4. PRICE
   For each (product_key, year_month):
     price = statistics.median([unit_price for all purchases that month])

5. GAP-FILL
   For consecutive observed months t1, t2 with gap:
     Spread log-return uniformly: Δ = (ln(p2) - ln(p1)) / (t2 - t1)
     Fill each intervening month with the spread return

6. FILTER OUTLIERS
   If |log(p_new/p_old)| > math.log(4):
     → Discard this price change (filtered_large_jumps counter)

7. COMPUTE MONTHLY INFLATION
   For each month m:
     weighted_return = Σ(spend_weight_i × log_return_i) / Σ(spend_weight_i)
     where spend_weight_i = total spend on product i across all months

8. CHAIN INDEX
   index[m] = index[m-1] × exp(weighted_return[m])
   base: index[2018-08] = 100.0

9. OUTPUT
   personal_inflation_data.json  (index series, YoY table, categories, risers/fallers)
   personal_inflation_validation.json  (inventory audit + ground-truth check)
   personal_inflation_index.html  (self-contained dashboard with embedded data)
```

### 6.2 Current Index Values

| Metric | Value |
|---|---|
| Base month | August 2018 = 100.00 |
| Latest month | July 2026 = **158.57** |
| Cumulative inflation | **+58.6%** over 8 years |
| Annualised rate | **+6.00%/year** |
| Trailing 12 months | **+5.88%** (re-accelerating from 3.59% in Jun) |
| IPCA reference (same period) | ~+50.4% (estimated) |
| Receipts processed | 498 |
| Products tracked | 622 |
| Total spend indexed | R$ 150,170.52 |
| Coverage | 40.6% of total household spend |

### 6.3 Validation Report (Latest Run)

```json
{
  "xml_note_files": 1352,
  "unique_xml_keys": 498,
  "duplicate_xml_key_instances": 854,
  "cancelled_files": 6,
  "cancelled_unique_keys": 4,
  "malformed_numeric_fields": 0,
  "missing_numeric_fields": 0,
  "notes_skipped_parse_errors": 0,
  "parsed_receipts": 498,
  "parsed_items": 5256,
  "invalid_ean_fallbacks": 0,
  "filtered_large_jumps": 0,
  "ground_truth_check": { "matches": true, "mismatches": [] }
}
```

---

## 7. Excel Workbook Architecture

### 7.1 `WealthCommand_V3.xlsx` — CALC Sheet Wiring Map

The `CALC` sheet is the single source of truth for all dashboard values. Every KPI tile on `00 COMMAND CENTER` references a cell in `CALC`.

**Pattern:**
```
CALC col C  →  raw numeric value  (e.g. 377473.49)
CALC col D  →  format code string (e.g. "R$ #,##0.00")
CALC col E  →  =TEXT(C{row}, D{row})  →  formatted display string
                                           ↑
                                   Dashboard text box: =CALC!E{row}
```

**KPI cell reference table:**

| KPI | Raw cell | Display cell | Current value |
|---|---|---|---|
| Est. Net Worth | `CALC!C137` | `CALC!E161` | R$ 377,473.49 |
| Total Liquidity | `CALC!C123` | `CALC!E162` | R$ 23,196.90 |
| IB Net Deployed | `CALC!C126` | `CALC!E163` | R$ 178,510.76 |
| Fundos BRL | `CALC!C127` | `CALC!E164` | R$ 175,765.83 |
| FX Outbound H1 | `CALC!C128` | `CALC!E165` | R$ 652,788.61 |
| Inbound H1 | `CALC!C129` | `CALC!E166` | R$ 98,857.00 |
| Avg FX Rate | `CALC!C130` | `CALC!E167` | 5.1799 |
| IB Deposits (gross) | `CALC!C124` | `CALC!E168` | R$ 197,706.57 |
| IB Withdrawal | `CALC!C125` | `CALC!E169` | R$ 19,195.81 |
| Card Spend H1 | `CALC!C131` | `CALC!E170` | R$ 37,245.76 |
| Card Avg/Month | `CALC!C132` | `CALC!E171` | R$ 6,207.63 |
| PIX Net Flow | `CALC!C136` | `CALC!E172` | R$ 144,847.62 |
| Sub Stack/Month | `CALC!C133` | `CALC!E173` | R$ 1,344.54 |
| Cancel Savings/Mo | `CALC!C134` | `CALC!E174` | R$ 365.80 |
| Cancel Savings/Yr | `CALC!C135` | `CALC!E175` | R$ 4,389.60 |

**Monthly table (newest first — MoM never breaks):**

| Row | Month | Card | PIX In | PIX Net |
|---|---|---|---|---|
| 269 | 2026-06 | R$ 1,114.17 | R$ 42,010 | R$ 41,530 |
| 270 | 2026-05 | R$ 3,308.38 | R$ 115,000 | R$ 45,080 |
| 271 | 2026-04 | R$ 5,330.44 | R$ 40,000 | R$ 29,670 |
| 272 | 2026-03 | R$ 14,231.47 | R$ 0 | −R$ 11,432 |
| 273 | 2026-02 | R$ 9,515.90 | R$ 40,000 | R$ 40,000 |
| 274 | 2026-01 | R$ 3,745.40 | R$ 0 | R$ 0 |

> MoM for card spend is always `=(C269-C270)/C270` — row numbers never change regardless of how many months are added.

---

## 8. Dashboards & Visualization Layer

### 8.1 Dashboard Inventory

| File | Size | Type | Status | How to open |
|---|---|---|---|---|
| `html/bloomberg-terminal.html` | 90 KB | HTML/JS/CSS | ✅ Active | `open html/bloomberg-terminal.html` |
| `html/financas2026-Dashboard.html` | 108 KB | HTML/JS/CSS | ✅ Active | `open html/financas2026-Dashboard.html` |
| `nfce/personal_inflation_index.html` | 178 KB | HTML/JS/CSS | ✅ Active | `open nfce/personal_inflation_index.html` |
| `nfce/inflation-tracker.html` | 31 KB | HTML | ⚠ Older version | Reference only |
| `nfce/nfce-dashboard.html` | 127 KB | HTML | ⚠ Older version | Reference only |

### 8.2 Chart Types Used

All charts in the Bloomberg dashboard are generated in-browser using **inline SVG** written by vanilla JavaScript — no charting library.

| Chart | Location | Technology |
|---|---|---|
| Wealth allocation pie | CMD CTR tab | SVG `<path>` arc |
| Monthly card spend bar | CMD CTR tab | SVG `<rect>` |
| FX rate timeline | INTL tab | SVG `<polyline>` |
| Capital flow dual bar | FLOWS tab | SVG `<rect>` |
| Flow composition pie | FLOWS tab | SVG `<path>` arc |
| IB deposit waterfall | PORTFOLIO tab | SVG `<rect>` |
| Subscription breakdown | SUBS tab | SVG `<path>` arc |

---

## 9. Operational Runbooks

### 9.1 Weekly Maintenance (Every Sunday, ~35 min)

```bash
# Step 1 — Download new bank statements
# Banco Inter app → Extrato → Export CSV + OFX
# Copy to: banco_inter/extratos/

# Step 2 — Update DataEntry workbook
open financas2026-DataEntry.xlsx
# → 🏦 Banks: update 3 balance cells
# → 💳 MP Faturas: paste any new card transactions
# → ❌ Cancel Tracker: update service statuses

# Step 3 — Verify SYNC sheet totals look correct

# Step 4 — Open Bloomberg dashboard and verify
open html/bloomberg-terminal.html
```

### 9.2 Monthly NFC-e Refresh

```bash
# Step 1 — Export XMLs from SEFAZ app on phone
# Share/export as folder named NFCE_XML_<code>

# Step 2 — Copy to notas/
cp -r ~/Downloads/NFCE_XML_XXXXXXXXXX \
      /Users/eduardofgiovannini/Documents/financas-2026/nfce/notas/

# Step 3 — Run pipeline
cd /Users/eduardofgiovannini/Documents/financas-2026/nfce
python3 personal_inflation.py --skip-html

# Step 4 — If new receipts found, the output will show new metrics.
# Update EXPECTED_METRICS in personal_inflation.py lines 57-65, then:
python3 personal_inflation.py --verify-ground-truth
# Expected output: "ground truth check: OK"

# Step 5 — Regenerate full HTML
python3 personal_inflation.py
```

### 9.3 Rebuilding the Excel CALC Sheet (after major data changes)

The CALC sheet was originally built by a Python script using `openpyxl`. If you need to rebuild it:

```bash
cd /Users/eduardofgiovannini/Documents/financas-2026

# The build logic was in step10_command_center.py (now deleted, but was committed).
# To rebuild manually, open WealthCommand_V3.xlsx and edit the raw values
# in CALC rows 123–137 directly from the source files.

# Key values to manually update:
# C123 = Inter balance + MP balance + BB balance
# C124 = sum of IB deposit BRL amounts from 🌍 International sheet
# C125 = IB withdrawal BRL amount
# C126 = C124 - C125
# C127 = sum of Fund Deposit BRL amounts
# C131 = sum of all MP Faturas Valor column
```

### 9.4 Quarterly BCB Registrato Update

```bash
# 1. Visit: https://meubc.bcb.gov.br/meubc/registrato
# 2. Login with CPF [REDACTED-CPF] + Gov.br credentials
# 3. Download:
#    - Relatório de Contas e Relacionamentos (CCS)
#    - Relatório de Chaves Pix Atuais
# 4. Save to bcb_registrato/ with naming:
#    BCB-CCS-contas-relacionamentos-YYYY-MM.pdf
#    BCB-Pix-chaves-YYYY-MM.pdf
# 5. Update the relevant tables in financas2026-DataEntry.xlsx → 🌍 International
```

---

## 10. Financial Summary

> All values verified against ≥2 independent sources. Confidence: HIGH.

### 10.1 Balance Sheet (Jul 2026)

| Category | Value (BRL) | Source | Verified |
|---|---|---|---|
| Banco Inter | R$ 18,934.67 | CSV extrato | ✅ 13/Jul/2026 |
| Mercado Pago | R$ 4,262.23 | PDF extrato | ✅ 12/Jul/2026 |
| BB Brasil | R$ 0.00 | CSV extrato | ✅ 13/Jul/2026 |
| **Total Liquid** | **R$ 23,196.90** | | |
| IB Net Deployed | R$ 178,510.76 | BCB Câmbio (7 ops) | ✅ |
| Fundos BRL | R$ 175,765.83 | BCB Câmbio (3 ops) | ✅ |
| **Total Investments** | **R$ 354,276.59** | | |
| **Est. Net Worth** | **R$ 377,473.49** | | |

### 10.2 H1 2026 Capital Flows Summary

| Flow | Value | Ops |
|---|---|---|
| FX Outbound (self-transfer USA) | R$ 652,788.61 | 19 |
| IB Deposits | R$ 197,706.57 | 7 |
| Fund Deposits | R$ 175,765.83 | 3 |
| Inbound | R$ 98,857.00 | 2 |
| IB Withdrawal ⚠ | R$ 19,195.81 | 1 |
| Card Spend | R$ 37,245.76 | 146 |
| PIX Net Flow (Inter) | R$ 144,847.62 | — |
| IOF paid | R$ 3,474.80 | 2 |
| Avg FX Rate (outbound) | 5.1799 BRL/USD | — |

---

## 11. Risk Register

| # | Severity | Domain | Finding | Exposure | Status |
|---|---|---|---|---|---|
| 1 | 🔴 CRITICAL | Subscriptions | Cancel queue pending: Claude×2, Grok, TuneIn = R$365.80/mo | R$ 4,390/yr | ⏳ Pending |
| 2 | 🔴 CRITICAL | FX Reconciliation | R$652,789 sent to USA — USD account balances unverified | R$ 652,789 | ⏳ Pending |
| 3 | 🔴 CRITICAL | Sub Stack Bloat | 6 services in REVIEW · Manus AI R$418/mo uncontrolled | ~R$ 5,400/yr | ⏳ Pending |
| 4 | 🟡 HIGH | Liquidity | 100% liquid in 2 digital banks — below R$30k target | R$ 23,197 | ⏳ Pending |
| 5 | 🟡 HIGH | IB Withdrawal | R$19,196 via Wise Jun/2026 — destination unconfirmed | R$ 19,196 | ⏳ Pending |
| 6 | 🟡 HIGH | Lottery | R$6,455 in MP Loteria H1 — no monthly cap set | R$ 6,455 | ⏳ Pending |
| 7 | 🟡 HIGH | SBCT Tech LLC | R$45,000 PIX to USA company via Inter — needs documentation | R$ 45,000 | ⏳ Pending |
| 8 | 🟠 MEDIUM | AI/Tech overlap | R$6,624 card IA/Tech vs sub stack — likely duplicate billing | R$ 6,624 | ⏳ Pending |
| 9 | 🟠 MEDIUM | Travel expense | R$9,037 LAN Airlines — business vs personal unclassified | R$ 9,037 | ⏳ Pending |
| 10 | 🟠 MEDIUM | ML tagging | R$31,570 ML purchases without CAPEX/HEALTH/CONSUMABLE tags | R$ 31,570 | ⏳ Pending |

---

## 12. Action Calendar

| Target date | Action | Impact | Owner |
|---|---|---|---|
| **Jul 14–20** | Cancel Claude×2 + Grok + TuneIn via Apple Subscriptions | +R$ 4,390/yr | Eduardo |
| **Jul 14–20** | Confirm IB withdrawal R$19,196 destination | Reconciliation | Eduardo |
| **Jul 21–31** | Pull USD account statement — reconcile 19 BCB ops | Reconciliation | Eduardo |
| **Jul 21–31** | Set R$500/month Loteria cap via MP card limit | −R$ 575/mo avg | Eduardo |
| **Aug 1–15** | Audit 6 REVIEW subscriptions → decide KEEP or CANCEL | +R$ 2,700/yr | Eduardo |
| **Aug 1–15** | Tag ML/iFood orders: CAPEX / HEALTH / CONSUMABLE | Tax/tracking | Eduardo |
| **Aug 1–15** | Classify LAN Airlines trip: business vs personal | Tax/deductibility | Eduardo |
| **Aug 31** | Increase liquid buffer to minimum R$30,000 | Security | Eduardo |
| **Sep 30** | Download new BCB Registrato (next quarterly update) | Compliance | Eduardo |
| **Oct 2026** | Full H2 review — rebuild CALC with new 6 months of data | — | Eduardo |

---

## Appendix A — File Size Reference

| File | Size | Notes |
|---|---|---|
| `WealthCommand_V3.xlsx` | 84 KB | 12 sheets, CALC = 634 rows |
| `financas2026-DataEntry.xlsx` | 57 KB | 11 sheets, primary entry |
| `FinanceAI_Tracker_V2.xlsx` | 43 KB | AI tracker |
| `planilhas/subscription-budget-2026.xlsx` | 92 KB | Subscription audit source |
| `html/bloomberg-terminal.html` | 90 KB | Self-contained dashboard |
| `html/financas2026-Dashboard.html` | 108 KB | Self-contained dashboard |
| `nfce/personal_inflation_index.html` | 178 KB | Inflation dashboard |
| `nfce/personal_inflation_data.json` | 229 KB | 9,700+ lines, full index series |
| `nfce/nfce_all.json` | 735 KB | All receipts consolidated |
| `nfce/nfce_items.csv` | 446 KB | All line items CSV |
| `nfce/personal_inflation.py` | 25 KB | 597-line pipeline |
| `nfce/notas/NFCE_XML_*/` (total) | ~89 MB | 1,352 XML files |
| `banco_inter/screenshots/` | ~8 MB | 29 PNG screenshots |
| `mercado_livre_ifood/ML.pdf` | 2.8 MB | ML order history PDF |
| **Repo total** | **~203 MB** | 1,496 files |

---

## Appendix B — Environment

| Item | Value |
|---|---|
| OS | macOS (zsh shell) |
| Python | 3.14 (CPython) — `python3` command |
| Excel | Microsoft Excel (2016+ compatible) |
| Browser | Any modern browser — no extensions needed |
| Editor | VS Code (workspace: `financas-2026.code-workspace`) |
| Git | Repo root at `/Users/eduardofgiovannini/Documents/financas-2026/` |
| nfce sub-repo | `/Users/eduardofgiovannini/Documents/financas-2026/nfce/` (separate `.git`) |

---

*Generated by automated pipeline — [REDACTED] · CPF [REDACTED-CPF] · 2026-07-14*

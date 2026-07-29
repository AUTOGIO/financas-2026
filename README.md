# financas-2026

Local personal finance workspace: Excel data entry, bank/NFC-e exports, and
static HTML dashboards (no cloud app, no build step).

## Prerequisites

- Python 3.10+ (tested on 3.14)
- `openpyxl` (the only third-party runtime dependency)
- macOS-only extras for the launcher scripts: Microsoft Excel, Hammerspoon,
  ChatGPT Atlas. The Python pipelines and the dashboards work without them.

### Install

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# or:  make install
```

The launcher scripts auto-detect `.venv/bin/python3` when it exists.

## Run

- Open the master workbook: `data/financas2026-DataEntry.xlsx`
  (do **not** create a copy at the repo root — `scripts/analytics_engine.py`
  refuses to run if it finds one, see AUDIT-003).
- Dashboards: open `src/html/financas2026-Dashboard.html`, or use
  `scripts/financas-open.sh` / `scripts/financas-login.sh` on macOS.
- NFC-e personal inflation:
  `cd src/nfce && python3 personal_inflation.py --verify-ground-truth`
- Litoral store prices (see symlink note below):
  `cd src/nfce && python3 litoral_store_prices.py`
- Tests: `python3 -m unittest tests.test_personal_inflation tests.test_litoral_store_prices`
  (or `make test`)

`sync.py` at the repo root runs `scripts/analytics_engine.py` on every
open/close to refresh `data/insights.json`.

### External data prerequisites

Two of the runtime inputs are **not** in this repository and must be provided
locally:

1. **Personal NFC-e receipts** — expected under `src/nfce/notas/NFCE_XML_*/`.
   These are gitignored (personal purchase history + PII, see AUDIT-002 in
   `REPOSITORY_AUDIT.md`). Point the pipeline at any directory via
   `python3 src/nfce/personal_inflation.py --notes-dir /path/to/xmls`.
2. **Litoral store snapshots** — expected at `src/nfce/notas_litoral/`.
   Symlink your local checkout of the sibling repository:

   ```bash
   ln -sfn "$HOME/Documents/GitHub/LitoralPriceTracker/data/raw/NOTAS_LITORAL" \
       src/nfce/notas_litoral
   ```

## Where things live

- `src/` — dashboards and NFC-e app
- `data/` — workbooks and raw bank/receipt exports
- `scripts/` — open/close/login helpers and the analytics engine
- `docs/` — reports · `docs/prompts/` — AI prompt scaffolds
- `config/` — project metadata
- `tests/` — unit tests
- `archive/` — obsolete material kept for reference
- Root: only `README.md`, `AGENTS.md`, `Makefile`, `requirements.txt`,
  `.gitignore`, and toolchain files

Latest upgrade summary: [`docs/UPGRADE_REPORT_2026-07.md`](docs/UPGRADE_REPORT_2026-07.md).

## Developer tasks

Common Make targets:

```bash
make install       # create .venv/ and install requirements
make sync          # refresh data/insights.json
make test          # run the unittest suite
make lint-paths    # fail if hardcoded /Users/<name>/ paths appear in live code
make clean         # remove .DS_Store and __pycache__ artifacts
```

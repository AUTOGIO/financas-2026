# financas-2026

Local personal finance workspace: Excel data entry, bank/NFC-e exports, and static HTML dashboards (no cloud app).

## Run

- Open the main workbook: `data/financas2026-DataEntry.xlsx`
- Dashboards: open `src/html/financas2026-Dashboard.html` (or use `scripts/financas-open.sh` / `scripts/financas-login.sh` on Mac)
- NFC-e inflation pipeline: `cd src/nfce && python3 personal_inflation.py --verify-ground-truth`
- Tests: `python3 -m unittest tests.test_personal_inflation`

Note: launchers still call `sync.py` at the repo root; that file is not present yet.

## Where things live

- `src/` — dashboards and NFC-e app · `data/` — workbooks and raw bank/receipt exports  
- `scripts/` — open/close/login helpers · `docs/` — reports · `config/` — project metadata · `archive/` — old material  

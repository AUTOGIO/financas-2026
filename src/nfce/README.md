# NFC-e Personal Inflation

Local, deterministic analysis of one household's personal inflation from Brazilian NFC-e XMLs.

## Source Of Truth

- Primary input: XML files under [notas](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/notas)
- Current XML inventory:
  - 2 export folders: `NFCE_XML_*`
  - 918 XML note files
  - 496 unique valid receipt keys after deduplication
  - 4 unique cancelled keys excluded
- Supporting artifacts only:
  - [nfce_transactions.csv](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/nfce_transactions.csv)
  - [nfce_items.csv](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/nfce_items.csv)
  - existing JSON/HTML outputs

The CSVs are not complete enough to reproduce the final index by themselves. The XMLs are the only reliable baseline for reruns.

## Current Pipeline

- Entry point: [personal_inflation.py](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/personal_inflation.py)
- Method:
  - product identity = valid EAN, else `CNPJ-root + normalized description`
  - commercial unit stays in the grouping key
  - monthly product price = median unit price
  - price gaps are spread with monthly log returns
  - jumps larger than `4x` are filtered
  - monthly inflation = spend-weighted mean of active log returns
  - chained base = `100` at the first active month

## Run

From this repo root:

```bash
cd /Users/eduardofgiovannini/Documents/financas-2026/src/nfce
python3 personal_inflation.py --verify-ground-truth
```

Optional flags:

```bash
python3 personal_inflation.py --skip-html
python3 personal_inflation.py --output-json /tmp/personal_inflation_data.json --validation-json /tmp/personal_inflation_validation.json
```

## Outputs

- [personal_inflation_data.json](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/personal_inflation_data.json)
  - main reproducible analysis payload
- [personal_inflation_validation.json](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/personal_inflation_validation.json)
  - inventory checks, duplicate/cancelled checks, numeric-field issues, invalid EAN handling, >4x jump filtering, ground-truth verification
- [personal_inflation_index.html](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/personal_inflation_index.html)
  - app shell with overview, product exploration, and validation views
- [personal_inflation_index.js](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/personal_inflation_index.js)
  - local UI state, charts, filters, and validation rendering
- [personal_inflation_index.css](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/personal_inflation_index.css)
  - dashboard styles

## Expected Reproduced Metrics

Successful execution should reproduce:

- valid receipts: `496`
- cancelled unique keys excluded: `4`
- total spend: `R$ 148,431.10`
- tracked products: `606`
- coverage: `40.1%`
- final index: `155.17` in `2026-06`
- trailing 12 months: `3.59%`

## Incremental Refresh

To add newly downloaded receipts, drop another export folder into `notas/` named
`NFCE_XML_<something>` and rerun:

```bash
python3 personal_inflation.py
```

Receipts are deduplicated by their 44-digit access key across all folders, so
re-downloading notes you already have never double-counts. Cancelled keys
(`CANC_*.xml`) are excluded and the validation report records the collapsed
duplicates.

If you intentionally add new receipts, `--verify-ground-truth` will fail until
you update `EXPECTED_METRICS` in [personal_inflation.py](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/personal_inflation.py).
That guard is meant to catch accidental drift between refreshes.

## Tests

Run the lightweight methodology tests:

```bash
cd /Users/eduardofgiovannini/Documents/financas-2026/src/nfce
python3 -m unittest discover -s tests -p 'test_*.py'
```

Coverage is intentionally narrow and focused on the core calculation rules:

- product identity
- unit separation
- monthly median pricing
- gap-spread log returns
- chained weighted aggregation
- incremental-refresh dedup by access key + cancelled-note exclusion

## Dashboard Use

You can open [personal_inflation_index.html](/Users/eduardofgiovannini/Documents/financas-2026/src/nfce/personal_inflation_index.html)
directly and it will use the embedded fallback payload written by the pipeline.

If you want the app to fetch the current JSON files live instead of relying on
the embedded fallback, serve the folder locally:

```bash
cd /Users/eduardofgiovannini/Documents/financas-2026/src/nfce
python3 -m http.server 8000
```

Then open [http://127.0.0.1:8000/personal_inflation_index.html](http://127.0.0.1:8000/personal_inflation_index.html).

## Known Gaps / Limits

- IPCA is still a rough embedded reference line, not a live external fetch.
- The dashboard is still a static local app, not a compiled frontend project.
- CSV artifacts remain useful for inspection, but they are partial historical extracts and should not be promoted to source-of-truth status.

# Upgrade Report — financas-2026 (July 2026)

**Date:** 2026-07-29  
**Scope:** Repository audit remediation + history rewrite + remaining cleanup  
**Branch:** `master` @ current HEAD  

---

## Summary

The repo went from a PII-heavy, post-reorg messy working tree to a lean
local-first finance workspace with redacted sources, untracked personal
receipts, passing tests, and CI. Git history was rewritten and force-pushed so
old commits no longer carry CPF/name/address blobs or 1,367 NFC-e XMLs.

---

## What changed

### Security & privacy
- Redacted operator CPF, name, addresses, and phones from live HTML, Markdown,
  and Mercado Pago exports.
- Moved executive PDF with PII into `archive/`.
- Stopped tracking `src/nfce/notas/NFCE_XML_*` (personal purchase history);
  local data lives under `$HOME/.financas-notas/personal/` via symlinks.
- Ran `git filter-repo` (`scripts/rewrite_history_pii.sh` + gitignored
  `.pii-replacements`) and force-pushed `origin/master`.
- Verified: no residual CPF/name matches in working tree or rewritten history.

### Correctness & tooling
- Canonical workbook is only `data/financas2026-DataEntry.xlsx`; root copies
  are refused by `analytics_engine.py`.
- Landed `sync.py`, `scripts/analytics_engine.py`, Litoral store price tracker
  (+ tests), `requirements.txt`, and `Makefile` (`install`, `sync`, `test`,
  `lint-paths`, `clean`).
- Launchers prefer `.venv` then `$(command -v python3)` (no Homebrew hardcode).
- `sysmonitor.py`: bare `except:` replaced.
- Prompt scaffold moved to `docs/prompts/` with lazy OpenAI import.
- Ground-truth baseline is JSON (`personal_inflation_baseline.json`) with
  `--verify-ground-truth` / `--accept-new-baseline`.

### Housekeeping
- Archived dead `fv.sh`, superseded `bloomberg-terminal.html`, and unused
  workbooks (`financeai-tracker`, `wealthcommand`, `subscription-budget-2026`)
  under `archive/`.
- Removed empty/orphan stubs (`reports/`, `archive/nfce-nested-git/`, macOS
  `" 2"` conflict copies).
- Fresh `docs/technical-report-2026-07.md`; stale copy archived.
- Added GitHub Actions workflow `.github/workflows/test.yml` (unittest +
  `lint-paths`).

---

## Verification (2026-07-29)

| Check | Result |
|-------|--------|
| `make test` | 15/15 pass |
| `make lint-paths` | clean |
| Tracked NFC-e XMLs | 0 |
| Root stray workbook | absent |
| `origin/master` | matches local after force-push |

---

## Layout after upgrades

```
financas-2026/
├── sync.py / Makefile / requirements.txt / AGENTS.md / README.md
├── scripts/          # launchers, analytics_engine, rewrite_history_pii
├── src/html/         # financas2026-Dashboard.html (primary UI)
├── src/nfce/         # personal inflation + Litoral pipelines
├── data/             # master workbook + raw bank exports
├── docs/             # technical report, prompts, this upgrade report
├── tests/            # unittest suite
├── .github/workflows/test.yml
└── archive/          # bloomberg, fv.sh, old reports, orphan xlsx
```

**Data flow (unchanged intent, cleaner paths):**

```
Excel workbook → analytics_engine.py → data/insights.json → Dashboard HTML
NFC-e XMLs (local) → personal_inflation.py → JSON + HTML index
Litoral XMLs (symlink) → litoral_store_prices.py → JSON + HTML
```

---

## Audit findings closed

| IDs | Outcome |
|-----|---------|
| AUDIT-001 … 013, 016, 017, 019, 020 | Done |
| AUDIT-014 | Accepted (operator-local `notas_litoral` symlink; documented in README) |
| AUDIT-015 | Done (README Prerequisites + `requirements.txt`) |
| AUDIT-018 | Informational only (short history after rewrite is expected) |
| Deferred: history rewrite, XML externalization, bloomberg, baseline JSON, CI | Done |

Open product choices intentionally left out of scope: rebuilding FinanceVision,
or merging any archived workbook content back into the master Excel file.

---

## Operator notes

1. Re-clone any machine that still has the pre-rewrite history (`git pull` is
   not enough after `filter-repo`).
2. Keep `.pii-replacements` local and gitignored; do not commit it.
3. Personal receipts: ensure `src/nfce/notas/NFCE_XML_*` still resolve to
   `$HOME/.financas-notas/personal/…`.
4. Litoral: refresh the `notas_litoral` symlink if the sibling repo moves.
5. Day-to-day: `make sync` → open `src/html/financas2026-Dashboard.html`.

---

## Commits in this upgrade wave

Representative sequence on `master` (hashes may differ after rewrite):

1. Remediate audit findings (PII, XMLs, tooling, Litoral tracker)
2. Document history rewrite
3. Mark force-push / AUDIT-001 complete
4. This leftover cleanup + upgrade report + CI

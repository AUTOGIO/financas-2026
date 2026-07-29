# AGENTS.md — financas-2026

Personal finance / analytics workspace (local-first). Prefer moves over rewrites. Do not invent new top-level folders.

## Folder layout

| Path | Purpose |
|------|---------|
| `src/` | Application code (HTML dashboards, NFC-e inflation pipeline) |
| `scripts/` | Runnable helpers (`.sh`, `.py` launchers/tools) |
| `config/` | Non-secret settings / metadata |
| `data/` | CSV, Excel, exports, raw inputs (`data/raw`) |
| `assets/` | Images, icons, logos (create only when needed) |
| `docs/` | Guides, reports, design notes |
| `docs/prompts/` | AI prompt files |
| `tests/` | Tests only |
| `archive/` | Obsolete files kept for reference |
| Root | Only `README.md`, `AGENTS.md`, `.gitignore`, `Makefile`, `requirements.txt`, `sync.py`, and toolchain files (e.g. `*.code-workspace`) |

## Rules

1. Prefer **MOVE** over copy; edit existing files over creating new ones.
2. Do not create new top-level folders without asking.
3. No filename versioning (`Foo_v1.md` → `docs/foo.md`; unsure → `archive/`).
4. Merge duplicate folders into the English names above.
5. Never commit secrets (`.env`, credentials, API keys).
6. After moves, fix broken paths in scripts and HTML.
7. Do not delete unless clearly a duplicate; otherwise move to `archive/`.

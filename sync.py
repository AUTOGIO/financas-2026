#!/usr/bin/env python3
"""
sync.py — financas-2026
────────────────────────────────────────────────────────────────
Placeholder invoked by the launcher scripts (financas-login.sh,
financas-open.sh, financas-close.sh) at workspace open/close.

Current behaviour: runs analytics_engine.py to refresh
data/insights.json so the dashboard always has fresh numbers.

Extend this file when you need additional sync steps, e.g.:
  - Pull bank exports from a shared folder / cloud drive
  - Push insights.json to a remote endpoint
  - Archive old log entries
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ANALYTICS = ROOT / "scripts" / "analytics_engine.py"
PYTHON = sys.executable


def main() -> None:
    parser = argparse.ArgumentParser(description="financas-2026 sync")
    parser.add_argument("--quiet", action="store_true", help="suppress non-error output")
    args = parser.parse_args()

    def log(msg: str) -> None:
        if not args.quiet:
            print(msg)

    log("sync.py: starting")

    # ── Step 1: refresh insights.json via analytics_engine ──────────────
    if ANALYTICS.exists():
        log(f"  → running {ANALYTICS.name} ...")
        result = subprocess.run(
            [PYTHON, str(ANALYTICS)],
            capture_output=args.quiet,
        )
        if result.returncode != 0:
            print(f"  ✗ analytics_engine exited with code {result.returncode}", file=sys.stderr)
            if args.quiet and result.stderr:
                print(result.stderr.decode(), file=sys.stderr)
        else:
            log("  ✓ insights.json updated")
    else:
        log(f"  ⚠  {ANALYTICS} not found — skipping analytics step")

    # ── Add future sync steps here ───────────────────────────────────────

    log("sync.py: done")


if __name__ == "__main__":
    main()

#!/usr/bin/env bash
# rewrite_history_pii.sh — Purge PII and personal NFC-e receipts from git history.
#
# ⚠️  DESTRUCTIVE + IRREVERSIBLE  ⚠️
# This uses `git filter-repo` to rewrite every commit in the repository.
# You MUST:
#   1. Have a clean working tree (`git status` empty).
#   2. Have every branch/tag you care about pushed to a backup remote first.
#   3. Coordinate with anyone who has cloned this repo — they will need to
#      `git clone` again, not `git pull`.
#   4. Force-push to origin ONLY after you have verified the rewritten repo
#      looks correct locally (`git log --stat`, run tests, open dashboards).
#
# Prerequisites:
#   brew install git-filter-repo         # or: pip install git-filter-repo
#
# Local (gitignored) pattern file:
#   Create `.pii-replacements` in the repo root with one `old==>new` line per
#   pattern (git-filter-repo --replace-text format). Never commit that file.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PATTERNS_FILE="$REPO_ROOT/.pii-replacements"

if ! command -v git-filter-repo >/dev/null 2>&1; then
  echo "❌ git-filter-repo is not installed."
  echo "   brew install git-filter-repo   # or:  pip install git-filter-repo"
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "❌ Working tree is not clean. Commit or stash first."
  git status --short
  exit 1
fi

if [[ ! -f "$PATTERNS_FILE" ]]; then
  echo "❌ Missing $PATTERNS_FILE"
  echo "   Create it with git-filter-repo --replace-text lines (old==>new)."
  echo "   That file is gitignored and must never be committed."
  exit 1
fi

echo "▶ Backing up refs before rewrite (safety net)..."
git for-each-ref --format='%(refname)' refs/heads refs/tags > /tmp/refs-before-filter-repo.txt

echo "▶ Removing personal NFC-e receipts from history..."
git filter-repo \
  --path src/nfce/notas/NFCE_XML_4BEPPCOPLX \
  --path src/nfce/notas/NFCE_XML_U2LGXQOLLF \
  --path src/nfce/notas/NFCE_XML_VX4AAMTBJR \
  --path-glob 'src/nfce/notas/NFCE_*.txt' \
  --invert-paths --force

echo "▶ Running text-replacement pass across surviving blobs..."
git filter-repo --replace-text "$PATTERNS_FILE" --force

echo "▶ Cleaning up unreachable objects..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "✓ History rewrite complete."
echo ""
echo "Next steps (do NOT skip):"
echo "  1. Inspect the result:  git log --stat"
echo "  2. Run the test suite:  make test"
echo "  3. Re-add the remote:   git remote add origin git@github.com:AUTOGIO/financas-2026.git"
echo "  4. Force push (only after 1-3 look correct):"
echo "       git push --force --all origin"
echo "       git push --force --tags origin"
echo "  5. Notify any collaborators to re-clone."

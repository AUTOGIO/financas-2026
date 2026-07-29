# financas-2026 · developer tasks
# Run `make help` for the full list.

.PHONY: help venv install sync test lint-paths clean clean-dsstore clean-pyc

PYTHON ?= python3
VENV   ?= .venv

help:  ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Targets:\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-16s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

venv:  ## Create a project-local virtual environment in .venv/
	$(PYTHON) -m venv $(VENV)

install: venv  ## Install runtime dependencies into .venv/
	$(VENV)/bin/pip install --upgrade pip
	$(VENV)/bin/pip install -r requirements.txt

sync:  ## Refresh data/insights.json from the master workbook
	$(PYTHON) sync.py

test:  ## Run the unit-test suite
	$(PYTHON) -m unittest tests.test_personal_inflation tests.test_litoral_store_prices

lint-paths:  ## Fail if hardcoded /Users/<name>/ paths crept back into live code
	@bad=$$(rg -n '/Users/[a-zA-Z0-9_-]+' \
	    -g '!archive/**' -g '!REPOSITORY_AUDIT.md' \
	    -g '!*.json' -g '!*.html' -g '!*.pdf' \
	    -g '!.git/**' -g '!node_modules/**' -g '!*.xlsx' \
	    2>/dev/null || true); \
	if [ -n "$$bad" ]; then \
	  echo "❌ hardcoded absolute user paths found:"; \
	  echo "$$bad"; \
	  exit 1; \
	else \
	  echo "✓ no hardcoded /Users/<name>/ paths in live code"; \
	fi

clean-dsstore:  ## Remove all .DS_Store files below the repo (never touches .git)
	find . -name .DS_Store -not -path './.git/*' -print -delete

clean-pyc:  ## Remove Python byte-caches
	find . -type d -name __pycache__ -not -path './.git/*' -exec rm -rf {} +
	find . -type f \( -name '*.pyc' -o -name '*.pyo' \) -not -path './.git/*' -delete

clean: clean-dsstore clean-pyc  ## Full local cleanup
	@echo "✓ workspace cleaned"

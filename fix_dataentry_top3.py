#!/usr/bin/env python3
"""
Surgical fix for the 3 highest-impact errors in financas2026-DataEntry.xlsx.
The workbook has drifted from rebuild_all.py (which is now stale), so it is the
hand-maintained source of truth and is patched directly here.

  FIX 1  📅 Weekly  — 11 pre-period transactions (Dec-2025 + early Jan, R$878.68)
                      fell before Week-1's start and were silently dropped, so the
                      TOTAL never matched 💳 Transactions. Fold them into Week 1 and
                      add a live reconciliation guard cell.

  FIX 2  📋 SYNC    — "Total Card Spend — 72 transactions" actually sums only the
                      curated AI/subscription subset (-R$10,231), not real card
                      spend (R$37,246). Relabel it, and wire the orphaned
                      💳 MP Faturas + 🛒 ML iFood sheets into the dashboard.

  FIX 4  🔄 Subscriptions — credit-based services (Manus x2, Desktop Commander) had
                      blank monthly cost = R$0, hiding the single largest recurring
                      spend (Manus ~R$418/mo). Fill Monthly BRL with trailing 6-mo
                      averages from actual charges, flagged as estimates.
"""
import datetime
import openpyxl
from openpyxl.comments import Comment

F = "financas2026-DataEntry.xlsx"
wb = openpyxl.load_workbook(F)  # keep formulas

# ---------------------------------------------------------------- FIX 1: Weekly
wk = wb["📅 Weekly"]
# Week 1 (row 4) now absorbs every transaction on/before its end date (2026-01-11),
# which captures the 11 pre-period charges. Value computed from 💳 Transactions.
wk["E4"] = -1032.06
wk["F4"] = 14
wk["G4"] = "Inclui 11 lançamentos pré-período (dez-2025 + início jan, R$878.68)"
# Live reconciliation guard: must equal 0.
wk["B31"] = "✓ RECONCILE vs Transactions (deve ser 0)"
wk["E31"] = "=E30-'💳 Transactions'!G76"

# ---------------------------------------------------------------- FIX 2: SYNC
sync = wb["📋 SYNC"]
sync["B13"] = "AI/Assinaturas no cartão — 72 tx (subconjunto)"
sync["G13"] = "Subset curado ⚠ (ver total real abaixo)"
# Wire the two orphaned full-statement sheets into the dashboard (new section,
# appended below existing content so no existing formula shifts).
sync["B34"] = "  💳  FATURAS COMPLETAS & MARKETPLACE (estava órfão)"
sync["B35"] = "Total Fatura MP — 146 tx (cartão completo)"
sync["C35"] = "=SUM('💳 MP Faturas'!D4:D149)"
sync["G35"] = "MP Faturas ✅"
sync["B36"] = "Mercado Livre — entregues"
sync["C36"] = "=SUMIFS('🛒 ML iFood'!D4:D72,'🛒 ML iFood'!B4:B72,\"Mercado Livre\",'🛒 ML iFood'!F4:F72,\"delivered\")"
sync["G36"] = "ML iFood ✅"
sync["B37"] = "iFood — pedidos"
sync["C37"] = "=SUMIFS('🛒 ML iFood'!D4:D72,'🛒 ML iFood'!B4:B72,\"iFood\")"
sync["G37"] = "ML iFood ✅"

# ------------------------------------------------------- FIX 4: Subscriptions
subs = wb["🔄 Subscriptions"]
# Trailing 6-month averages derived from actual charges in 💳 Transactions.
MANUS_AVG = round(2510.56 / 6, 2)   # 418.43  (8 charges over Jan-Jun)
DC_AVG    = round(272.21 / 6, 2)    # 45.37   (single R$272.21 credit purchase)
# Row 9 = Manus (automacao.giovannini) -> attribute all observed Manus spend here.
subs["I9"] = MANUS_AVG
subs["I9"].comment = Comment(
    "Estimativa: média móvel 6m das cobranças reais de Manus em Transactions "
    "(R$2.510,56 / 6). Serviço por créditos, sem preço fixo.", "fix_dataentry_top3")
# Row 8 = Manus (cadastro.giovannini) -> 0 to avoid double counting.
subs["I8"] = 0
subs["I8"].comment = Comment(
    "Sem cobranças separadas identificáveis; todo o gasto Manus atribuído à "
    "linha 9 para evitar dupla contagem.", "fix_dataentry_top3")
# Row 11 = Desktop Commander.
subs["I11"] = DC_AVG
subs["I11"].comment = Comment(
    "Estimativa: média móvel 6m (uma compra de crédito de R$272,21 / 6).",
    "fix_dataentry_top3")

wb.save(F)
print("saved.")

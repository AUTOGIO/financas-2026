#!/usr/bin/env python3
"""
Round 2 — the four lower-impact findings in financas2026-DataEntry.xlsx.

  #5  Data lineage — 💳 Transactions is a curated AI subset of 💳 MP Faturas, and
      ~R$8,744 of Mercado Livre lines sit in BOTH 💳 MP Faturas and 🛒 ML iFood.
      Nothing said so; a cross-sheet "grand total" double counts. Documented now.

  #6  🌉 Cash Bridge never tied out. PIX+Câmbio+IOF = R$42,092.58 vs confirmed
      final balance R$42,112.59. Add a live reconciliation + residual (R$20.01)
      and clarify the R$122K "documented gap" is a README narrative, not math here.

  #7  🛒 ML iFood said "13 pedidos" but only 9 have a value; cancelled/failed rows
      are interleaved with delivered. Add a status-aware totals block and make the
      header count honest ("13 pedidos, 9 com valor").

  #8  Hardcoded header totals -> live formulas on 💳 MP Faturas and 🛒 ML iFood, plus
      live total rows at the bottom of each sheet so edits self-update.
"""
import openpyxl
from openpyxl.comments import Comment

P = "/Users/eduardofgiovannini/Documents/financas-2026/financas2026-DataEntry.xlsx"
wb = openpyxl.load_workbook(P)

# ------------------------------------------------- #8 + #7: MP Faturas headers/totals
mp = wb["💳 MP Faturas"]
mp["A2"] = '="Total: R$"&TEXT(SUM(D4:D149),"#,##0.00")'
mp["C2"] = '=COUNT(D4:D149)&" transações"'
# live total block at the bottom
mp["C151"] = "TOTAL FATURA (live)"
mp["D151"] = "=SUM(D4:D149)"
mp["C152"] = "Nº transações"
mp["D152"] = "=COUNT(D4:D149)"

# ------------------------------------------------- #8 + #7: ML iFood headers/totals
ml = wb["🛒 ML iFood"]
ml["A2"] = '="ML Entregues: R$"&TEXT(SUMIFS(D4:D72,B4:B72,"Mercado Livre",F4:F72,"delivered"),"#,##0.00")'
ml["C2"] = ('="iFood: R$"&TEXT(SUMIFS(D4:D72,B4:B72,"iFood"),"#,##0.00")&" ("'
            '&COUNTIF(B4:B72,"iFood")&" pedidos, "&COUNTIFS(B4:B72,"iFood",D4:D72,">0")&" com valor)"')
ml["E2"] = ('="Total Combinado: R$"&TEXT(SUMIFS(D4:D72,B4:B72,"Mercado Livre",F4:F72,"delivered")'
            '+SUMIFS(D4:D72,B4:B72,"iFood"),"#,##0.00")')
# status-aware totals block (#7): delivered counted, cancelled/failed shown separately
ml["C74"] = "ML entregues"
ml["D74"] = '=SUMIFS(D4:D72,B4:B72,"Mercado Livre",F4:F72,"delivered")'
ml["C75"] = "ML cancelado/falhou (EXCLUÍDO do total)"
ml["D75"] = ('=SUMIFS(D4:D72,B4:B72,"Mercado Livre",F4:F72,"cancelled")'
             '+SUMIFS(D4:D72,B4:B72,"Mercado Livre",F4:F72,"failed")')
ml["C76"] = "iFood (só pedidos com valor)"
ml["D76"] = '=SUMIFS(D4:D72,B4:B72,"iFood")'
ml["C77"] = "TOTAL COMBINADO (entregue)"
ml["D77"] = "=D74+D76"

# ------------------------------------------------- #6: Cash Bridge reconciliation
cb = wb["🌉 Cash Bridge"]
cb["B40"] = "SOMA MOVIMENTOS (PIX+Câmbio+IOF)"
cb["E40"] = "=E36+F37+G38"
cb["B41"] = "RESÍDUO vs Saldo Final (F3) — deve ~0"
cb["E41"] = "=E40-F3"
cb["B42"] = "ⓘ Movimentos explicam o saldo até R$20,01. C3 (R$122K) é narrativa do README, não reconciliada aqui."

# ------------------------------------------------- #5: data lineage documentation
tx = wb["💳 Transactions"]
tx["B2"] = ("Source: subscription_budget_dashboard_v3_deduped.xlsx · "
            "SUBCONJUNTO de 💳 MP Faturas (só cobranças AI/assinatura) — NÃO somar junto com MP Faturas")
mp["A1"].comment = Comment(
    "FONTE DE VERDADE do gasto no cartão MP (146 tx). 💳 Transactions é um "
    "subconjunto curado disto; ~R$8.744 em linhas MERCADOLIVRE* também aparecem "
    "itemizadas em 🛒 ML iFood. Não somar as abas entre si.", "fix_round2")
ml["A1"].comment = Comment(
    "As compras Mercado Livre pagas no cartão MP (~R$8.744, 9 linhas) também "
    "constam em 💳 MP Faturas. Esta aba itemiza; não somar junto com MP Faturas.",
    "fix_round2")

wb.save(P)
print("saved.")

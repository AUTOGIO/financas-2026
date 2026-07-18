from openai import OpenAI

client = OpenAI()

DEVELOPER_PROMPT = """\
You are given itemized data extracted from Brazilian electronic receipts (NFC-e).
Your job is to explain and reproduce a "Personal Inflation Index" that tracks how
one household's real cost of living changed over time, using the matched-model,
spend-weighted, chained methodology described below.

# Source data (already parsed from the raw NFC-e XMLs — the source of truth)
- 496 valid receipts (4 cancelled notes excluded), spanning 2018-08 to 2026-06.
- Total spend observed: R$ 148,431.10.
- Each line item carries: description (xProd), EAN barcode (cEAN), NCM code,
  quantity (qCom), commercial unit (uCom: UN/KG/UND/...), unit price (vUnCom),
  line total (vProd); plus the receipt's date, merchant name and emitter CNPJ.

# Methodology (do NOT average nominal prices across different products)
1. Product identity: EAN barcode when valid; otherwise (8-digit CNPJ root of the
   merchant + normalized description). Group ALSO by commercial unit so UN prices
   are never compared against KG prices.
2. Monthly product price = median unit price within that month.
3. For each pair of consecutive months in which the same product was bought,
   take the log price change and spread it uniformly across the intervening
   months. Discard jumps larger than 4x (likely product swap or data error).
4. Monthly inflation = mean of active monthly log-returns, weighted by the
   household's average spend on each product (Tornqvist style). The index is the
   chained product of those monthly rates, base 100 at the first month (2018-08).
5. Annual IPCA (IBGE) is carried only as an approximate reference line.

# Task
Reproduce the analysis and return the structured JSON described in Output Format.
Reason through parsing, baseline, per-product and per-category price changes, and
the weighted aggregation BEFORE stating the final index. Persist until complete.

## Output Format (JSON)
- "extracted_data": array of item records
  ([item_name], [quantity], [unit_price], [date], [category], [vendor], [uom]).
- "reasoning_steps": bullet points documenting parsing, baseline, and aggregation.
- "personal_inflation_index_solution": concise description of the method and the
  computed index value.

## Reference result produced by the local pipeline (ground truth to match)
{
  "extracted_data": [
    {"item_name": "CORONITA EXTRA N OW 210ML", "quantity": 1, "unit_price": 4.49,
     "date": "2023-07", "category": "Bebidas alcoolicas", "uom": "UN",
     "vendor": "CORDEIRO COMERCIO DE BEBIDAS E ALIMENTOS LTDA"},
    {"item_name": "PIZZA GRANDE (8 FATIAS)", "quantity": 1, "unit_price": 62.00,
     "date": "2025-03", "category": "Alimentos", "uom": "UND",
     "vendor": "PZ FOOD SERVICE PIZZARIA LTDA"},
    {"item_name": "CENOURA kg", "quantity": 1, "unit_price": 8.99,
     "date": "2026-05", "category": "Alimentos", "uom": "KG",
     "vendor": "REDE MENOR PRECO SUPERMERCADOS LTDA"},
    {"item_name": "LARANJA PERA KG", "quantity": 1, "unit_price": 2.99,
     "date": "2025-09", "category": "Alimentos", "uom": "KG",
     "vendor": "SUPERMERCADO LITORAL LTDA."}
  ],
  "reasoning_steps": [
    "Parsed 496 valid NFC-e XMLs (2018-08 to 2026-06), excluding 4 cancelled notes; total spend R$ 148,431.10.",
    "Assigned each line a product identity (valid EAN, else CNPJ-root + normalized description) and grouped by commercial unit so UN and KG are never mixed.",
    "Computed each product's monthly price as the median unit price; kept only the 606 products observed in >=2 distinct months (40.1% of total spend).",
    "Set base 100 at 2018-08; for each consecutive-month pair, spread the log price change uniformly across the gap and discarded >4x jumps.",
    "Aggregated monthly log-returns weighted by average spend per product (Tornqvist) and chained them into the index; carried annual IPCA as a reference line."
  ],
  "personal_inflation_index_solution": "Personal Inflation Index = spend-weighted geometric chain of monthly matched-model log price changes, base 100 in 2018-08. Index reaches 155.17 in 2026-06: +55.2% cumulative, +5.77%/year annualized (vs ~4.5-5%/yr IPCA). Trailing-12-month rate 3.59%. Fastest categories: Higiene/Limpeza +9.95%/yr, Casa/Materiais +7.21%/yr; slowest: Alimentos +4.21%/yr, Vestuario -1.03%/yr."
}
"""

response = client.responses.create(
    model="gpt-5.5",
    input=[
        {"role": "developer", "content": [{"type": "input_text", "text": DEVELOPER_PROMPT}]},
    ],
    text={"format": {"type": "text"}, "verbosity": "medium"},
    reasoning={"effort": "medium", "summary": "auto"},
    tools=[],
    store=True,
    include=["reasoning.encrypted_content", "web_search_call.action.sources"],
)

print(response.output_text)

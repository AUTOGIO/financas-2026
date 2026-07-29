# Excel Interactive Dashboard — Open-Source Tools Guide
> **Context:** Paste this into Claude Code as a knowledge base / system prompt reference.
> **Author context:** [REDACTED] | [REDACTED-ORG] | Python · macOS · Financial dashboards

---

## 1. TOOL OVERVIEW (Quick Reference)

| # | Tool | License | Primary Language | Excel Input | Best Use Case |
|---|------|---------|-----------------|-------------|---------------|
| 1 | Plotly Dash | MIT | Python | pandas/openpyxl | Full financial web apps |
| 2 | Streamlit | Apache 2.0 | Python | pandas/openpyxl | Rapid data prototypes |
| 3 | xlwings | BSD | Python + Excel | Native Excel bridge | Live Excel ↔ Python sync |
| 4 | Panel (HoloViz) | BSD | Python | pandas + PyData | Multi-page complex apps |
| 5 | Apache Superset | Apache 2.0 | Python/TypeScript | UI CSV/Excel upload | Enterprise BI platform |
| 6 | Metabase | AGPL | Java/JavaScript | CSV/Excel import | No-code team dashboards |
| 7 | Redash | BSD | Python/React | SQL + CSV/Excel | SQL-first analytics |
| 8 | Evidence | MIT | SQL + Markdown | DuckDB/CSV/Excel | BI-as-code static sites |
| 9 | openpyxl | MIT | Python | Native Excel r/w | Automate Excel output |
| 10 | Grafana | AGPL | Go/TypeScript | CSV/Infinity plugin | Real-time monitoring |

---

## 2. TOOL DEEP DIVES

---

### 2.1 Plotly Dash ⭐ RECOMMENDED

**Repo:** https://github.com/plotly/dash  
**Docs:** https://dash.plotly.com  
**Stars:** 43K+  
**License:** MIT

#### What it does
Open-source Python framework to build reactive, web-based data apps entirely in Python — no HTML/CSS/JavaScript required. Ideal for financial dashboards with sliders, dropdowns, date pickers, and live charts.

#### Excel Integration
```python
import pandas as pd
import dash
from dash import dcc, html, dash_table, Input, Output
import plotly.express as px

app = dash.Dash(__name__)

# Load Excel
df = pd.read_excel("data.xlsx", sheet_name="Sales")

app.layout = html.Div([
    dcc.Dropdown(id='region', options=df['Region'].unique(), value='All'),
    dcc.Graph(id='chart'),
    dash_table.DataTable(data=df.to_dict('records'), page_size=20)
])

@app.callback(Output('chart', 'figure'), Input('region', 'value'))
def update(region):
    filtered = df if region == 'All' else df[df['Region'] == region]
    return px.bar(filtered, x='Month', y='Revenue', title=f'Revenue — {region}')

if __name__ == '__main__':
    app.run(debug=True)
```

#### Key Components
- `dcc.Graph` — Plotly charts (bar, line, scatter, candlestick, heatmap)
- `dash_table.DataTable` — Excel-like interactive tables with sorting/filtering
- `dcc.Upload` — Drag-and-drop Excel file uploader in browser
- `dcc.Interval` — Auto-refresh for live data
- `dash_ag_grid` — Advanced AG Grid integration

#### Financial Dashboard Patterns
```python
# Upload Excel dynamically
from dash import dcc
import base64, io

dcc.Upload(id='upload', children='Drop Excel Here',
           accept='.xlsx,.xls')

@app.callback(Output('store', 'data'), Input('upload', 'contents'))
def parse(contents):
    _, content_string = contents.split(',')
    decoded = base64.b64decode(content_string)
    df = pd.read_excel(io.BytesIO(decoded))
    return df.to_dict('records')
```

#### Install
```bash
pip install dash pandas openpyxl plotly dash-ag-grid
```

---

### 2.2 Streamlit

**Repo:** https://github.com/streamlit/streamlit  
**Docs:** https://docs.streamlit.io  
**License:** Apache 2.0

#### What it does
Fastest path from Python script to shareable web app. Re-runs script top-to-bottom on every widget interaction. Best for internal tools, ML dashboards, quick prototypes.

#### Excel Integration
```python
import streamlit as st
import pandas as pd
import plotly.express as px

st.title("Financial Dashboard")

# Upload or load fixed file
uploaded = st.file_uploader("Upload Excel", type=["xlsx", "xls"])
df = pd.read_excel(uploaded) if uploaded else pd.read_excel("default.xlsx")

# Sidebar filters
sheet_col = st.sidebar.selectbox("Group by", df.columns)
selected = st.sidebar.multiselect("Filter", df[sheet_col].unique(), default=df[sheet_col].unique())
filtered = df[df[sheet_col].isin(selected)]

# Charts
col1, col2 = st.columns(2)
col1.plotly_chart(px.bar(filtered, x=sheet_col, y=filtered.columns[-1]))
col2.plotly_chart(px.pie(filtered, names=sheet_col))

# Table
st.dataframe(filtered, use_container_width=True)
```

#### Key Components
- `st.file_uploader` — Excel upload
- `st.dataframe` / `st.data_editor` — Interactive tables
- `st.plotly_chart`, `st.bar_chart` — Charts
- `st.columns`, `st.tabs` — Layout
- `st.cache_data` — Cache Excel reads for performance

#### Install
```bash
pip install streamlit pandas openpyxl plotly
streamlit run app.py
```

---

### 2.3 xlwings

**Repo:** https://github.com/xlwings/xlwings  
**Docs:** https://docs.xlwings.org  
**License:** BSD (core free; PRO paid)  
**macOS:** ✅ Fully supported

#### What it does
Python library that controls live Excel from Python (and vice versa). Replaces VBA with Python. Can write DataFrames into cells, insert charts, trigger Python from Excel buttons, and run as a web API.

#### Core Usage
```python
import xlwings as xw
import pandas as pd

# Open existing workbook
wb = xw.Book("Dashboard.xlsx")
ws = wb.sheets["Data"]

# Read range into DataFrame
df = ws["A1"].options(pd.DataFrame, expand='table').value

# Write processed data back
result = df.groupby("Region")["Revenue"].sum().reset_index()
wb.sheets["Summary"]["A1"].value = result

# Insert a chart
chart = wb.sheets["Summary"].charts.add()
chart.set_source_data(wb.sheets["Summary"]["A1"].expand())
chart.chart_type = "bar_clustered"

wb.save()
wb.close()
```

#### UDF (User-Defined Functions in Excel cells)
```python
import xlwings as xw

@xw.func
def moving_avg(data, window):
    import pandas as pd
    s = pd.Series(data)
    return s.rolling(window).mean().tolist()
```

#### xlwings Lite (Free Add-in)
- Available in the Excel Add-in Store
- No Python installation required for end users
- Runs Python in browser/cloud

#### Install (macOS)
```bash
pip install xlwings
xlwings addin install   # installs Excel add-in
```

---

### 2.4 Panel (HoloViz)

**Repo:** https://github.com/holoviz/panel  
**Docs:** https://panel.holoviz.org  
**License:** BSD

#### What it does
Most flexible Python dashboarding library. Wraps Bokeh, Matplotlib, Plotly, Altair, and Vega. Supports multi-page apps, reactive programming, and complex widget trees. Can deploy as standalone server or embed in Jupyter.

#### Excel Dashboard Example
```python
import panel as pn
import pandas as pd
import hvplot.pandas  # noqa

pn.extension('plotly')

df = pd.read_excel("financials.xlsx")

select = pn.widgets.Select(name='Column', options=list(df.select_dtypes('number').columns))
date_range = pn.widgets.DateRangeSlider(name='Date', start=df['Date'].min(), end=df['Date'].max())

@pn.depends(select, date_range)
def plot(col, dates):
    mask = (df['Date'] >= dates[0]) & (df['Date'] <= dates[1])
    return df[mask].hvplot.line(x='Date', y=col, responsive=True)

dashboard = pn.template.FastListTemplate(
    title="Financial Dashboard",
    sidebar=[select, date_range],
    main=[plot]
)
dashboard.servable()
```

#### Install
```bash
pip install panel hvplot pandas openpyxl bokeh
panel serve app.py --autoreload
```

---

### 2.5 Apache Superset

**Repo:** https://github.com/apache/superset  
**Docs:** https://superset.apache.org  
**License:** Apache 2.0

#### What it does
Enterprise-grade BI platform. Self-hosted. Role-based access control. Connects to 40+ databases. Supports Excel/CSV upload via UI. Drag-and-drop chart builder.

#### Quick Docker Start
```bash
git clone https://github.com/apache/superset
cd superset
docker compose -f docker-compose-image-tag.yml up
# Access at http://localhost:8088
# Default: admin / admin
```

#### Excel Import Steps
1. Enable `ALLOW_ADHOC_SUBQUERY` and `UPLOAD_FOLDER` in `superset_config.py`
2. Go to **Data → Upload a CSV/Excel**
3. Select your `.xlsx` file, map columns
4. Build charts from the new dataset
5. Assemble charts into a Dashboard

#### Key Config (superset_config.py)
```python
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_NATIVE_FILTERS": True,
}
UPLOAD_EXTENSIONS = ["xlsx", "xls", "csv", "parquet"]
```

---

### 2.6 Metabase

**Repo:** https://github.com/metabase/metabase  
**Docs:** https://www.metabase.com/docs  
**License:** AGPL (Community Edition free)

#### What it does
No-code BI tool for teams. Point-and-click query builder, automatic chart suggestions, scheduled email reports. Best for sharing dashboards with non-technical stakeholders.

#### Quick Start
```bash
# Docker
docker run -d -p 3000:3000 --name metabase metabase/metabase
# Access at http://localhost:3000
```

#### Excel Workflow
1. Import Excel → local SQLite or PostgreSQL using `pandas + sqlalchemy`
2. Connect Metabase to the database
3. Build dashboards visually — no SQL required

```python
# Load Excel → PostgreSQL for Metabase
import pandas as pd
from sqlalchemy import create_engine

df = pd.read_excel("data.xlsx")
engine = create_engine("postgresql://user:pass@localhost/mydb")
df.to_sql("sales", engine, if_exists="replace", index=False)
```

---

### 2.7 Redash

**Repo:** https://github.com/getredash/redash  
**Docs:** https://redash.io/help  
**License:** BSD

#### What it does
SQL-first analytics and dashboard tool. Connect to Postgres, MySQL, BigQuery, Snowflake, MongoDB, and more. Write SQL → build charts → assemble dashboards. Supports CSV/Excel as flat-file data sources.

#### Quick Start
```bash
git clone https://github.com/getredash/redash
cd redash
docker compose up
# Access at http://localhost
```

---

### 2.8 Evidence (BI as Code)

**Repo:** https://github.com/evidence-dev/evidence  
**Docs:** https://docs.evidence.dev  
**License:** MIT

#### What it does
Write SQL + Markdown → generates a fast, static interactive website powered by DuckDB WASM. Version-controlled with Git. Supports CSV/Excel as data sources via DuckDB.

#### Excel → Evidence Workflow
```bash
npx degit evidence-dev/template my-dashboard
cd my-dashboard
npm install
npm run dev
```

```sql
-- pages/index.md
---
title: Sales Dashboard
---

```sql orders
SELECT * FROM read_excel('data/sales.xlsx')
```

<BarChart data={orders} x=Month y=Revenue />
<DataTable data={orders} />
```

#### Key Advantage
Output is a **static website** — deploy to Netlify/Vercel/S3 with no backend.

---

### 2.9 openpyxl

**Repo:** https://github.com/theorchard/openpyxl  
**Docs:** https://openpyxl.readthedocs.io  
**License:** MIT

#### What it does
Pure Python library to read/write `.xlsx` files. Create charts, apply conditional formatting, add formulas, and build styled Excel dashboards programmatically.

#### Dashboard Generation
```python
from openpyxl import Workbook
from openpyxl.chart import BarChart, Reference
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.formatting.rule import ColorScaleRule

wb = Workbook()
ws = wb.active
ws.title = "Dashboard"

# Write data
headers = ["Month", "Revenue", "Expenses", "Profit"]
data = [
    ["Jan", 120000, 80000, 40000],
    ["Feb", 135000, 85000, 50000],
    ["Mar", 150000, 90000, 60000],
]
ws.append(headers)
for row in data:
    ws.append(row)

# Style header
for cell in ws[1]:
    cell.font = Font(bold=True, color="FFFFFF")
    cell.fill = PatternFill("solid", fgColor="1F4E79")
    cell.alignment = Alignment(horizontal="center")

# Add Bar Chart
chart = BarChart()
chart.title = "Monthly Revenue vs Expenses"
chart.y_axis.title = "Amount (USD)"
data_ref = Reference(ws, min_col=2, max_col=3, min_row=1, max_row=4)
cats = Reference(ws, min_col=1, min_row=2, max_row=4)
chart.add_data(data_ref, titles_from_data=True)
chart.set_categories(cats)
ws.add_chart(chart, "F2")

# Conditional formatting on Profit column
ws.conditional_formatting.add(
    "D2:D4",
    ColorScaleRule(start_type='min', start_color='FF0000',
                   end_type='max', end_color='00FF00')
)

wb.save("dashboard_output.xlsx")
```

---

### 2.10 Grafana

**Repo:** https://github.com/grafana/grafana  
**Docs:** https://grafana.com/docs  
**License:** AGPL

#### What it does
Industry-standard real-time monitoring and observability dashboards. Connects to 80+ data sources. For Excel/CSV use the **Infinity** or **CSV** plugin.

#### Excel/CSV via Infinity Plugin
```bash
# Install plugin
grafana cli plugins install yesoreyeram-infinity-datasource
# Restart Grafana
```

Configure datasource URL to point to a CSV export from Excel, or use a local file path. Best for operational/metrics dashboards rather than financial analysis.

---

## 3. RECOMMENDED STACK BY USE CASE

| Use Case | Recommended Stack |
|----------|------------------|
| Financial web dashboards (internal) | **Plotly Dash** + openpyxl |
| Quick internal tools / prototyping | **Streamlit** |
| Keep dashboards inside Excel | **xlwings** |
| Team BI with non-technical users | **Metabase** or **Superset** |
| Analyst SQL → charts workflow | **Redash** |
| Git-versioned, deployable reports | **Evidence** |
| Real-time metrics/monitoring | **Grafana** |
| Automated Excel report generation | **openpyxl** + xlsxwriter |

---

## 4. FULL STACK RECIPE: Dash + xlwings + pandas

This is the recommended combination for **[REDACTED-ORG]** — Python financial data pipeline with live Excel sync and web dashboard.

```
project/
├── app.py              ← Dash web dashboard
├── data_pipeline.py    ← pandas data processing
├── excel_sync.py       ← xlwings Excel sync
├── data/
│   └── portfolio.xlsx  ← Source data
└── requirements.txt
```

### requirements.txt
```
dash>=2.17
plotly>=5.22
pandas>=2.2
openpyxl>=3.1
xlwings>=0.31
dash-ag-grid>=31.0
python-dotenv
```

### data_pipeline.py
```python
import pandas as pd

def load_portfolio(path="data/portfolio.xlsx"):
    df = pd.read_excel(path, sheet_name="Holdings")
    df['PnL'] = df['CurrentValue'] - df['CostBasis']
    df['PnL_pct'] = df['PnL'] / df['CostBasis'] * 100
    return df

def get_summary(df):
    return {
        "total_value": df['CurrentValue'].sum(),
        "total_pnl": df['PnL'].sum(),
        "positions": len(df),
    }
```

### app.py (Dash dashboard)
```python
import dash
from dash import dcc, html, dash_table, Input, Output, callback
import plotly.express as px
import plotly.graph_objects as go
from data_pipeline import load_portfolio, get_summary

app = dash.Dash(__name__, title="GMC Portfolio Dashboard")

df = load_portfolio()
summary = get_summary(df)

app.layout = html.Div([
    html.H1("[REDACTED-ORG] — Portfolio Dashboard"),

    # KPI Cards
    html.Div([
        html.Div([html.H3("Total Value"), html.H2(f"${summary['total_value']:,.2f}")]),
        html.Div([html.H3("Total P&L"), html.H2(f"${summary['total_pnl']:,.2f}")]),
        html.Div([html.H3("Positions"), html.H2(summary['positions'])]),
    ], style={"display": "flex", "gap": "2rem"}),

    # Filters
    dcc.Dropdown(id='sector', options=df['Sector'].unique() if 'Sector' in df.columns else [],
                 placeholder="Filter by Sector", multi=True),

    # Charts
    html.Div([
        dcc.Graph(id='pnl-chart'),
        dcc.Graph(id='allocation-chart'),
    ], style={"display": "grid", "gridTemplateColumns": "1fr 1fr"}),

    # Table
    dash_table.DataTable(
        id='table',
        columns=[{"name": c, "id": c} for c in df.columns],
        data=df.to_dict('records'),
        sort_action='native',
        filter_action='native',
        page_size=15,
        style_data_conditional=[
            {"if": {"filter_query": "{PnL} < 0"}, "color": "red"},
            {"if": {"filter_query": "{PnL} > 0"}, "color": "green"},
        ]
    ),

    # Auto-refresh
    dcc.Interval(id='interval', interval=60_000),  # refresh every 60s
])

@callback(Output('pnl-chart', 'figure'), Output('allocation-chart', 'figure'),
          Input('sector', 'value'), Input('interval', 'n_intervals'))
def update(sectors, _):
    filtered = df if not sectors else df[df['Sector'].isin(sectors)]
    fig1 = px.bar(filtered.sort_values('PnL'), x='Ticker', y='PnL',
                  color='PnL', color_continuous_scale='RdYlGn', title='P&L by Position')
    fig2 = px.pie(filtered, names='Sector', values='CurrentValue', title='Allocation by Sector')
    return fig1, fig2

if __name__ == '__main__':
    app.run(debug=True, port=8050)
```

### excel_sync.py (xlwings sync)
```python
import xlwings as xw
import pandas as pd
from data_pipeline import load_portfolio

def push_to_excel(path="data/portfolio.xlsx"):
    df = load_portfolio(path)
    wb = xw.Book(path)
    ws = wb.sheets.add("Dashboard_Python", after=wb.sheets[-1])

    ws["A1"].value = "Auto-generated by Python"
    ws["A3"].options(pd.DataFrame, index=False).value = df

    # Color negative PnL rows red
    for i, val in enumerate(df['PnL'], start=4):
        if val < 0:
            ws[f"A{i}"].expand('right').color = (255, 200, 200)

    wb.save()
    print("Excel dashboard updated.")

if __name__ == '__main__':
    push_to_excel()
```

---

## 5. PROMPTS FOR CLAUDE CODE

Use these prompts directly in Claude Code sessions:

### Build a Dash Dashboard from Excel
```
I have an Excel file at data/sales.xlsx with columns: Date, Region, Product, Revenue, Units.
Build a Plotly Dash app with:
- KPI cards at the top (total revenue, total units, avg per region)
- Date range picker filter
- Bar chart: Revenue by Region
- Line chart: Revenue over time
- Filterable DataTable with all records
- Auto-refresh every 5 minutes
Use dash-ag-grid for the table. Style with dark theme.
```

### Add Excel Upload to Existing Dash App
```
Add a dcc.Upload component to my Dash app that:
- Accepts .xlsx and .xls files
- Parses the uploaded file with pandas
- Updates all charts and the DataTable reactively
- Shows a loading spinner during processing
- Handles errors gracefully with a user-friendly message
```

### Generate Excel Report with openpyxl
```
Write a Python script using openpyxl that:
- Reads data from a pandas DataFrame
- Creates a styled Excel workbook with:
  - Frozen header row with blue background and white bold text
  - Alternating row colors
  - A BarChart and LineChart on a separate "Charts" sheet
  - Conditional formatting: green for positive values, red for negative
  - Auto-width columns
- Saves as "monthly_report.xlsx"
```

### xlwings UDF Setup
```
Create an xlwings UDF file for Excel that provides:
- A =MOVING_AVG(range, window) function
- A =VOLATILITY(returns_range, annualize) function
- A =SHARPE(returns_range, risk_free_rate) function
Include proper type hints and error handling.
Register with xlwings on macOS.
```

### Streamlit Multi-sheet Excel Dashboard
```
Build a Streamlit app that:
- Lets users upload a multi-sheet Excel file
- Shows a tab for each sheet in the workbook
- Auto-detects numeric columns for charting
- Provides a "Summary" tab with aggregates across all sheets
- Allows downloading filtered data back as Excel
```

---

## 6. COMMON PATTERNS & TIPS

### Read Excel with multiple sheets
```python
# All sheets
sheets = pd.read_excel("data.xlsx", sheet_name=None)  # dict of DataFrames

# Specific sheets
df1 = pd.read_excel("data.xlsx", sheet_name="Sales")
df2 = pd.read_excel("data.xlsx", sheet_name=0)  # by index
```

### Write back to Excel preserving formatting
```python
# Use openpyxl engine to avoid overwriting styles
from openpyxl import load_workbook

wb = load_workbook("template.xlsx")
ws = wb["Sheet1"]
ws["B2"] = 42  # write single cell
wb.save("output.xlsx")
```

### Cache Excel reads in Dash
```python
from functools import lru_cache

@lru_cache(maxsize=1)
def get_data():
    return pd.read_excel("data.xlsx")
```

### Cache in Streamlit
```python
@st.cache_data(ttl=300)  # 5-minute cache
def load_data(path):
    return pd.read_excel(path)
```

### Convert Excel dates (common gotcha)
```python
df['Date'] = pd.to_datetime(df['Date'])
df['Date'] = df['Date'].dt.strftime('%Y-%m-%d')  # to string if needed
```

### Handle merged cells (xlwings)
```python
ws = wb.sheets["Sheet1"]
ws.range("A1:D1").merge()
ws.range("A1").value = "Title"
```

---

## 7. RESOURCES

| Resource | URL |
|----------|-----|
| Plotly Dash Docs | https://dash.plotly.com |
| Dash AG Grid | https://dash.plotly.com/dash-ag-grid |
| Streamlit Docs | https://docs.streamlit.io |
| xlwings Docs | https://docs.xlwings.org |
| Panel Docs | https://panel.holoviz.org |
| Apache Superset | https://superset.apache.org |
| Metabase Docs | https://www.metabase.com/docs |
| Redash Docs | https://redash.io/help |
| Evidence Docs | https://docs.evidence.dev |
| openpyxl Docs | https://openpyxl.readthedocs.io |
| Grafana Docs | https://grafana.com/docs |

---

*Generated: July 2026 | [REDACTED-ORG]*

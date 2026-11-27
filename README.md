# Video Game Sales Analysis (SQL)

An end-to-end SQL project analysing over 16,000 video games released between 1980 and 2020: which genres, platforms and publishers sell the most, how tastes differ between regions, and how the market has changed over time.

**Skills shown:** database design, data cleaning in SQL, JOINs, GROUP BY and aggregation, CASE, subqueries, CTEs (`WITH`), and window functions (`RANK`, `ROW_NUMBER`, `LAG`, running totals).

**Tools:** SQL (SQLite), Python (standard library only, to load the data and run the queries).

---

## The questions

| # | Business question | SQL techniques |
|---|---|---|
| 1 | How big is the dataset, and how complete is it? | Aggregates, `CASE`, subqueries |
| 2 | What are the 10 best-selling games of all time? | `GROUP BY`, `ORDER BY`, `LIMIT` |
| 3 | Which genres sell the most, overall and per game? | `JOIN`, `AVG`, percentage of total |
| 4 | Do players in different regions prefer different genres? | CTEs, `UNION ALL`, `RANK() OVER (PARTITION BY …)` |
| 5 | How do Sony, Nintendo, Microsoft and Sega compare? | `JOIN`, `COUNT(DISTINCT …)` |
| 6 | Which publishers sell the most, and what is their hit rate? | Conditional aggregation |
| 7 | How have yearly sales changed over time? | `LAG()`, running total with `SUM() OVER` |
| 8 | What is the best-selling game on each platform? | `ROW_NUMBER()` |
| 9 | Do a few blockbusters make most of the money? | `CASE` banding, share of total |
| 10 | Which genres are far more popular in Japan than in the West? | `CROSS JOIN`, comparing shares |

All queries are in [`sql/03_analysis.sql`](sql/03_analysis.sql), and their results are saved in [`outputs/`](outputs/).

---

## Database design

The raw data is one wide CSV. I split it into a normalised schema so each fact is stored once:

```
platforms (platform_id, platform_code, manufacturer)
genres    (genre_id, genre_name)
publishers(publisher_id, publisher_name)
games     (game_id, title, platform_id, genre_id, publisher_id, release_year)
sales     (game_id, na_sales, eu_sales, jp_sales, other_sales, global_sales)
```

`games` links to the three lookup tables, and `sales` has one row per game. Sales are in millions of units.

---

## Data cleaning

Done in SQL in [`sql/02_clean_and_load.sql`](sql/02_clean_and_load.sql):

- **Missing years:** stored as the text `N/A`, converted to `NULL` so they don't break year-based analysis.
- **Missing publishers:** `N/A` or blank, converted to `NULL`.
- **Extra spaces:** trimmed from all text fields.
- **Duplicate rows:** removed with `SELECT DISTINCT`.
- **Text to numbers:** years and sales cast from text to numeric types.
- **New field:** each platform mapped to its manufacturer with `CASE`.

---

## Key findings

<!-- After running the project, fill these in from the files in outputs/ -->

- **Top genre:** …
- **Regional differences:** …
- **Console makers:** …
- **Blockbusters vs long tail:** …
- **Peak year:** …

---

## How to run it

1. **Download the data.** Get `vgsales.csv` from the [Video Game Sales dataset on Kaggle](https://www.kaggle.com/datasets/gregorut/videogamesales) (free account needed) and put it in the `data/` folder.
2. **Run the project** (Python 3, no installs needed):
   ```
   python run_project.py
   ```
3. This builds `video_games.db`, runs every query, prints the results and saves each one as a CSV in `outputs/`.

You can also open `video_games.db` in a free tool such as [DB Browser for SQLite](https://sqlitebrowser.org/) and run the queries yourself.

---

## Project structure

```
video-game-sales-sql/
├── data/                  # vgsales.csv here
├── outputs/               # results (CSV)
├── sql/
│   ├── 01_schema.sql          # creates the tables
│   ├── 02_clean_and_load.sql  # cleans the raw data and loads the tables
│   └── 03_analysis.sql        # 10 business questions
├── run_project.py         # builds the database and runs everything
└── README.md
```

---

## Data source and limitations

Data from the Video Game Sales dataset on Kaggle, originally scraped from VGChartz. It only includes games that sold over 100,000 copies, and figures for the most recent years are incomplete, so recent years look lower than they really were. Sales are mostly physical retail units, so digital downloads are largely missing.

**Author:** Olivia Sassarini · [LinkedIn](http://www.linkedin.com/in/olivia-s-66a222395) · [GitHub](https://github.com/oliviasassarini)

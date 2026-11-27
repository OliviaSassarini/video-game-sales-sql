-- =============================================================
-- 02_clean_and_load.sql
-- Cleans the staging table (raw_sales) and loads the clean tables.
--
-- Data quality issues handled:
--   * Year stored as text, with 'N/A' for unknown years  -> NULL
--   * Publisher 'N/A' or blank                            -> NULL
--   * Stray spaces around text values                     -> TRIM
--   * Exact duplicate rows                                -> removed
-- =============================================================

-- 1. Clean copy of the raw data, one numbered row per game ------

DROP TABLE IF EXISTS clean_sales;

CREATE TABLE clean_sales AS
WITH deduplicated AS (
    SELECT DISTINCT
        TRIM(Name)                                    AS title,
        TRIM(Platform)                                AS platform_code,
        CASE
            WHEN TRIM(Year) GLOB '[0-9][0-9][0-9][0-9]'
                THEN CAST(TRIM(Year) AS INTEGER)
            ELSE NULL
        END                                           AS release_year,
        TRIM(Genre)                                   AS genre_name,
        NULLIF(NULLIF(TRIM(Publisher), 'N/A'), '')    AS publisher_name,
        CAST(NA_Sales     AS REAL)                    AS na_sales,
        CAST(EU_Sales     AS REAL)                    AS eu_sales,
        CAST(JP_Sales     AS REAL)                    AS jp_sales,
        CAST(Other_Sales  AS REAL)                    AS other_sales,
        CAST(Global_Sales AS REAL)                    AS global_sales
    FROM raw_sales
    WHERE TRIM(Name) <> ''
)
SELECT
    ROW_NUMBER() OVER (ORDER BY global_sales DESC, title) AS row_id,
    *
FROM deduplicated;

-- 2. Lookup tables -----------------------------------------------

INSERT INTO platforms (platform_code, manufacturer)
SELECT DISTINCT
    platform_code,
    CASE
        WHEN platform_code IN ('PS', 'PS2', 'PS3', 'PS4', 'PSP', 'PSV')            THEN 'Sony'
        WHEN platform_code IN ('NES', 'SNES', 'N64', 'GC', 'Wii', 'WiiU',
                               'GB', 'GBA', 'DS', '3DS')                           THEN 'Nintendo'
        WHEN platform_code IN ('XB', 'X360', 'XOne')                               THEN 'Microsoft'
        WHEN platform_code IN ('GEN', 'SCD', 'SAT', 'DC', 'GG')                    THEN 'Sega'
        WHEN platform_code = 'PC'                                                  THEN 'PC'
        ELSE 'Other'
    END
FROM clean_sales;

INSERT INTO genres (genre_name)
SELECT DISTINCT genre_name FROM clean_sales;

INSERT INTO publishers (publisher_name)
SELECT DISTINCT publisher_name FROM clean_sales
WHERE publisher_name IS NOT NULL;

-- 3. Games and sales (row_id becomes game_id) -------------------

INSERT INTO games (game_id, title, platform_id, genre_id, publisher_id, release_year)
SELECT
    c.row_id,
    c.title,
    p.platform_id,
    g.genre_id,
    pub.publisher_id,
    c.release_year
FROM clean_sales c
JOIN platforms       p   ON p.platform_code    = c.platform_code
JOIN genres          g   ON g.genre_name       = c.genre_name
LEFT JOIN publishers pub ON pub.publisher_name = c.publisher_name;

INSERT INTO sales (game_id, na_sales, eu_sales, jp_sales, other_sales, global_sales)
SELECT row_id, na_sales, eu_sales, jp_sales, other_sales, global_sales
FROM clean_sales;

DROP TABLE clean_sales;

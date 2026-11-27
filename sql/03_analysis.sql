-- =============================================================
-- 03_analysis.sql
-- Business questions about video game sales, answered in SQL.
-- Each query starts with a "-- name:" line so run_project.py can
-- run it and save the result to outputs/<name>.csv.
--
-- Sales figures are in millions of units.
-- =============================================================


-- name: 01_data_overview
-- Q1. How big is the dataset, and how complete is it?
SELECT
    COUNT(*)                                              AS total_games,
    COUNT(DISTINCT g.title)                               AS unique_titles,
    (SELECT COUNT(*) FROM platforms)                      AS platforms,
    (SELECT COUNT(*) FROM publishers)                     AS publishers,
    MIN(g.release_year)                                   AS first_year,
    MAX(g.release_year)                                   AS last_year,
    SUM(CASE WHEN g.release_year IS NULL THEN 1 ELSE 0 END) AS games_missing_year,
    SUM(CASE WHEN g.publisher_id IS NULL THEN 1 ELSE 0 END) AS games_missing_publisher,
    ROUND(SUM(s.global_sales), 1)                         AS total_global_sales_m
FROM games g
JOIN sales s ON s.game_id = g.game_id;


-- name: 02_top_10_games
-- Q2. What are the 10 best-selling games of all time (all platforms combined)?
SELECT
    g.title,
    COUNT(*)                          AS platforms_released_on,
    ROUND(SUM(s.global_sales), 2)     AS global_sales_m
FROM games g
JOIN sales s ON s.game_id = g.game_id
GROUP BY g.title
ORDER BY global_sales_m DESC
LIMIT 10;


-- name: 03_sales_by_genre
-- Q3. Which genres sell the most, and which sell the most per game?
SELECT
    ge.genre_name,
    COUNT(*)                                   AS games,
    ROUND(SUM(s.global_sales), 1)              AS global_sales_m,
    ROUND(AVG(s.global_sales), 2)              AS avg_sales_per_game_m,
    ROUND(100.0 * SUM(s.global_sales)
          / (SELECT SUM(global_sales) FROM sales), 1) AS pct_of_all_sales
FROM games g
JOIN genres ge ON ge.genre_id = g.genre_id
JOIN sales  s  ON s.game_id   = g.game_id
GROUP BY ge.genre_name
ORDER BY global_sales_m DESC;


-- name: 04_regional_genre_preferences
-- Q4. Do players in different regions prefer different genres?
--     Ranks each genre within each region using a window function.
WITH regional AS (
    SELECT ge.genre_name, 'North America' AS region, SUM(s.na_sales)    AS sales_m
    FROM games g JOIN genres ge ON ge.genre_id = g.genre_id JOIN sales s ON s.game_id = g.game_id
    GROUP BY ge.genre_name
    UNION ALL
    SELECT ge.genre_name, 'Europe',        SUM(s.eu_sales)
    FROM games g JOIN genres ge ON ge.genre_id = g.genre_id JOIN sales s ON s.game_id = g.game_id
    GROUP BY ge.genre_name
    UNION ALL
    SELECT ge.genre_name, 'Japan',         SUM(s.jp_sales)
    FROM games g JOIN genres ge ON ge.genre_id = g.genre_id JOIN sales s ON s.game_id = g.game_id
    GROUP BY ge.genre_name
),
ranked AS (
    SELECT
        region,
        genre_name,
        ROUND(sales_m, 1) AS sales_m,
        RANK() OVER (PARTITION BY region ORDER BY sales_m DESC) AS rank_in_region
    FROM regional
)
SELECT region, rank_in_region, genre_name, sales_m
FROM ranked
WHERE rank_in_region <= 3
ORDER BY region, rank_in_region;


-- name: 05_platform_manufacturers
-- Q5. How do the console makers compare?
SELECT
    p.manufacturer,
    COUNT(DISTINCT p.platform_code)    AS platforms,
    COUNT(*)                           AS games,
    ROUND(SUM(s.global_sales), 1)      AS global_sales_m,
    ROUND(AVG(s.global_sales), 2)      AS avg_sales_per_game_m
FROM games g
JOIN platforms p ON p.platform_id = g.platform_id
JOIN sales     s ON s.game_id     = g.game_id
GROUP BY p.manufacturer
ORDER BY global_sales_m DESC;


-- name: 06_top_publishers
-- Q6. Which publishers have sold the most, and how many hits (1m+ sales) do they have?
SELECT
    pub.publisher_name,
    COUNT(*)                                              AS games,
    SUM(CASE WHEN s.global_sales >= 1 THEN 1 ELSE 0 END)  AS million_sellers,
    ROUND(100.0 * SUM(CASE WHEN s.global_sales >= 1 THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                  AS hit_rate_pct,
    ROUND(SUM(s.global_sales), 1)                         AS global_sales_m
FROM games g
JOIN publishers pub ON pub.publisher_id = g.publisher_id
JOIN sales      s   ON s.game_id        = g.game_id
GROUP BY pub.publisher_name
ORDER BY global_sales_m DESC
LIMIT 10;


-- name: 07_sales_by_year
-- Q7. How have yearly sales changed over time? Includes year-on-year
--     change (LAG) and a running total.
WITH yearly AS (
    SELECT
        g.release_year,
        COUNT(*)              AS games_released,
        SUM(s.global_sales)   AS global_sales_m
    FROM games g
    JOIN sales s ON s.game_id = g.game_id
    WHERE g.release_year IS NOT NULL
    GROUP BY g.release_year
)
SELECT
    release_year,
    games_released,
    ROUND(global_sales_m, 1) AS global_sales_m,
    ROUND(global_sales_m - LAG(global_sales_m) OVER (ORDER BY release_year), 1)
                             AS change_vs_last_year_m,
    ROUND(SUM(global_sales_m) OVER (ORDER BY release_year), 1)
                             AS running_total_m
FROM yearly
ORDER BY release_year;


-- name: 08_best_game_per_platform
-- Q8. What is the single best-selling game on each platform?
WITH ranked AS (
    SELECT
        p.platform_code,
        g.title,
        s.global_sales,
        ROW_NUMBER() OVER (PARTITION BY p.platform_code
                           ORDER BY s.global_sales DESC) AS rn
    FROM games g
    JOIN platforms p ON p.platform_id = g.platform_id
    JOIN sales     s ON s.game_id     = g.game_id
)
SELECT platform_code, title, ROUND(global_sales, 2) AS global_sales_m
FROM ranked
WHERE rn = 1
ORDER BY global_sales_m DESC;


-- name: 09_hits_vs_long_tail
-- Q9. How concentrated are sales? Do a few blockbusters make most of the money?
--     Splits games into sales bands with CASE.
SELECT
    CASE
        WHEN s.global_sales >= 10  THEN '1. 10m+ (mega hit)'
        WHEN s.global_sales >= 1   THEN '2. 1m-10m (hit)'
        WHEN s.global_sales >= 0.1 THEN '3. 100k-1m'
        ELSE                            '4. under 100k'
    END                                              AS sales_band,
    COUNT(*)                                         AS games,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM sales), 1)           AS pct_of_games,
    ROUND(SUM(s.global_sales), 1)                    AS global_sales_m,
    ROUND(100.0 * SUM(s.global_sales)
          / (SELECT SUM(global_sales) FROM sales), 1)                   AS pct_of_sales
FROM sales s
GROUP BY sales_band
ORDER BY sales_band;


-- name: 10_japan_vs_west
-- Q10. Which genres are far more popular in Japan than in North America and Europe?
--      Compares each genre's share of Japanese sales with its share of Western sales.
WITH totals AS (
    SELECT SUM(jp_sales) AS jp_total, SUM(na_sales + eu_sales) AS west_total FROM sales
)
SELECT
    ge.genre_name,
    ROUND(100.0 * SUM(s.jp_sales) / t.jp_total, 1)                  AS pct_of_japan_sales,
    ROUND(100.0 * SUM(s.na_sales + s.eu_sales) / t.west_total, 1)   AS pct_of_western_sales,
    ROUND(100.0 * SUM(s.jp_sales) / t.jp_total
        - 100.0 * SUM(s.na_sales + s.eu_sales) / t.west_total, 1)   AS japan_minus_west_pts
FROM games g
JOIN genres ge ON ge.genre_id = g.genre_id
JOIN sales  s  ON s.game_id   = g.game_id
CROSS JOIN totals t
GROUP BY ge.genre_name, t.jp_total, t.west_total
ORDER BY japan_minus_west_pts DESC;

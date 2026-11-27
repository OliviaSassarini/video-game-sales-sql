-- =============================================================
-- 01_schema.sql
-- Builds a normalised database from the raw video game sales data.
--
-- Raw CSV  ->  staging table (raw_sales)  ->  clean tables:
--   platforms, genres, publishers, games, sales
--
-- Sales figures are in millions of units.
-- =============================================================

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS games;
DROP TABLE IF EXISTS platforms;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS publishers;

-- Lookup tables -------------------------------------------------

CREATE TABLE platforms (
    platform_id   INTEGER PRIMARY KEY,
    platform_code TEXT NOT NULL UNIQUE,   -- e.g. 'PS4', 'Wii', 'X360'
    manufacturer  TEXT NOT NULL           -- Sony, Nintendo, Microsoft, Sega, PC, Other
);

CREATE TABLE genres (
    genre_id   INTEGER PRIMARY KEY,
    genre_name TEXT NOT NULL UNIQUE
);

CREATE TABLE publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL UNIQUE
);

-- One row per game title released on a platform ------------------

CREATE TABLE games (
    game_id      INTEGER PRIMARY KEY,
    title        TEXT    NOT NULL,
    platform_id  INTEGER NOT NULL REFERENCES platforms(platform_id),
    genre_id     INTEGER NOT NULL REFERENCES genres(genre_id),
    publisher_id INTEGER          REFERENCES publishers(publisher_id),
    release_year INTEGER          -- NULL where the year is unknown
);

-- Sales by region for each game ----------------------------------

CREATE TABLE sales (
    game_id     INTEGER PRIMARY KEY REFERENCES games(game_id),
    na_sales    REAL NOT NULL,   -- North America
    eu_sales    REAL NOT NULL,   -- Europe
    jp_sales    REAL NOT NULL,   -- Japan
    other_sales REAL NOT NULL,   -- Rest of world
    global_sales REAL NOT NULL
);

CREATE INDEX idx_games_platform  ON games(platform_id);
CREATE INDEX idx_games_genre     ON games(genre_id);
CREATE INDEX idx_games_publisher ON games(publisher_id);
CREATE INDEX idx_games_year      ON games(release_year);

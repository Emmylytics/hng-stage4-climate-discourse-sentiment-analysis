-- =================================================================
-- CLIMATE CHANGE TWITTER DATASET: End-to-End SQL Analysis
-- Dataset: Climate Change Twitter Dataset (~15M tweets, 2006–2019)
-- Sections:
--   1. Data Understanding & Quality Assessment
--   2. Data Cleaning & Transformation
--   3. Descriptive Analytics
--   4. Diagnostic Analytics
-- =================================================================



-- =======================================================
-- SECTION 1: DATA UNDERSTANDING & QUALITY ASSESSMENT
-- =======================================================

-- -------------------------------------------------------
-- 1.1 Create the raw table with appropriate data types
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS climate_tweets_raw (
	created_at 			TIMESTAMPTZ,
	id 					BIGINT,
	lng 				DOUBLE PRECISION,
	lat 				DOUBLE PRECISION,
	topic 				TEXT,
	sentiment 			DOUBLE PRECISION,
	stance 				TEXT,
	gender 				TEXT,
	temperature_avg 	DOUBLE PRECISION,
	aggressiveness 		TEXT
);

-- Load data into the raw table
COPY climate_tweets_raw
FROM 'C:\Program Files\PostgreSQL\17\data\The Climate Change Twitter Dataset.csv'
DELIMITER ','
CSV HEADER;

-- ----------------------------------------------------
-- 1.2 Inspect Raw Data – Schema & Record Counts
-- ----------------------------------------------------

-- Check information_schema for metadata review
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'climate_tweets_raw';

-- Total row counts
SELECT 
	COUNT(*) AS total_rows 
FROM climate_tweets_raw;

-- Quick data preview(first 10 rows)
SELECT * 
FROM climate_tweets_raw 
LIMIT 10;

-- Date range of the dataset
SELECT
    MIN(created_at) AS earliest_tweet,
    MAX(created_at) AS latest_tweet,
    COUNT(*) AS total_rows
FROM climate_tweets_raw
WHERE created_at IS NOT NULL;

-- Check distinct values for categorical fields
SELECT 
	DISTINCT stance       
FROM climate_tweets_raw;
SELECT 
	DISTINCT gender       
FROM climate_tweets_raw;
SELECT 
	DISTINCT aggressiveness 
FROM climate_tweets_raw;
SELECT 
	DISTINCT topic        
FROM climate_tweets_raw;

-- -------------------------------------
-- 1.3 Identify Data Quality Issues
-- -------------------------------------

-- Missing/null coordinates
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE lat IS NULL OR lng IS NULL) AS missing_coordinates,
    ROUND(
        COUNT(*) FILTER (WHERE lat IS NULL OR lng IS NULL)::NUMERIC / COUNT(*) * 100, 2
    ) AS pct_missing_coordinates
FROM climate_tweets_raw;

-- Missing temperature_avg
SELECT
	COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE temperature_avg IS NULL) AS missing_temperature,
    ROUND(
        COUNT(*) FILTER (WHERE temperature_avg IS NULL)::NUMERIC / COUNT(*) * 100, 2
    ) AS pct_missing_temperature
FROM climate_tweets_raw;

-- Undefined gender
SELECT 
	gender, 
	COUNT(*) AS total_cnt
FROM climate_tweets_raw
GROUP BY gender
ORDER BY total_cnt DESC;

-- Sentiment range check
SELECT
    MIN(sentiment) AS min_sentiment,
    MAX(sentiment) AS max_sentiment,
    COUNT(*) FILTER (WHERE sentiment < -1 OR sentiment > 1) AS out_of_range
FROM climate_tweets_raw;

-- Duplicate tweet IDs
SELECT 
	id, 
	COUNT(*) AS occurrences
FROM climate_tweets_raw
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

-- Aggressiveness distribution
SELECT 
	aggressiveness, 
	COUNT(*) AS total_cnt
FROM climate_tweets_raw
GROUP BY aggressiveness
ORDER BY total_cnt DESC;

-- =================================================
-- SECTION 2: DATA CLEANING & TRANSFORMATION
-- =================================================

-- -------------------------------------
-- 2.1 Create Cleaned Table
-- -------------------------------------
CREATE TABLE IF NOT EXISTS climate_tweets_clean AS
SELECT
	DISTINCT ON (id)
    id 										AS tweet_id,
	created_at 								AS tweet_timestamp,
    EXTRACT(YEAR  FROM created_at)::INT 	AS tweet_year,
    EXTRACT(MONTH FROM created_at)::INT 	AS tweet_month,
	DATE_TRUNC('month', created_at)::DATE 	AS month_start,
	lat,
	lng,
	CASE
		WHEN lat IS NOT NULL AND lng IS NOT NULL
     	AND lat BETWEEN -90 AND 90
     	AND lng BETWEEN -180 AND 180
    	THEN TRUE
    	ELSE FALSE
	END										AS is_geo_valid,
	LOWER(TRIM(topic)) 						AS topic,
	LOWER(TRIM(stance)) 					AS stance,
	LOWER(TRIM(aggressiveness)) 			AS aggressiveness,
	CASE
        WHEN LOWER(TRIM(gender)) IN ('male', 'female') THEN LOWER(TRIM(gender))
        ELSE 'unknown'
    END  									AS gender,
	sentiment,
	CASE
        WHEN sentiment >=  0.3 THEN 'positive'
        WHEN sentiment <= -0.3 THEN 'negative'
        ELSE 'neutral'
    END                                     AS sentiment_bucket,
	temperature_avg
	
FROM climate_tweets_raw
WHERE
    created_at IS NOT NULL
    AND id IS NOT NULL
    AND EXTRACT(YEAR FROM created_at) BETWEEN 2006 AND 2019
ORDER BY id, created_at DESC;

-- Add primary key after table creation
ALTER TABLE climate_tweets_clean
ADD PRIMARY KEY (tweet_id);

-- Add indexes for faster analytical queries
CREATE INDEX idx_tweet_date ON climate_tweets_clean(tweet_timestamp);
CREATE INDEX idx_topic ON climate_tweets_clean(topic);
CREATE INDEX idx_year_topic ON climate_tweets_clean (tweet_year, topic);

-- -----------------------------------
-- 2.2 Post-Clean Validation
-- ----------------------------------

-- Row count after cleaning
SELECT 
	COUNT(*) AS cleaned_rows 
FROM climate_tweets_clean;

-- Confirm no duplicate IDs remain
SELECT 
	COUNT(*) AS duplicate_ids
FROM (
    SELECT tweet_id 
		FROM climate_tweets_clean 
	GROUP BY tweet_id HAVING COUNT(*) > 1
) ids;

-- Check for missing critical fields after cleaning
SELECT
    COUNT(*) FILTER (WHERE tweet_timestamp IS NULL) AS missing_timestamp,
    COUNT(*) FILTER (WHERE topic IS NULL) AS missing_topic,
    COUNT(*) FILTER (WHERE sentiment IS NULL) AS missing_sentiment
FROM climate_tweets_clean;

-- ============================================
-- SECTION 3: DESCRIPTIVE ANALYTICS
-- ============================================

-- ---------------------------------------------
-- 3.1 Overall Summary Statistics
-- ---------------------------------------------
CREATE OR REPLACE VIEW vw_summary_stats AS
SELECT
    COUNT(*)                                                AS total_tweets,
    MIN(tweet_year)                                         AS earliest_year,
    MAX(tweet_year)                                         AS latest_year,
    COUNT(DISTINCT topic)                                   AS distinct_topics,
    COUNT(DISTINCT stance)                                  AS distinct_stances,
    ROUND(AVG(sentiment)::NUMERIC, 4)                       AS avg_sentiment,
    ROUND(STDDEV(sentiment)::NUMERIC, 4)                    AS stddev_sentiment,
    COUNT(*) FILTER (WHERE is_geo_valid = TRUE)             AS geo_tagged_tweets,
    ROUND(
        COUNT(*) FILTER (WHERE is_geo_valid = TRUE)::NUMERIC
        / COUNT(*), 4
    )                                                       AS pct_geo_tagged,
    COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')   AS aggressive_tweets,
    ROUND(
        COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')::NUMERIC
        / COUNT(*), 4
    )                                                       AS pct_aggressive
FROM climate_tweets_clean;

-- ---------------------------------------
-- 3.2 Tweet Volume by Year
-- ---------------------------------------
CREATE OR REPLACE VIEW vw_tweets_by_year AS
SELECT
    tweet_year,
    COUNT(*)                                                AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)                       AS avg_sentiment,
    COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')   AS aggressive_tweets,
    ROUND(
        COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')::NUMERIC
        / COUNT(*), 4
    )                                                       AS pct_aggressive
FROM climate_tweets_clean
GROUP BY tweet_year;

-- -----------------------------------------
-- 3.3 Stance Distribution
-- -----------------------------------------
CREATE OR REPLACE VIEW vw_stance_distribution AS
SELECT
    stance,
    COUNT(*)                                                AS tweet_count,
    ROUND(
        COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER(), 4
    )                                                       AS pct_of_total,
    ROUND(AVG(sentiment)::NUMERIC, 4)                       AS avg_sentiment
FROM climate_tweets_clean
GROUP BY stance;

-- ---------------------------------------------
-- 3.4 Sentiment Distribution
-- ----------------------------------------------
CREATE OR REPLACE VIEW vw_sentiment_distribution AS
SELECT
    sentiment_bucket,
    COUNT(*)                                                AS tweet_count,
    ROUND(
        COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER(), 4
    )                                                       AS pct_of_total,
    ROUND(AVG(sentiment)::NUMERIC, 4) 						 AS avg_sentiment
FROM climate_tweets_clean
GROUP BY sentiment_bucket;

-- -------------------------------------------
-- 3.5 Topic Distribution
-- -------------------------------------------
CREATE OR REPLACE VIEW vw_topic_distribution AS
SELECT
    topic,
    COUNT(*)                                                AS tweet_count,
    ROUND(
        COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER(), 4
    )                                                       AS pct_of_total,
    ROUND(AVG(sentiment)::NUMERIC, 4)                       AS avg_sentiment,
    COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')   AS aggressive_count,
    ROUND(
        COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')::NUMERIC
        / COUNT(*), 4
    )                                                       AS pct_aggressive
FROM climate_tweets_clean
WHERE topic IS NOT NULL
  AND topic != 'undefined / one word hashtags'
GROUP BY topic;

-- -------------------------------------------
-- 3.6 Topic & Sentiment Distribution
-- -------------------------------------------
CREATE OR REPLACE VIEW vw_topic_sentiment_heatmap AS
SELECT
    topic,
    sentiment_bucket,
    COUNT(*) AS tweet_count,

    ROUND(
        COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER (PARTITION BY topic),
        4
    ) AS pct_within_topic,

    ROUND(
        COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')::NUMERIC
        / COUNT(*),
        4
    ) AS pct_aggressive
FROM climate_tweets_clean
WHERE topic IS NOT NULL
  AND topic != 'undefined / one word hashtags'
GROUP BY topic, sentiment_bucket;

-- ===============================================
-- SECTION 4: DIAGNOSTIC ANALYTICS
-- ===============================================

-- --------------------------------------------------------------
-- 4.1 Stance Trend by Year
-- How belief, denial and neutrality shifted over 13 years
-- --------------------------------------------------------------
CREATE OR REPLACE VIEW vw_stance_trend_by_year AS
SELECT
    tweet_year,
    stance,
    COUNT(*)                                                AS tweet_count,
    ROUND(
        COUNT(*)::NUMERIC/ SUM(COUNT(*)) OVER (PARTITION BY tweet_year)
		, 4
    )                                                       AS pct_of_year
FROM climate_tweets_clean
GROUP BY tweet_year, stance;

-- -----------------------------------------------------------
-- 4.2 Aggressiveness by Topic
-- Which topics generate the most hostile discourse?
-- -----------------------------------------------------------
CREATE OR REPLACE VIEW vw_aggressiveness_by_topic AS
SELECT
    topic,
    COUNT(*)                                                AS total_tweets,
    COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')   AS aggressive_count,
    ROUND(
        COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')::NUMERIC
        / COUNT(*), 4
    )                                                       AS pct_aggressive,
    ROUND(AVG(sentiment)::NUMERIC, 4)                       AS avg_sentiment
FROM climate_tweets_clean
WHERE topic IS NOT NULL
  AND topic != 'undefined / one word hashtags'
GROUP BY topic;

-- ----------------------------------------------------------------
-- 4.3 Aggressiveness by Stance
-- Do deniers tweet more aggressively than believers?
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW vw_aggressiveness_by_stance AS
SELECT
    stance,
    COUNT(*)                                                AS total_tweets,
    COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')   AS aggressive_count,
    ROUND(
        COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')::NUMERIC
        / COUNT(*), 4
    )                                                       AS pct_aggressive,
    ROUND(AVG(sentiment)::NUMERIC, 4)                       AS avg_sentiment
FROM climate_tweets_clean
GROUP BY stance;

-- ----------------------------------------------------------------------
-- 4.4 Regional Analysis
-- Sentiment and aggressiveness patterns by geographic region
-- ----------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_regional_analysis AS
SELECT
    CASE
        WHEN lng < -30 THEN 'Americas'
        WHEN lng BETWEEN -30 AND 60 THEN 'Africa/Europe'
        WHEN lng > 60 THEN 'Asia/Oceania'
        ELSE 'Other'
    END                                                     AS region,
    COUNT(*)                                                AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)                       AS avg_sentiment,
    COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')   AS aggressive_count,
    ROUND(
        COUNT(*) FILTER (WHERE aggressiveness = 'aggressive')::NUMERIC
        / COUNT(*), 4
    )                                                       AS pct_aggressive,
    COUNT(*) FILTER (WHERE stance = 'believer')             AS believers,
    COUNT(*) FILTER (WHERE stance = 'denier')               AS deniers,
    COUNT(*) FILTER (WHERE stance = 'neutral')              AS neutrals
FROM climate_tweets_clean
WHERE is_geo_valid = TRUE
GROUP BY region;

-- ------------------------------------------------------------------------
-- 4.5 Year-over-Year Sentiment Change
-- Measures how average sentiment shifts from one year to the next
-- ------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_yoy_sentiment_change AS
WITH yearly AS (
    SELECT
        tweet_year,
        AVG(sentiment) 										AS avg_sentiment
    FROM climate_tweets_clean
    GROUP BY tweet_year
)
SELECT
    tweet_year,
    ROUND(avg_sentiment::NUMERIC, 4)						AS avg_sentiment,
	COALESCE(
    	ROUND(
        (avg_sentiment - LAG(avg_sentiment) OVER (ORDER BY tweet_year))::NUMERIC,
        4
    	), 0
	)														AS sentiment_change
FROM yearly;

-- Check view outputs
SELECT * FROM vw_summary_stats;
SELECT * FROM vw_tweets_by_year;
SELECT * FROM vw_stance_distribution;
SELECT * FROM vw_sentiment_distribution;
SELECT * FROM vw_topic_distribution;
SELECT * FROM vw_stance_trend_by_year;
SELECT * FROM vw_aggressiveness_by_topic;
SELECT * FROM vw_aggressiveness_by_stance;
SELECT * FROM vw_regional_analysis;
SELECT * FROM vw_yoy_sentiment_change;


SELECT MIN(sentiment), MAX(sentiment)
FROM climate_tweets_clean;

SELECT AVG(sentiment) FROM climate_tweets_clean;
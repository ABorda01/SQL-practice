-- ###########################################
-- ###########################################
-- CHAPTER 2: Preparing Data
-- ###########################################
-- ###########################################

-- DISTRIBUTIONS: 

-- ntiles(n_tiles) is the generalized quantile f.
-- ALWAYS performs equal-frequency binning (not equal width)

-- =====================================================================
-- NTILE example: credit-score decile table (simulated data)
-- =====================================================================
SELECT setseed(0.42);              -- makes random() reproducible

CREATE TEMPORARY TABLE applicants AS

SELECT id,
       score,
       -- default probability falls with score (logistic curve centred at 560)
       (random() < 1 / (1 + exp((score - 560) / 40.0)))::int AS defaulted
FROM (
    SELECT id, round(random_normal(650, 60))::int AS score
    FROM generate_series(1, 2000) AS id
) AS s;

SELECT decile,
       COUNT(*)                                         AS n,
       MIN(score)                                       AS min_score,
       MAX(score)                                       AS max_score,
       SUM(defaulted)                                   AS defaults,
       ROUND(AVG(defaulted) * 100, 1)                   AS default_rate_pct,
       -- share of all defaults captured from the lowest decile up to this one
       ROUND(100.0 * SUM(SUM(defaulted)) OVER (ORDER BY decile)
                   / SUM(SUM(defaulted)) OVER (), 1)    AS cum_defaults_pct
FROM (
    SELECT score, defaulted,
           NTILE(10) OVER (ORDER BY score) AS decile   -- 1 = lowest scores
    FROM applicants
) AS t
GROUP BY decile
ORDER BY decile;

-- percent_rank() returns the percentile. Also used on window f. typically

-- =====================================================================
-- PERCENT_RANK example (uses the temporary table applicants from the NTILE example)
-- =====================================================================

-- 1) Ties: PERCENT_RANK keeps them together, NTILE splits them
SELECT id, score,
       ROUND(PERCENT_RANK() OVER (ORDER BY score)::numeric, 4) AS pct_rank,
       NTILE(10) OVER (ORDER BY score)                          AS decile_ntile
FROM applicants
ORDER BY score, id
OFFSET 194 LIMIT 12;          -- rows around the decile 1 / decile 2 boundary

-- 2) Approval rule: reject the bottom 30% of scores
SELECT CASE WHEN pct_rank >= 0.30 THEN 'approved' ELSE 'rejected' END AS decision,
       COUNT(*)                        AS n,
       MIN(score)                      AS min_score,
       ROUND(AVG(defaulted) * 100, 1)  AS default_rate_pct
FROM (
    SELECT score, defaulted,
           PERCENT_RANK() OVER (ORDER BY score) AS pct_rank
    FROM applicants
) AS t
GROUP BY 1
ORDER BY 1;



-- Data type modification:

-- The standard way is CAST(value AS type)
-- The PostgreSQL shorthand version is value :: type




-- =====================================================================
-- Pivot with CASE: yearly sales by clothing-store type (millions of USD)
-- =====================================================================
SELECT date_part('year', sales_month)::int AS sales_year,
       SUM(CASE WHEN kind_of_business = 'Men''s clothing stores'   THEN sales END) AS mens,
       SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens,
       SUM(CASE WHEN kind_of_business = 'Family clothing stores'   THEN sales END) AS family
FROM retail_sales
WHERE kind_of_business IN ('Men''s clothing stores',
                           'Women''s clothing stores',
                           'Family clothing stores')
  AND sales_month >= '2015-01-01' AND sales_month < '2021-01-01'
GROUP BY 1
ORDER BY 1;




-- =====================================================================
-- Unpivot with UNION ALL: wide (1 column per store type) -> long (1 row per store type)
-- =====================================================================
WITH wide AS (                          -- the pivot from before
    SELECT date_part('year', sales_month)::int AS sales_year,
           SUM(CASE WHEN kind_of_business = 'Men''s clothing stores'   THEN sales END) AS mens,
           SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens,
           SUM(CASE WHEN kind_of_business = 'Family clothing stores'   THEN sales END) AS family
    FROM retail_sales
    WHERE kind_of_business IN ('Men''s clothing stores',
                               'Women''s clothing stores',
                               'Family clothing stores')
      AND sales_month >= '2015-01-01' AND sales_month < '2021-01-01'
    GROUP BY 1
)
SELECT sales_year, 'mens'   AS store_type, mens   AS sales FROM wide
UNION ALL
SELECT sales_year, 'womens' AS store_type, womens AS sales FROM wide
UNION ALL
SELECT sales_year, 'family' AS store_type, family AS sales FROM wide
ORDER BY sales_year, store_type;




-- ###########################################
-- ###########################################
-- CHAPTER 3: Time Series Analysis
-- ###########################################
-- ###########################################



SELECT make_date(2020,09,01);

SELECT to_date(concat(2020,'-',09,'-',01), 'yyyy-mm-dd');


SELECT age(date('2020-06-30'),date('2020-01-01'));

SELECT date('2020-06-01') + interval '7 days' as new_date;


-- TRENDING THE DATA

-- These kind of queries are ready to be plotted for trend-iding

SELECT date_part('year',sales_month) AS sales_year
,sum(sales) AS sales
FROM retail_sales
WHERE kind_of_business = 'Retail and food services sales, total'
GROUP BY 1
ORDER BY 1 ASC;


SELECT date_part('year',sales_month) AS sales_year,
kind_of_business,
sum(sales) AS sales
FROM retail_sales
WHERE kind_of_business in ('Book stores' ,
    'Sporting goods stores','Hobby, toy, and game stores')
GROUP BY 1,2
ORDER BY 1,2;


SELECT t.sales_year AS sales_year,
t.women_sales - t.men_sales AS diff,
CONCAT (CAST(ROUND((100 * t.women_sales / (t.women_sales+t.men_sales)), 2) 
    AS varchar), '%') AS pct
FROM (
    SELECT date_part('year', sales_month) AS sales_year,
    SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' 
        THEN sales END) AS women_sales,
    SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' 
        THEN sales END) AS men_sales
    FROM retail_sales
    WHERE kind_of_business in ('Men''s clothing stores', 
        'Women''s clothing stores')
    GROUP BY 1
    ) AS t
ORDER BY 1;







-- =========================================
-- Ch. 14 — Views
-- =========================================
USE sakila;


DROP VIEW IF EXISTS customer_vw;


CREATE VIEW customer_vw
 (customer_id, first_name, last_name, email) AS
SELECT customer_id, first_name, last_name, concat(substr(email,1,2), '*****', substr(email, -4)) email
FROM customer;


SELECT * FROM customer_vw;

DESCRIBE customer_vw;



DROP VIEW IF EXISTS sales_by_film_category;

CREATE VIEW sales_by_film_category
AS
SELECT
 c.name AS category,
 SUM(p.amount) AS total_sales
FROM payment AS p
 INNER JOIN rental AS r ON p.rental_id = r.rental_id
 INNER JOIN inventory AS i ON r.inventory_id = i.inventory_id
 INNER JOIN film AS f ON i.film_id = f.film_id
 INNER JOIN film_category AS fc ON f.film_id = fc.film_id
 INNER JOIN category AS c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY total_sales DESC;

SELECT * FROM sales_by_film_category;


-- Views are used to protect sensitive information, grant limited data to some users,
-- display aggregated/modified data without modifying the underlaying data and others.

DROP VIEW IF EXISTS film_stats;

CREATE VIEW film_stats
AS
SELECT f.film_id, f.title, f.description, f.rating,
 (SELECT c.name
 FROM category c
 INNER JOIN film_category fc
 ON c.category_id = fc.category_id
 WHERE fc.film_id = f.film_id) category_name,
 (SELECT count(*)
 FROM film_actor fa
 WHERE fa.film_id = f.film_id
 ) num_actors,
 (SELECT count(*)
 FROM inventory i
 WHERE i.film_id = f.film_id
 ) inventory_cnt,
 (SELECT count(*)
 FROM inventory i
 INNER JOIN rental r
 ON i.inventory_id = r.inventory_id
 WHERE i.film_id = f.film_id
 ) num_rentals
FROM film f;

SELECT * FROM film_stats;




-- =========================================
-- Ch. 16 — Analytic functions
-- =========================================


SELECT quarter(payment_date) quarter, monthname(payment_date) month_nm, sum(amount) monthly_sales,
max(sum(amount)) over () max_overall_sales,
max(sum(amount)) over (partition by quarter(payment_date)) max_qrtr_sales
FROM payment
WHERE year(payment_date) = 2005
GROUP BY quarter(payment_date), monthname(payment_date);

-- =====================================================================
-- WINDOW (ANALYTIC) FUNCTIONS — OVER / PARTITION BY
-- =====================================================================
--
-- Can only be used in the SELECT() clause
--
-- func(...) OVER (
--     [PARTITION BY col, ...]     -- split rows into groups WITHOUT collapsing them
--     [ORDER BY col [DESC], ...]  -- order of rows inside each partition
--     [ROWS BETWEEN start AND end]-- optional frame: which rows the function sees
-- ) AS alias
--
-- * Every row is kept; each row gets a value computed over its window.
-- * No PARTITION BY  -> whole result is one window.  OVER () = all rows.



SELECT quarter(payment_date) quarter, monthname(payment_date) month_nm, sum(amount) monthly_sales,
rank() over (order by sum(amount) desc) sales_rank -- The order by clause determines the manner of ranking
FROM payment
WHERE year(payment_date) = 2005
GROUP BY quarter(payment_date), monthname(payment_date)
ORDER BY 1, MIN(month(payment_date));

SELECT quarter(payment_date) quarter, monthname(payment_date) month_nm, sum(amount) monthly_sales,
rank() over (partition by quarter(payment_date)
    order by sum(amount) desc) sales_rank -- Now the ranking is done per quarter instead
FROM payment
WHERE year(payment_date) = 2005
GROUP BY quarter(payment_date), monthname(payment_date)
ORDER BY 1, MIN(month(payment_date));


-- =====================================================================
-- MOST USED ANALYTIC FUNCTIONS
-- =====================================================================
-- Ranking (need ORDER BY in OVER):
--   ROW_NUMBER()  1,2,3,4  unique numbers, ties broken arbitrarily -> "one row per group"
--   RANK()        1,2,2,4  ties share rank, gaps after ties       -> "top-N incl. ties"
--   DENSE_RANK()  1,2,2,3  ties share rank, no gaps
--   NTILE(n)      bucket number 1..n (quartiles, deciles)
--
-- Offset (need ORDER BY in OVER):
--   LAG(col [, k [, default]])   value k rows BEFORE (default k = 1)
--   LEAD(col [, k [, default]])  value k rows AFTER
--   FIRST_VALUE(col) / LAST_VALUE(col) / NTH_VALUE(col, n)
--     (LAST_VALUE needs ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
--
-- Aggregates as windows:
--   SUM/COUNT/AVG/MIN/MAX(col) OVER (PARTITION BY g)              group total on every row
--   SUM(col) OVER (PARTITION BY g ORDER BY t)                     running total
--   AVG(col) OVER (ORDER BY t ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)  7-row moving avg
--   col / SUM(col) OVER (PARTITION BY g)                          share of group total
--
-- Distribution:
--   PERCENT_RANK()  (rank-1)/(rows-1), in [0,1]
--   CUME_DIST()     fraction of rows <= current row
--
-- Typical patterns:
--   one row per group:   WHERE ROW_NUMBER() ... = 1   (in outer query)
--   top-N per group:     WHERE RANK() ... <= N
--   change vs previous:  col - LAG(col) OVER (PARTITION BY g ORDER BY t)




-- Reporting functions: MAX(), MIN(), etc 

SELECT monthname(payment_date) payment_month, amount,
SUM(amount) OVER (PARTITION BY monthname(payment_date)) AS monthly_total,
SUM(amount) OVER () AS grand_total
FROM payment
WHERE amount >= 10
ORDER BY 1;

SELECT monthname(payment_date) payment_month, SUM(amount) AS month_total,
CASE SUM(amount)
    WHEN (MAX(SUM(amount)) over ()) THEN 'Highest'
    WHEN (MIN(SUM(amount)) over ()) THEN 'Lowest'
    ELSE 'Middle'
END AS Descriptor
FROM payment
GROUP BY monthname(payment_date);


SELECT yearweek(payment_date) payment_week, sum(amount) week_total,
sum(sum(amount)) over (order by yearweek(payment_date) rows unbounded preceding) rolling_sum
FROM payment -- Cumulative total from the start of the given year to the final row
GROUP BY yearweek(payment_date)
ORDER BY 1;

SELECT yearweek(payment_date) payment_week, sum(amount) week_total,
avg(sum(amount)) over (order by yearweek(payment_date) rows between 1 preceding and 1 following) rolling_3wk_avg
FROM payment
GROUP BY yearweek(payment_date)
ORDER BY 1;


-- LAG AND LEAD:

SELECT yearweek(payment_date) payment_week, sum(amount) week_total,
lag(sum(amount), 1) over (order by yearweek(payment_date)) prev_wk_tot,
lead(sum(amount), 1) over (order by yearweek(payment_date)) next_wk_tot
FROM payment
GROUP BY yearweek(payment_date)
ORDER BY 1;

-- Windows can also be explicitly named for brevity, e.g.:

SELECT YEARWEEK(payment_date) AS payment_week, SUM(amount) AS week_total,
LAG(SUM(amount), 1)  OVER w AS prev_wk_tot,
LEAD(SUM(amount), 1) OVER w AS next_wk_tot
FROM payment
GROUP BY YEARWEEK(payment_date)
WINDOW w AS (ORDER BY YEARWEEK(payment_date)) -- Before ordery by necessarily
ORDER BY 1;


SELECT YEARWEEK(payment_date) AS payment_week, SUM(amount) AS week_total,
ROUND((SUM(amount) - LAG(sum(amount), 1) OVER w) / 
(LAG(sum(amount), 1) OVER w) * 100, 1) AS pct_diff
FROM payment
GROUP BY YEARWEEK(payment_date)
WINDOW w as (ORDER BY YEARWEEK(payment_date))
ORDER BY 1;


-- Not a WINDOW function but relevant: groupconcat()

SELECT f.title,
GROUP_CONCAT(a.last_name ORDER BY a.last_name SEPARATOR ', ') actors
FROM actor AS a
INNER JOIN film_actor AS fa ON a.actor_id = fa.actor_id
INNER JOIN film AS f ON fa.film_id = f.film_id
GROUP BY f.title
HAVING count(*) = 3;






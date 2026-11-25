-- =========================================
-- Ch. 8 — Groupping and Aggregates
-- =========================================


USE sakila;

SELECT customer_id, count(*) AS number_of_rentals
FROM rental
GROUP BY customer_id
ORDER BY 2 DESC; -- 2 works as column number of the SELECT clause


-- The GROUP BY clause runs AFTER the WHERE clause so we need HAVING instead

SELECT customer_id, count(*) AS number_of_rentals
FROM rental
GROUP BY customer_id
HAVING number_of_rentals >= 40;


-- Typical aggregate functions include:
--      max(), min(), avg(), sum(), count()...

SELECT MAX(amount) max_amt, 
MIN(amount) min_amt,
AVG(amount) avg_amt, 
SUM(amount) tot_amt, 
COUNT(*) num_payments
FROM payment;


-- Explicit grouping: The previous query works with implicit grouping. The following needs explicit

SELECT customer_id,
MAX(amount) max_amt,
MIN(amount) min_amt,
AVG(amount) avg_amt,
SUM(amount) tot_amt,
COUNT(*) num_payments
FROM payment
GROUP BY customer_id; -- Without the GROUP BY clause this query fails


-- COUNT() can be used for distinct VALUES. COUNT also includes null values

SELECT COUNT(customer_id) AS num_rows,
COUNT(DISTINCT customer_id) AS num_customers
FROM payment;


-- MULTI-COLUMN grouping: One row for each combination of grouping columns

 SELECT fa.actor_id, f.rating, count(*)
FROM film_actor fa
INNER JOIN film f
ON fa.film_id = f.film_id
GROUP BY fa.actor_id, f.rating
ORDER BY 1,2;


SELECT extract(YEAR FROM rental_date) AS year,
count(*) AS amount
FROM rental
GROUP BY extract(YEAR FROM rental_date);



-- ROLLUP: (null, null) = grand total; (id, null) total for said id.

SELECT fa.actor_id, f.rating, count(*)
FROM film_actor fa
INNER JOIN film f
ON fa.film_id = f.film_id
GROUP BY fa.actor_id, f.rating WITH ROLLUP
ORDER BY 1, 2;

-- WITH ROLLUP: adds subtotal and grand-total rows to a GROUP BY.
--   GROUP BY a, b WITH ROLLUP  produces groups at these levels:
--     (a, b)  -> normal groups
--     (a)     -> subtotal per a, across all b
--     ()      -> grand total
--   Columns are rolled up right to left, so the column order matters.
--   In subtotal/total rows, rolled-up columns show NULL (= "all").
--   GROUPING(col) = 1 marks those rows, to tell them apart from real NULLs.


SELECT fa.actor_id, f.rating, count(*)
FROM film_actor fa
INNER JOIN film f
ON fa.film_id = f.film_id
WHERE f.rating IN ('G','PG') -- Filter before grouping
GROUP BY fa.actor_id, f.rating
HAVING count(*) > 9; -- Filter for grouped columns




-- =========================================
-- Ch. 9 — Subqueries
-- =========================================


SELECT customer_id, first_name, last_name
FROM customer
WHERE customer_id = (SELECT MAX(customer_id) 
                    FROM customer); -- returns single row, single column (Scalar subquery)


-- NONCORRELATED SUBQUERIES: Can be ran independently of the larger query


SELECT city_id, city
FROM city
WHERE country_id != (SELECT country_id
                     FROM country
                     WHERE country = 'India');
            -- The subquerie allows us to access the country table without joining


-- Multi-row subqueries: Cannot directly use (in)equalities. Can use IN, ALL and such

SELECT city_id, city
FROM city
WHERE country_id NOT IN (
    SELECT country_id
    FROM country
    WHERE country in ('Mexico', 'Canada', 'Spain')
);


SELECT first_name, last_name
FROM customer
WHERE customer_id != ALL ( -- Checks for ALL rows (vectorized comparison)
    SELECT customer_id
    FROM payment
    WHERE amount = 0
);


SELECT customer_id, count(*) -- "Customers whose rental number exceeds EVERYONE in NA"
FROM rental
GROUP BY customer_id
HAVING count(*) > ALL (
    SELECT count(*)
    FROM rental r
    INNER JOIN customer c
    ON r.customer_id = c.customer_id
    INNER JOIN address a
    ON c.address_id = a.address_id
    INNER JOIN city ct
    ON a.city_id = ct.city_id
    INNER JOIN country co
    ON ct.country_id = co.country_id
    WHERE co.country IN ('United States','Mexico','Canada')
    GROUP BY r.customer_id
);


SELECT customer_id, count(*) -- "Customers whose rental number exceeds SOMEONE in NA"
FROM rental
GROUP BY customer_id
HAVING count(*) > ANY (
    SELECT count(*)
    FROM rental r
    INNER JOIN customer c
    ON r.customer_id = c.customer_id
    INNER JOIN address a
    ON c.address_id = a.address_id
    INNER JOIN city ct
    ON a.city_id = ct.city_id
    INNER JOIN country co
    ON ct.country_id = co.country_id
    WHERE co.country IN ('United States','Mexico','Canada')
    GROUP BY r.customer_id
);



SELECT customer_id, sum(amount) -- ALL customers whose total spending exceeded the total of
FROM payment                    --     Paraguay, Bolivia or Chile
GROUP BY customer_id
HAVING sum(amount) > ANY (
    SELECT sum(p.amount)
    FROM payment p
    INNER JOIN customer c
    ON p.customer_id = c.customer_id
    INNER JOIN address a
    ON c.address_id = a.address_id
    INNER JOIN city ct
    ON a.city_id = ct.city_id
    INNER JOIN country co
    ON ct.country_id = co.country_id
    WHERE co.country IN ('Bolivia','Paraguay','Chile')
    GROUP BY co.country
);




-- MULTI-COLUMN SUBQUERIES:

SELECT actor_id, film_id
FROM film_actor
WHERE (actor_id, film_id) IN (
    SELECT a.actor_id, f.film_id
    FROM actor AS a
    CROSS JOIN film as f
    WHERE (a.last_name = 'Monroe') AND (f.rating = 'PG') -- We need AND since we cross-joined
);


-- CORRELATED SUBQUERIES: The subquery is dependent on its containing statement.
--                        Executed once per (containing) row, instead of before the containing statement.


SELECT c.first_name, c.last_name
FROM customer c
WHERE 20 = ( -- Analogous to a FOR cycle in py
    SELECT count(*) FROM rental r
    WHERE r.customer_id = c.customer_id -- correlation
);


-- "Find all customers whose total rental payment is between 180 and 240"
SELECT c.first_name, c.last_name
FROM customer AS c
WHERE (
    SELECT sum(p.amount) -- Table containing only said customer
    FROM payment AS p
    WHERE p.customer_id = c.customer_id
) BETWEEN 180 AND 240;


-- EXISTS:

SELECT c.first_name, c.last_name -- "SELECT x WHERE Y(x) IS TRUE"
FROM customer c
WHERE EXISTS (
    SELECT 1 FROM rental r -- 1 is a placeholder, * would yield the same or anything else
    WHERE r.customer_id = c.customer_id AND date(r.rental_date) < '2005-05-25'
);
-- EXISTS (subquery): true if the subquery returns >= 1 rows; values are ignored,
-- NOT EXISTS: keeps outer rows with no match (safer than NOT IN when NULLs are possible).



-- DATA MANIPULATION USING CORRELATED SUBQUERIES:

CREATE DATABASE IF NOT EXISTS practice;

CREATE TABLE practice.customer LIKE sakila.customer;            -- same columns, types, keys, indexes
INSERT INTO practice.customer SELECT * FROM sakila.customer; 
CREATE TABLE practice.rental LIKE sakila.rental;            -- same columns, types, keys, indexes
INSERT INTO practice.rental SELECT * FROM sakila.rental;   -- copy the data

SHOW TABLES FROM practice;

UPDATE practice.customer AS c
SET c.last_update =
    (SELECT MAX(r.rental_date) FROM practice.rental AS r
    WHERE r.customer_id = c.customer_id)
WHERE EXISTS
    (SELECT 1 FROM practice.rental AS r
    WHERE r.customer_id = c.customer_id);

SELECT c.first_name, c.last_name, c.last_update, MAX(r.rental_date)
FROM practice.customer AS c INNER JOIN practice.rental AS r
ON r.customer_id = c.customer_id
GROUP BY c.customer_id;


DELETE FROM practice.customer
WHERE 365 < ALL
  (SELECT DATEDIFF('2006-11-15', r.rental_date)
 FROM practice.rental r
 WHERE r.customer_id = customer.customer_id);

SELECT * FROM practice.customer; 

DROP TABLE IF EXISTS practice.customer;
DROP TABLE IF EXISTS practice.rental;

SHOW TABLES FROM practice;



-- SUBQUERIES AS DATA SOURCES:


-- Subquery on FORM clause: HAVE TO BE NON-CORRELATED
SELECT c.first_name, c.last_name, pymnt.num_rentals, pymnt.tot_payments
FROM customer AS c
INNER JOIN
    (SELECT customer_id, count(*) AS num_rentals, sum(amount) AS tot_payments
    FROM payment
    GROUP BY customer_id
    ) AS pymnt
ON c.customer_id = pymnt.customer_id;


-- Data generation in subquery:

SELECT pymnt_grps.name, count(*) AS num_customers
FROM
    (SELECT customer_id,
    count(*) AS num_rentals, sum(amount) AS tot_payments
    FROM payment
    GROUP BY customer_id
    ) AS pymnt
INNER JOIN                 -- Here we create the table with the categories we wish to group by later
    (SELECT 'Small Fry' name, 0 AS low_limit, 74.99 AS high_limit -- SELECT without FROM produces a row of constants
    UNION ALL              -- UNION ALL stacks the three rows of contants on top of each other
    SELECT 'Average Joes' name, 75 AS low_limit, 149.99 AS high_limit
    UNION ALL
    SELECT 'Heavy Hitters' name, 150 AS low_limit, 9999999.99 AS high_limit
    ) AS pymnt_grps
ON pymnt.tot_payments BETWEEN pymnt_grps.low_limit AND pymnt_grps.high_limit -- groups all customers in the range
GROUP BY pymnt_grps.name;

-- See inner table:

SELECT 'Small Fry' name, 0 low_limit, 74.99 high_limit
    UNION ALL
    SELECT 'Average Joes' name, 75 low_limit, 149.99 high_limit
    UNION ALL
    SELECT 'Heavy Hitters' name, 150 low_limit, 9999999.99 high_limit;




-- SUBQUERIES AS EXPRESSION GENERATORS:

SELECT
  (SELECT c.first_name FROM customer c
   WHERE c.customer_id = p.customer_id
  ) AS first_name,
  (SELECT c.last_name FROM customer c
   WHERE c.customer_id = p.customer_id
  ) AS last_name,
  (SELECT ct.city FROM customer c
   INNER JOIN address a
     ON c.address_id = a.address_id
   INNER JOIN city ct
     ON a.city_id = ct.city_id
   WHERE c.customer_id = p.customer_id
  ) AS city,
sum(p.amount) tot_payments, count(*) tot_rentals
FROM payment p
GROUP BY p.customer_id;




















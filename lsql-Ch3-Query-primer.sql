-- =========================================
-- Ch. 3 — Query primer
-- =========================================

USE sakila;

-- SELECT statement clausses:
--      select Determines which columns to include in the query’s result set
--      from Identifies the tables from which to retrieve data and how the tables should be joined
--      where Filters out unwanted data
--      group by Used to group rows together by common column values
--      having Filters out unwanted groups
--      order by Sorts the rows of the final result set by one or more columns


SELECT * -- * indicates all columns
FROM language; -- lists the table to select IMPORT TABLE FROM

-- This query is identical to "Show me all the columns and all the rows in the language table"

SELECT language_id, name 
FROM language;


SELECT language_id, -- The SELECT clauses can include modifications and can add column aliases
'COMMON' language_usage,
language_id * 3.1415927 AS lang_pi_value, -- "AS" is optional but is clearer
upper(name) language_name
FROM language;


-- Removing duplicates:

SELECT actor_id FROM film_actor ORDER BY actor_id;

SELECT DISTINCT actor_id FROM film_actor ORDER BY actor_id; -- 200 rows vs previous 1000 rows (records)


-- FROM clause: "he from clause defines the tables used by a query, along with the means of linking the tables together."

SELECT concat(cust.last_name, ', ', cust.first_name) AS full_name
FROM
(SELECT first_name, last_name, email
FROM customer
WHERE first_name = 'JESSIE'
) AS cust; -- cust is the alias given to the subtable


-- TEMPORARY TABLES: 

DROP TEMPORARY TABLE IF EXISTS actors_j; -- needed to rerun in same session

CREATE TEMPORARY TABLE actors_j
(actor_id smallint(5),  -- integer
first_name varchar(45), -- variable of at most 45 characters
last_name varchar(45));

INSERT INTO actors_j
SELECT actor_id, first_name, last_name
FROM actor
WHERE last_name LIKE 'J%'; -- "starts with J"

SELECT * FROM actors_j;

-- Equivalent:

DROP TEMPORARY TABLE IF EXISTS actors_j;

CREATE TEMPORARY TABLE actors_j
SELECT actor_id, first_name, last_name
FROM actor
WHERE last_name LIKE 'J%';

SELECT * FROM actors_j;


-- VIEWS: A view is a query that is stored in the data dictionary. It looks and acts like a table, but 
--        there is no data associated with a view. It is a 'virtual' TABLE

DROP VIEW IF EXISTS cust_vw;

CREATE VIEW cust_vw AS
SELECT customer_id, first_name, last_name, active -- active is just another column
FROM customer;

SELECT first_name, last_name
FROM cust_vw
WHERE active = 0;

-- views do modify underlaying data while temp tables just make copies.ALTER


-- TABLE LINKS: If more than one table appears in the FORM clause the condition to link them must be included

SELECT customer.first_name, customer.last_name, time(rental.rental_date) rental_time
FROM customer
INNER JOIN rental
ON customer.customer_id = rental.customer_id -- uses the whole table name to reference it
WHERE date(rental.rental_date) = '2005-06-14';
-- displays data from both the customer and rental tables. Customer ID joins them (common column)

SELECT c.first_name, c.last_name, time(r.rental_date) rental_time
FROM customer c
INNER JOIN rental AS r
ON c.customer_id = r.customer_id -- uses alias "AS" optional as usual
WHERE date(r.rental_date) = '2005-06-14';


-- WHERE: Traditional conditional operator on selection of data 

SELECT title
FROM film
WHERE rating = 'G' AND rental_duration >= 7;

SELECT title
FROM film
WHERE rating = 'G' OR rental_duration >= 7;

SELECT title, rating, rental_duration
FROM film
WHERE (rating = 'G' AND rental_duration >= 7) OR (rating = 'PG-13' AND rental_duration < 4);

-- GROUPBY \ ORDERBY:

SELECT c.first_name, c.last_name, count(*)
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.first_name, c.last_name
HAVING count(*) >= 40;

SELECT c.first_name, c.last_name, time(r.rental_date) rental_time
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
WHERE date(r.rental_date) = '2005-06-14'
ORDER BY c.last_name DESC, c.first_name ASC; -- alphabetical | the second condition resolves ties

-- we can also reference column position
SELECT c.first_name, c.last_name, time(r.rental_date) rental_time
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
WHERE date(r.rental_date) = '2005-06-14'
ORDER BY 3 desc; -- 3 == 'rental_time'

-- Exercise 3.3: Write a query against the rental table that returns the IDs of the customers who rented a film on 
--  July 5, 2005 (use the rental.rental_date column, and you can use the date() function to ignore the time component). 
-- Include a single row for each distinct customer ID

SELECT DISTINCT c.customer_id
FROM customer AS c INNER JOIN rental AS r ON c.customer_id = r.customer_id -- join not really needed
WHERE date(r.rental_date) = '2005-07-05'




























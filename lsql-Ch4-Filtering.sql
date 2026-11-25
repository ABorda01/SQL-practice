-- =========================================
-- Ch. 4 — Filtering
-- =========================================

USE sakila;

SELECT first_name, last_name
FROM customer
WHERE customer.first_name != 'John';

-- Care with deletes:

START TRANSACTION; -- suspends auto-commit

DELETE FROM rental WHERE YEAR(rental_date) = 2005;
SELECT COUNT(*) FROM rental;   -- inspect the result

ROLLBACK;   -- undo everything since START TRANSACTION
-- COMMIT;  -- or make it permanent instead
SELECT COUNT(*) FROM rental;



-- BETWEEN:

SELECT customer_id, rental_date
FROM rental
WHERE rental_date BETWEEN '2005-06-14' AND '2005-06-16'
ORDER BY date(rental_date) DESC;
-- due to date conversion 06-16 only includes midnight exactly


SELECT customer_id, payment_date, amount
FROM payment
WHERE amount BETWEEN 10 AND 11.99 -- inclusive
ORDER BY amount DESC;

SELECT last_name, first_name
FROM customer
WHERE last_name BETWEEN 'FA' and 'FR'-- FR > FRA lexicographically
ORDER BY last_name DESC; 

SELECT last_name, first_name
FROM customer
WHERE last_name BETWEEN 'FA' and 'FRB'
ORDER BY last_name DESC; 


-- SUBQUERIES: 

SELECT title, rating
FROM film                                -- 'title includes "PET" ' (ignores case)
WHERE rating NOT IN (SELECT rating FROM film WHERE title LIKE '%PET%');


SELECT last_name, first_name
FROM customer
WHERE last_name LIKE '_A_T%S'; -- "where last_name = XAXTX...XS"

-- % esentially denotes any characters can be in the middle while _ is a fixed spot

SELECT last_name, first_name
FROM customer                    -- 'starts with E'
WHERE (last_name LIKE '_A_T%S') AND (first_name LIKE 'E%');


-- NULL:
SELECT rental_id, customer_id, return_date
FROM rental
WHERE return_date IS NULL;

-- IS NULL is not the same as  '= NULL'

SELECT rental_id, customer_id, return_date
FROM rental
WHERE return_date = NULL;


SELECT c.last_name, r.return_date, c.create_date
FROM customer as c
INNER JOIN rental as R ON c.customer_id = r.customer_id
WHERE (r.return_date IS NULL) OR (c.create_date IS NULL);






















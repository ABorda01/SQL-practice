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
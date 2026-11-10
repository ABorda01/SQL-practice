-- =========================================
-- Ch. 5 — Querying multiple tables
-- =========================================

USE sakila;

-- JOINS:

DESC customer;

DESC address;

-- address id is found in both tables (foreign key)


SELECT c.last_name, c.first_name, a.address
FROM customer AS C
JOIN address AS a; -- Just "JOIN" is esentially a cartesian product
                   -- typically called a CROSS JOIN



-- These version of INNER JOINS are identical:

SELECT c.last_name, c.first_name, a.address
FROM customer AS c
JOIN address AS a
ON c.address_id = a.address_id;

SELECT c.last_name, c.first_name, a.address
FROM customer AS c
INNER JOIN address AS a
ON c.address_id = a.address_id;

SELECT c.last_name, c.first_name, a.address
FROM customer AS C
INNER JOIN address AS a
USING (address_id);

SELECT c.first_name, c.last_name, a.address -- older version
FROM customer c, address a
WHERE c.address_id = a.address_id;

-- OUTER JOIN would instead include all columns even if no match was found

-- LEFT JOIN: Keeps rows with no present "ON" value as null on the LEFT of the 
--            FROM X LEFT JOIN Y ON... 
-- RIGHT JOIN: Analogously would keep all the Y rows on the previous structure


-- MULTI INNER JOIN: city_id is shared between address and city but not with customer

SELECT c.first_name, c.last_name, ct.city
FROM customer AS c
INNER JOIN address AS a ON c.address_id = a.address_id
INNER JOIN city as CT on ct.city_id = a.city_id;
-- address does not provide info for the final table; it is an intermediary to merge
-- two tables that do not share any columns. The order of joining is mute



-- SUBQUERIES AS TABLES:

SELECT c.first_name, c.last_name, addr.address, addr.city
FROM customer AS c
INNER JOIN
(SELECT a.address_id, a.address, ct.city
FROM address a
INNER JOIN city ct
ON a.city_id = ct.city_id
WHERE a.district = 'California') AS addr
ON c.address_id = addr.address_id;


SELECT f.title -- films with either of these actors
FROM film AS f
INNER JOIN film_actor AS fa ON fa.film_id = f.film_id
INNER JOIN actor AS a ON a.actor_id = fa.actor_id
WHERE ((a.first_name = 'CATE' AND a.last_name = 'MCQUEEN') OR (a.first_name = 'CUBA' AND a.last_name = 'BIRCH'));




SELECT f.title -- films with BOTH (just OR ---> AND won't work, previous lost track of multiple actors)
FROM film AS f
INNER JOIN film_actor AS fa1 ON f.film_id = fa1.film_id
INNER JOIN actor AS a1 ON a1.actor_id = fa1.actor_id
INNER JOIN film_actor AS fa2 ON fa2.film_id = fa1.film_id
INNER JOIN actor AS a2 ON a2.actor_id = fa2.actor_id
WHERE ((a1.first_name = 'CATE' AND a1.last_name = 'MCQUEEN') AND (a2.first_name = 'CUBA' AND a2.last_name = 'BIRCH'));

-- TRICK: self-join film_actor/actor twice (aliases fa1/a1 and fa2/a2).
-- A single join gives one actor per row.
-- Joining twice on the same film_id turns each row into a PAIR of actors
-- so by joining twice we form all pairs of actors found in the data

-- EQUIVALENT: Refinement of the original version

SELECT f.title
FROM film AS f
INNER JOIN film_actor AS fa ON fa.film_id = f.film_id
INNER JOIN actor AS a ON a.actor_id = fa.actor_id
WHERE (a.first_name = 'CATE' AND a.last_name = 'MCQUEEN') OR (a.first_name = 'CUBA' AND a.last_name = 'BIRCH')
GROUP BY f.film_id, f.title -- if we don't group by title as well the select can't catch it
HAVING COUNT(DISTINCT a.actor_id) = 2; -- WHERE would not work here


























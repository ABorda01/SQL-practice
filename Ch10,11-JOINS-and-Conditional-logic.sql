-- =========================================
-- Ch. 10 — JOINS revisited
-- =========================================

-- INNER JOIN (already covered, see Ch4) only includes row in the resulting TABLE
-- if and only if the JOIN condition is satisfied. Else the corresponding row is dropped


-- LEFT (RIGHT resp.) OUTER JOIN keeps all rows on the left and matches them with
-- the right (left resp.) rows of the ON condition when possible only. Only Right (resp. left) rows are included
-- when they satisfy the ON condition. The 'OUTER' part is optional, LEFT OUTER JOIN = LEFT JOIN.

SELECT f.film_id, f.title, count(i.inventory_id) num_copies
FROM film f  -- see film_id 14 has 0 num_copies as it is missing from the inventory table
LEFT OUTER JOIN inventory i
ON f.film_id = i.film_id
GROUP BY f.film_id, f.title;



-- When the right row fails to satisfy the condition a null value fills its columns
-- An INNER JOIN would not include film_id 14 at all
SELECT f.film_id, f.title, i.inventory_id, i.store_id
FROM film f
LEFT OUTER JOIN inventory i
ON f.film_id = i.film_id
WHERE f.film_id BETWEEN 13 AND 15;



SELECT f.film_id, f.title, i.inventory_id, r.rental_date
FROM film f
LEFT OUTER JOIN inventory i
ON f.film_id = i.film_id
LEFT OUTER JOIN rental r -- The second OUTER JOIN takes the previously JOINED table as the
ON i.inventory_id = r.inventory_id -- lead table, not just the inventory table
WHERE f.film_id BETWEEN 13 AND 15;


-- CROSS JOINS: Esentially a cartesian product of rows
-- ALL combinations of colums between joined tables will be found unless filtered by
-- Has no ON clause.

SELECT c.name category_name, l.name language_name
FROM category c
CROSS JOIN language l;


-- NATURAL JOIN: Let's the server pick the JOIN type, based usually on matching columns

SELECT c.first_name, c.last_name, date(r.rental_date)
FROM customer c
NATURAL JOIN rental r; -- The server picked customer_id AND last_update to join so it's empty


SELECT cust.first_name, cust.last_name, date(r.rental_date)
FROM -- by restricting the columns it works fine.
    (SELECT customer_id, first_name, last_name
    FROM customer
    ) cust
NATURAL JOIN rental r;







-- =========================================
-- Ch. 11 — Conditional logic
-- =========================================

















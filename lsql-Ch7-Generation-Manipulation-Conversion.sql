-- ===============================================
-- Ch. 7 - Generation, manipulation and conversion
-- ===============================================


USE sakila;

CREATE TABLE string_tbl
 (char_fld CHAR(30),
 vchar_fld VARCHAR(30),
 text_fld TEXT
 );


-- ''''''''''''
-- STRING DATA:
-- ''''''''''''


INSERT INTO string_tbl (char_fld, vchar_fld, text_fld)
VALUES ('This is char data', 'This is varchar data', 'This is text data');

SELECT char_fld, vchar_fld, text_fld
FROM string_tbl;

-- SQL necessitates concatenation of strings with '...' + '...'

DELETE FROM string_tbl;

INSERT INTO string_tbl (char_fld, vchar_fld, text_fld)
VALUES ('This string is 28 characters', 'This string is 28 characters', 'This string is 28 characters');


SELECT LENGTH()(char_fld) AS char_length,
LENGTH(vchar_fld) varchar_length,
LENGTH(text_fld) text_length
FROM string_tbl;


SELECT POSITION('CHARACTERS' IN vchar_fld) AS position 
FROM string_tbl; -- not case sensitive and 0 = not found

-- LOCATE is a similar function but allows for the search to start at another SAVEPOINT


DELETE FROM string_tbl;

INSERT INTO string_tbl(vchar_fld)
VALUES ('abcd'), ('xyz'), ('QRSTUV'), ('qrstuv'), ('12345');

SELECT vchar_fld
FROM string_tbl
ORDER BY vchar_fld;

SELECT name, name LIKE '%y' AS ends_in_y
FROM category -- LIKE returns T/F
WHERE name LIKE '%y' = 1; -- which is the same as 0/1


SELECT concat(first_name, ' ', last_name, -- CONCAT:
' has been a customer since ', date(create_date)) AS customer_summary
FROM customer;



SELECT INSERT('goodbye world', 9, 0, 'cruel ') string;
--     INSERT(original str, start pos, #chars to replace, str to add)




-- ''''''''''''''''''''''''''
-- NUMERIC AND TEMPORAL DATA
-- ''''''''''''''''''''''''''


SELECT POW(2,3) - MOD(4,3);

SELECT CEIL(75.017), FLOOR(75.017), ROUND(75.017, 2), TRUNCATE(75.017, 2);


SELECT UTC_TIME();

SELECT CAST('2019-09-17 15:30:00' AS DATETIME);

SELECT HOUR(CAST('2019-09-17 15:30:00' AS DATETIME)) AS h,
       DATE_FORMAT(CAST('2019-09-17 15:30:00' AS DATETIME), '%Y-%m-%d %H:%i:%s') AS full_dt;

SELECT CAST('2019-09-17 15:30:00' AS TIME) AS time,
    CAST('2019-09-17 15:30:00' AS DATE) as date;

 SELECT STR_TO_DATE('September 17, 2019', '%M %d, %Y'),
    DAYNAME(STR_TO_DATE('September 17, 2019', '%M %d, %Y'));
    -- Here: '%M' is a str month, '%d' a numeric day and '%Y' a 4-digit year

SELECT EXTRACT(MONTH FROM '2019-09-18 22:19:05');














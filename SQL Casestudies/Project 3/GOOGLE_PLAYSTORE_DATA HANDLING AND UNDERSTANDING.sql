CREATE DATABASE IF NOT EXISTS PROJECT3;
USE PROJECT3;

-- All the data is not imported, so we will prepare the schema for infile data loading
TRUNCATE TABLE PLAYSTORE;

-- LOADING INFILE
LOAD DATA INFILE "C:/SQL Works/Project 3/PLAYSTORE.CSV"
INTO TABLE PLAYSTORE
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- AND DONE!
SELECT * FROM PLAYSTORE;

/*You're working as a market analyst for a mobile app development company. 
Your task is to identify the most promising categories (TOP 5) for launching 
new free apps based on their average ratings.*/

SELECT CATEGORY
FROM PLAYSTORE
WHERE PRICE = 0
GROUP BY CATEGORY
ORDER BY AVG(RATING) DESC
LIMIT 5;

/*As a business strategist for a mobile app company, your objective is to pinpoint 
the three categories that generate the most revenue from paid apps.This calculation 
is based on the product of the app price and its number of installations.*/

SELECT CATEGORY, AVG(REVENUE)
FROM
	(SELECT CATEGORY, (INSTALLS*PRICE) AS 'REVENUE'
	FROM PLAYSTORE
	WHERE TYPE = 'PAID')T
GROUP BY CATEGORY
ORDER BY AVG(REVENUE) DESC
LIMIT 3;

/*As a data analyst for a gaming company, you're tasked with calculating the percentage of apps within each category.
This information will help the company understand the distribution of gaming apps across different categories.*/

SET @TOTALAPPS = (SELECT COUNT(*) FROM PLAYSTORE);

SELECT CATEGORY, ROUND(((CNT/@TOTALAPPS)*100),2) AS 'PERCENT'
FROM
	(SELECT CATEGORY, COUNT(*) AS 'CNT'
	FROM PLAYSTORE
	GROUP BY CATEGORY)T;


/*As a data analyst at a mobile app-focused market research firm you’ll recommend whether the 
company should develop paid or free apps for each category based on the ratings of that category.*/
SELECT CATEGORY, TYPE FROM
(
	SELECT *, DENSE_RANK() OVER (PARTITION BY CATEGORY ORDER BY AVG_RATING DESC) AS NUM  
	FROM
		(SELECT CATEGORY,TYPE,AVG(RATING) AS 'AVG_RATING'
		FROM PLAYSTORE
		GROUP BY CATEGORY, TYPE)T
)M
WHERE NUM = 1;

/*Suppose you're a database administrator your databases have been hacked and hackers are changing price of certain apps on 
the database, it is taking long for IT team to neutralize the hack, however you as a responsible manager don’t want your data 
to be changed, do some measure where the changes in price can be recorded as you can’t stop hackers from making changes*/

-- I WILL BE USING TRIGGERS, WHICH WILL GET TRIGGERED ONCE THE DATABASE HAS BEEN UPDATED/DELETED!

-- TO STORE THE CHANGES, I AM CREATING A NEW TABLE.
CREATE TABLE PRICE_CHANGELOG
(
	APP_NAME VARCHAR(255),
    OLD_PRICE DECIMAL(10,2),
    NEW_PRICE DECIMAL(10,2),
    OPERATION VARCHAR(30),
    OP_TIME TIMESTAMP
);

DELIMITER //
CREATE TRIGGER PRICE_CHANGE_WATCHER
AFTER UPDATE -- HERE IT CAN BE DELETE/WRITE ANYTHING!
ON PLAYSTORE
FOR EACH ROW
BEGIN
	INSERT INTO PRICE_CHANGELOG (APP_NAME, OLD_PRICE, NEW_PRICE, OPERATION, OP_TIME)
    VALUES(NEW.APP, OLD.PRICE, NEW.PRICE,'UPDATE',CURRENT_TIMESTAMP);
END;
// DELIMITER ;


/*Your IT team have neutralized the threat; however, hackers have made some changes in the prices, 
but because of your measure you have noted the changes, now you want correct data to be inserted 
into the database again.*/

-- WE ARE REVERSING THE CHANGES. 

-- STEP 1 : GETTNG THE ROWS THAT HAVE BEEN COMPROMISED
SELECT * 
FROM PLAYSTORE AS A
INNER JOIN
PRICE_CHANGELOG AS B
ON A.APP = B.APP_NAME;

-- STEP 2 : UPDATING THE VALUES WITH THEIR ORIGINAL VALUES
 
DROP TRIGGER PRICE_CHANGE_WATCHER;

UPDATE PLAYSTORE AS A
INNER JOIN
PRICE_CHANGELOG AS B
ON A.APP = B.APP_NAME
SET A.PRICE = B.OLD_PRICE;


/*As a data person you are assigned the task of investigating the correlation between 
two numeric factors: app ratings and the quantity of reviews.*/

SET @X_MEAN = (SELECT AVG(RATING) FROM PLAYSTORE);
SET @Y_MEAN = (SELECT AVG(REVIEWS) FROM PLAYSTORE);

WITH T AS (
SELECT 
RATING AS X, 
REVIEWS AS Y,
ROUND(RATING-@X_MEAN,2) AS 'RAT',
ROUND(REVIEWS-@Y_MEAN,2) AS 'REV',
ROUND((RATING-@X_MEAN)*(RATING-@X_MEAN),2) AS 'SQRX',
ROUND((REVIEWS-@Y_MEAN)*(REVIEWS-@Y_MEAN),2) AS 'SQRY'
FROM PLAYSTORE
)

SELECT @NUMER := SUM(RAT*REV),
	   @DENOM1 := SUM(SQRX),
       @DENOM2 := SUM(SQRY)
FROM T;

SELECT (@NUMER/SQRT(@DENOM1*@DENOM2)) AS 'CORR_COEFF';

/*Your boss noticed  that some rows in genres columns have multiple genres in them, 
which was creating issue when developing the  recommender system from the data he/she 
assigned you the task to clean the genres column and make two genres out of it, rows that 
have only one genre will have other column as blank.*/

DELIMITER // 
CREATE FUNCTION F_NAME(A VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
	SET @INDEX_OF_SEMIC = LOCATE(';',A); -- IT LOCATES THE SPECIFIED CHARACTER
    SET @FIRST_GENRE = IF(@INDEX_OF_SEMIC > 0, LEFT(A,@INDEX_OF_SEMIC-1),A); -- IF ( COND : TRUE , FALSE )
    RETURN @FIRST_GENRE;
END;
// DELIMITER

DELIMITER // 
CREATE FUNCTION L_NAME(A VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
	SET @INDEX_OF_SEMIC = LOCATE(';',A); -- IT LOCATES THE SPECIFIED CHARACTER
    SET @LAST_GENRE = IF(@INDEX_OF_SEMIC = 0, '', SUBSTRING(A,@INDEX_OF_SEMIC+1,LENGTH(A))); -- IF ( COND : TRUE , FALSE )
    RETURN @LAST_GENRE;
END;
// DELIMITER

SELECT GENRES, F_NAME(GENRES) AS 'F', L_NAME(GENRES) AS 'K'
FROM PLAYSTORE;

-- THAT'S ALL FOLKS


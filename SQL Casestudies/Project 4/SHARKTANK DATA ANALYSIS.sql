CREATE DATABASE IF NOT EXISTS PROJECT4;
USE PROJECT4;

-- IMPORTED THE DATA, BUT ONLY ABOUT 350 ROWS WERE IMPORTED! SO FETCHING THE DATA USING INFILE METHOD
TRUNCATE TABLE SHARKTANK;

LOAD DATA INFILE "C:/SQL Works/Project 4/SHARKTANK.CSV"
INTO TABLE SHARKTANK
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM SHARKTANK;

/*You Team must promote shark Tank India season 4, The senior come up with the idea to show 
highest funding domain wise so that new startups can be attracted, and you were assigned the 
task to show the same.*/

SELECT INDUSTRY, MAX(TOTAL_DEAL_AMOUNT_IN_LAKHS)
FROM SHARKTANK
GROUP BY INDUSTRY;

/*You have been assigned the role of finding the domain where female as pitchers have 
female to male pitcher ratio >70%*/

SELECT INDUSTRY, (FEMALE_PRESENTERS/ALL_MF_PRESENTER)*100 AS 'RATIO'
FROM
(SELECT INDUSTRY, FEMALE_PRESENTERS, (MALE_PRESENTERS+FEMALE_PRESENTERS) AS 'ALL_MF_PRESENTER' FROM SHARKTANK)T
HAVING RATIO > 70;

/*You are working at marketing firm of Shark Tank India, you have got the task to 
determine volume of per season sale pitch made, pitches who received offer and pitches 
that were converted. Also show the percentage of pitches converted and percentage of 
pitches entertained.*/

SELECT J.SEASON_NUMBER,NUM_PITCHES,RECEIVED_OFFER,ACCEPTED_OFFER,(ACCEPTED_OFFER/NUM_PITCHES) AS CONVERTED_PITCHES,(RECEIVED_OFFER/NUM_PITCHES) AS ENTERTAINED_PITCHES FROM
(SELECT SEASON_NUMBER,COUNT(*) AS NUM_PITCHES
FROM SHARKTANK
GROUP BY SEASON_NUMBER) J
INNER JOIN
(SELECT A.SEASON_NUMBER,RECEIVED_OFFER,ACCEPTED_OFFER FROM
(SELECT SEASON_NUMBER, COUNT(*) AS RECEIVED_OFFER
FROM SHARKTANK
WHERE RECEIVED_OFFER = 'YES'
GROUP BY SEASON_NUMBER)A
INNER JOIN
(SELECT SEASON_NUMBER, COUNT(*) AS ACCEPTED_OFFER
FROM SHARKTANK
WHERE ACCEPTED_OFFER = 'YES'
GROUP BY SEASON_NUMBER)B
ON A.SEASON_NUMBER = B.SEASON_NUMBER)K
ON J.SEASON_NUMBER = K.SEASON_NUMBER;

/*As a venture capital firm specializing in investing in startups featured on a renowned entrepreneurship TV show, 
you are determining the season with the highest average monthly sales and identify the top 5 industries with the 
highest average monthly sales during that season to optimize investment decisions?*/

SET @SEASON_WITH_MAXMON_SALE = (SELECT SEASON_NUMBER
FROM
(SELECT SEASON_NUMBER,AVG(MONTHLY_SALES_IN_LAKHS) AS AVG_MON_SALE
FROM SHARKTANK
GROUP BY SEASON_NUMBER)A
ORDER BY AVG_MON_SALE DESC
LIMIT 1);

SELECT INDUSTRY, AVG(MONTHLY_SALES_IN_LAKHS) AS AVG_SALES_BY_MONTH
FROM SHARKTANK
WHERE SEASON_NUMBER = @SEASON_WITH_MAXMON_SALE
GROUP BY INDUSTRY
ORDER BY AVG_SALES_BY_MONTH DESC
LIMIT 5;

/*As a data scientist at our firm, your role involves solving real-world challenges like identifying industries 
with consistent increases in funds raised over multiple seasons. This requires focusing on industries where data
 is available across all three seasons. Once these industries are pinpointed, your task is to delve into the specifics,
 analyzing the number of pitches made, offers received, and offers converted per season within each industry.*/
 
 WITH VALID AS 
 (
 SELECT INDUSTRY,
 MAX(CASE WHEN SEASON_NUMBER =1 THEN TOTAL_DEAL_AMOUNT_IN_LAKHS END) AS S1,
 MAX(CASE WHEN SEASON_NUMBER =2 THEN TOTAL_DEAL_AMOUNT_IN_LAKHS END) AS S2, 
 MAX(CASE WHEN SEASON_NUMBER =3 THEN TOTAL_DEAL_AMOUNT_IN_LAKHS END) AS S3
 FROM SHARKTANK
 GROUP BY INDUSTRY
 HAVING S3 > S2
 AND S2 > S1
 AND S1 != 0 )
 

SELECT S.SEASON_NUMBER,
A.INDUSTRY, 
COUNT(S.STARTUP_NAME) AS 'TOTAL',
COUNT(CASE WHEN S.RECEIVED_OFFER = 'YES' THEN S.STARTUP_NAME END) AS 'RECEIVED_OFFER',
COUNT(CASE WHEN S.ACCEPTED_OFFER = 'YES' THEN S.STARTUP_NAME END) AS 'ACCEPTED_OFFER'
FROM VALID AS A
INNER JOIN 
SHARKTANK AS S
ON A.INDUSTRY = S.INDUSTRY
GROUP BY S.SEASON_NUMBER, A.INDUSTRY;
 

/*Every shark wants to know in how much year their investment will be returned, 
so you must create a system for them, where shark will enter the name of the startup’s 
and the based on the total deal and equity given in how many years their principal 
amount will be returned and make their investment decisions.*/

delimiter //
create procedure TOT( in startup varchar(100))
begin
   case 
      when (select Accepted_offer ='No' from sharktank where startup_name = startup)
	        then  select 'Turn Over time cannot be calculated';
	 when (select Accepted_offer ='yes' and Yearly_Revenue_in_lakhs = 'Not Mentioned' from sharktank where startup_name= startup)
           then select 'Previous data is not available';
	 else
         select `startup_name`,`Yearly_Revenue_in_lakhs`,`Total_Deal_Amount_in_lakhs`,`Total_Deal_Equity`, 
         `Total_Deal_Amount_in_lakhs`/((`Total_Deal_Equity`/100)*`Total_Deal_Amount_in_lakhs`) as 'years'
		 from sharktank where Startup_Name= startup;
    end case;
end
//
DELIMITER ;

call tot('BUMMER');


/*In the world of startup investing, we're curious to know which big-name investor, 
often referred to as "sharks," tends to put the most money into each deal on average. 
This comparison helps us see who's the most generous with their investments and how they 
measure up against their fellow investors.*/
SELECT SHARKNAME, AVG(INVESTMENT) FROM
(
	(SELECT `Namita_Investment_Amount_in_lakhs` AS INVESTMENT,
	'NAMITA' AS SHARKNAME
	FROM SHARKTANK
	WHERE `Namita_Investment_Amount_in_lakhs` > 0)
	UNION ALL
	(SELECT `Aman_Investment_Amount_in_lakhs` AS INVESTMENT,
	'AMAN' AS SHARKNAME
	FROM SHARKTANK
	WHERE `Aman_Investment_Amount_in_lakhs` > 0)
	UNION ALL
	(SELECT `Anupam_Investment_Amount_in_lakhs` AS INVESTMENT,
	'ANUPAM' AS SHARKNAME
	FROM SHARKTANK
	WHERE `Anupam_Investment_Amount_in_lakhs` > 0)
	UNION ALL
	(SELECT `Vineeta_Investment_Amount_in_lakhs` AS INVESTMENT,
	'VINITA' AS SHARKNAME
	FROM SHARKTANK
	WHERE `Vineeta_Investment_Amount_in_lakhs` > 0)
 )K
 GROUP BY SHARKNAME
 ORDER BY AVG(INVESTMENT) DESC
 LIMIT 1;
 
 
 
 /*Develop a stored procedure that accepts inputs for the season number and the name of a shark. 
 The procedure will then provide detailed insights into the total investment made by that specific 
 shark across different industries during the specified season. Additionally, it will calculate the 
 percentage of their investment in each sector relative to the total investment in that year, giving
 a comprehensive understanding of the shark's investment distribution and impact.*/
 
DELIMITER //
CREATE PROCEDURE GETDETAILS (IN SEASON INT, IN SHARKNAME VARCHAR(100))
BEGIN
	CASE
		WHEN SHARKNAME = 'NAMITA'
        THEN
        SELECT INDUSTRY, SUM(Namita_Investment_Amount_in_lakhs) AS TOTAL_INVESTED
        FROM SHARKTANK
        WHERE SEASON_NUMBER = SEASON
        AND Namita_Investment_Amount_in_lakhs>0
        GROUP BY INDUSTRY;
        WHEN SHARKNAME = 'VINEETA'
        THEN
        SELECT INDUSTRY, SUM(Vineeta_Investment_Amount_in_lakhs) AS TOTAL_INVESTED
        FROM SHARKTANK
        WHERE SEASON_NUMBER = SEASON
        AND Vineeta_Investment_Amount_in_lakhs>0
        GROUP BY INDUSTRY;
        WHEN SHARKNAME = 'AMAN'
        THEN
        SELECT INDUSTRY, SUM(Aman_Investment_Amount_in_lakhs) AS TOTAL_INVESTED
        FROM SHARKTANK
        WHERE SEASON_NUMBER = SEASON
        AND Aman_Investment_Amount_in_lakhs>0
        GROUP BY INDUSTRY;
        WHEN SHARKNAME = 'ASHNEER'
        THEN
        SELECT INDUSTRY, SUM(Ashneer_Investment_Amount_in_lakhs) AS TOTAL_INVESTED
        FROM SHARKTANK
        WHERE SEASON_NUMBER = SEASON
        AND Ashneer_Investment_Amount_in_lakhs>0
        GROUP BY INDUSTRY;
        ELSE
        SELECT 'INVALID SHARKNAME';
	END CASE;
 END
// 
DELIMITER ;

CALL GETDETAILS(1, 'AMAN');
 
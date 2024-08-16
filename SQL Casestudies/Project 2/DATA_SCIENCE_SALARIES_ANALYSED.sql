CREATE DATABASE IF NOT EXISTS PROJECT2;
USE PROJECT2;

-- DATASCIENCE JOB SALARIES CASE STUDY

SELECT * FROM SALARIES;
/*1. You're a Compensation analyst employed by a multinational corporation. 
Your Assignment is to Pinpoint Countries who give work fully remotely, 
for the title 'managers’ Paying salaries Exceeding $90,000 USD*/ 

SELECT DISTINCT COMPANY_LOCATION
FROM SALARIES
WHERE JOB_TITLE LIKE '%MANAGER%'
AND REMOTE_RATIO = 100
AND SALARY_IN_USD > 90000;

/*AS a remote work advocate Working for a progressive HR tech startup who place their freshers’ clients IN large tech firms.
 you're tasked WITH Identifying top 5 Country Having greatest count of large 
 (company size) number of companies.*/
 
 SELECT COMPANY_LOCATION, COUNT(COMPANY_SIZE) AS NUM_LARGE_COMPANIES
 FROM SALARIES
 WHERE COMPANY_SIZE = 'L'
 AND EXPERIENCE_LEVEL = 'EN'
 GROUP BY COMPANY_LOCATION
 ORDER BY NUM_LARGE_COMPANIES DESC
 LIMIT 5;
 
 /*Picture yourself AS a data scientist Working for a workforce management platform. 
 Your objective is to calculate the percentage of employees. Who enjoy fully remote roles WITH salaries 
 Exceeding $100,000 USD,Shedding light ON the attractiveness of high-paying 
 remote positions IN today's job market*/
 
SET @COUNT_REMOTE_WORKERS = (SELECT COUNT(REMOTE_RATIO) FROM SALARIES WHERE SALARY_IN_USD > 100000 AND REMOTE_RATIO = 100);
SET @ALL_WORKERS = (SELECT COUNT(*) FROM SALARIES);
SET @PERCENT = ROUND(((SELECT @COUNT_REMOTE_WORKERS)/(SELECT @ALL_WORKERS))*100);
SELECT @PERCENT AS 'PERCENTAGE';

/*Imagine you're a data analyst Working for a global recruitment agency. 
Your Task is to identify the Locations where entry-level average salaries exceed 
the average salary for that job title IN market for entry level, 
helping your agency guide candidates towards lucrative opportunities.
*/
SELECT COMPANY_LOCATION, T.JOB_TITLE, AVG_SALARY
FROM
(SELECT JOB_TITLE, AVG(SALARY_IN_USD) AS "AVG_SALARY_BY_JOB"
FROM SALARIES
GROUP BY JOB_TITLE)T
INNER JOIN
(SELECT JOB_TITLE, COMPANY_LOCATION, AVG(SALARY_IN_USD) AS "AVG_SALARY"
FROM SALARIES
GROUP BY JOB_TITLE, COMPANY_LOCATION)M
ON T.JOB_TITLE = M.JOB_TITLE WHERE AVG_SALARY > AVG_SALARY_BY_JOB;


/*You've been hired by a big HR Consultancy to look at how much people get paid IN different Countries. 
Your job is to Find out for each job title which. 
Country pays the maximum average salary. 
This helps you to place your candidates IN those countries*/
SELECT COMPANY_LOCATION, JOB_TITLE FROM(
SELECT *, DENSE_RANK() OVER (PARTITION BY JOB_TITLE ORDER BY AVERAGE DESC) AS NUM FROM
(SELECT JOB_TITLE, AVG(SALARY_IN_USD) AS 'AVERAGE', COMPANY_LOCATION
FROM SALARIES
GROUP BY JOB_TITLE, COMPANY_LOCATION)T
)M WHERE NUM = 1;

/*AS a data-driven Business consultant, you've been hired by a multinational corporation to analyze salary trends across different company Locations. 
Your goal is to Pinpoint Locations WHERE the average salary Has consistently Increased over the Past few years (Countries WHERE data is available for 
3 years Only(present year and past two years) providing Insights into Locations experiencing Sustained salary growth.*/
WITH MYINTEREST AS(
	SELECT * FROM SALARIES 
	WHERE COMPANY_LOCATION 
	IN
	(
	SELECT COMPANY_LOCATION FROM
	(SELECT COMPANY_LOCATION, COUNT(DISTINCT WORK_YEAR) AS 'CNT'
	FROM SALARIES
	WHERE WORK_YEAR >= YEAR(CURRENT_DATE())-2
	GROUP BY COMPANY_LOCATION
	HAVING CNT = 3
	)T
	)
)
-- HERE, THE TABLE IS HAVING DATA WHERE FOR A COMPANY LOCATION THERE IS PAST 3 YEARS OF DATA AVAILABLE.
-- SELECT * FROM MYINTEREST;

/*SELECT WORK_YEAR, COMPANY_LOCATION, AVG(SALARY_IN_USD)
FROM MYINTEREST
GROUP BY WORK_YEAR, COMPANY_LOCATION; */

SELECT 
    COMPANY_LOCATION,
    MAX(CASE WHEN work_year = 2022 THEN  average END) AS AVG_salary_2022,
    MAX(CASE WHEN work_year = 2023 THEN average END) AS AVG_salary_2023,
    MAX(CASE WHEN work_year = 2024 THEN average END) AS AVG_salary_2024
FROM 
(
SELECT COMPANY_LOCATION, work_year, AVG(salary_IN_usd) AS average FROM  MYINTEREST GROUP BY company_locatiON, work_year 
)q GROUP BY company_locatiON  HAVING AVG_salary_2024 > AVG_salary_2023 AND AVG_salary_2023 > AVG_salary_2022;

/*Picture yourself AS a workforce strategist employed by a global HR tech startup. 
Your Mission is to Determine the percentage of fully remote work for each experience level 
IN 2021 and compare it WITH the corresponding figures for 2024, Highlighting any significant 
Increases or decreases IN remote work Adoption over the years*/

SELECT 
    J.EXPERIENCE_LEVEL, 
    J.PERCENT_2021, 
    K.PERCENT_2024
FROM 
    (SELECT 
        T.EXPERIENCE_LEVEL,
        ((M.CNT/T.CNT)*100) AS PERCENT_2021
    FROM
        (SELECT EXPERIENCE_LEVEL, COUNT(*) AS CNT
        FROM SALARIES
        WHERE WORK_YEAR = 2021
        GROUP BY EXPERIENCE_LEVEL) T
    INNER JOIN
        (SELECT EXPERIENCE_LEVEL, COUNT(*) AS CNT
        FROM SALARIES
        WHERE REMOTE_RATIO = 100
        AND WORK_YEAR = 2021
        GROUP BY EXPERIENCE_LEVEL) M
    ON T.EXPERIENCE_LEVEL = M.EXPERIENCE_LEVEL) J
INNER JOIN
    (SELECT 
        T.EXPERIENCE_LEVEL,
        ((M.CNT/T.CNT)*100) AS PERCENT_2024
    FROM
        (SELECT EXPERIENCE_LEVEL, COUNT(*) AS CNT
        FROM SALARIES
        WHERE WORK_YEAR = 2024
        GROUP BY EXPERIENCE_LEVEL) T
    INNER JOIN
        (SELECT EXPERIENCE_LEVEL, COUNT(*) AS CNT
        FROM SALARIES
        WHERE REMOTE_RATIO = 100
        AND WORK_YEAR = 2024
        GROUP BY EXPERIENCE_LEVEL) M
    ON T.EXPERIENCE_LEVEL = M.EXPERIENCE_LEVEL) K
ON J.EXPERIENCE_LEVEL = K.EXPERIENCE_LEVEL;


/*AS a Compensation specialist at a Fortune 500 company, you're tasked WITH analyzing salary trends over time.
 Your objective is to calculate the average salary increase percentage for each experience level and job title 
 between the years 2023 and 2024, helping the company stay competitive IN the talent market.*/
 SELECT A.EXPERIENCE_LEVEL, ((AVG2024-AVG2023)/AVG2023)*100 AS 'INCREASE' 
 FROM
 (SELECT WORK_YEAR, EXPERIENCE_LEVEL, AVG(SALARY_IN_USD) AS "AVG2023"
 FROM SALARIES
 WHERE WORK_YEAR = 2023
 GROUP BY WORK_YEAR, EXPERIENCE_LEVEL)A
INNER JOIN
(SELECT WORK_YEAR, EXPERIENCE_LEVEL, AVG(SALARY_IN_USD) AS "AVG2024"
 FROM SALARIES
 WHERE WORK_YEAR = 2024
 GROUP BY WORK_YEAR, EXPERIENCE_LEVEL)B
ON A.EXPERIENCE_LEVEL = B.EXPERIENCE_LEVEL;

-- THAT'S ALL FOLKS.
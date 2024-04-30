-- SQL Project - Data Cleaning

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022

DROP TABLE IF EXISTS layoff;
------------------------------------------------------------------------------------
CREATE TABLE layoff (
	company text,
	location text,
	industry text,
	total_laid_off text,
	percentage_laid_off text,
	date text,
	stage text,
	country text,
	funds_raised_millions text
);
------------------------------------------------------------------------------------
-- DATE COULUMN HAS A NULL VALUES RECORD
--SELECT * FROM layoff where date = 'NULL'; 
------------------------------------------------------------------------------------
-- LETS CHANGE 'NULL' STRINGS TO NULL VALUES IN OUR COLUMNS WHERE WE HAVE NUMERIC VALUES;
-- we should set the blanks to nulls since those are typically easier to work with
UPDATE layoff
SET total_laid_off = null
WHERE total_laid_off = 'NULL';

UPDATE layoff
SET percentage_laid_off = null
WHERE percentage_laid_off = 'NULL';

UPDATE layoff
SET funds_raised_millions = null
WHERE funds_raised_millions = 'NULL';

UPDATE layoff
SET date = NULL
WHERE DATE = 'NULL';
------------------------------------------------------------------------------------
-- CHANGE DATA TYPE OF total_laid_off, percentage_laid_off, funds_raised_millions FROM TEXT TO INTEGER AND FLOAT 
-- AND CHANGE date COLUMN FROM TEXT TO DATE TYPE

ALTER TABLE layoff
ALTER COLUMN total_laid_off TYPE INTEGER
USING total_laid_off::INTEGER;

ALTER TABLE layoff
ALTER COLUMN percentage_laid_off TYPE FLOAT
USING percentage_laid_off::FLOAT;

ALTER TABLE layoff
ALTER COLUMN funds_raised_millions TYPE FLOAT
USING funds_raised_millions::FLOAT;

ALTER TABLE layoff
ALTER COLUMN date TYPE DATE
USING date::DATE;

SELECT * FROM layoff;
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- ***DATA CLEANING 
-- CREATE COPY OF ORIGINAL TABLE (BACKUP TABLE)

CREATE TABLE layoffs_staging (LIKE layoff INCLUDING ALL);

INSERT INTO layoffs_staging
SELECT * FROM layoff;

-- OTHER WAY
CREATE TABLE layoffs_staging AS
SELECT * FROM layoff;
------------------------------------------------------------------------------------

-- REMOVING DUPLICATES (WHEN WE DONT HAVE UNIQUE INDENTIFIER)
-- these are the ones we want to delete where the row number is > 1 or 2or greater essentially

select * , ctid
from layoffs_staging
-- SOLUTION 1: ONLY WORKS IN POSTGRESQL(CTID) AND ORACLE(ROWID)
delete from layoffs_staging 
where ctid in (select max(ctid)
			   from layoffs_staging
			   group by company, location, industry, total_laid_off, 
			   percentage_laid_off, date, stage, country, funds_raised_millions
			   having count(*) > 1)
------------------------------------------------------------------------------------
-- SOLUTION 2: FOR EVERY RDBMS, BY CREATING UNIQUE IDENTIFIER COLUMN
-- this solution, which I think is a good one. Is to create a new column and add those row numbers in. 
-- Then delete where row numbers are over 2, then delete that column so let's do it!!

ALTER TABLE layoffs_staging ADD COLUMN row_num INT GENERATED ALWAYS AS IDENTITY;

DELETE FROM layoffs_staging 
WHERE row_num IN (SELECT MAX(row_num)
				  FROM layoffs_staging
				  GROUP BY company, location, industry, total_laid_off, 
				  percentage_laid_off, date, stage, country, funds_raised_millions
				  HAVING COUNT(*) > 1);

ALTER TABLE layoffs_staging DROP COLUMN row_num;

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- *** STANDARDIZING DATA
-- DELETE WHITE SPACES
SELECT COMPANY,TRIM(COMPANY) 
FROM layoffs_staging;

UPDATE layoffs_staging
SET COMPANY = TRIM(COMPANY);
------------------------------------------------------------------------------------

-- UPDATE INDUSTRY COLUMN 
SELECT *
FROM layoffs_staging
WHERE INDUSTRY LIKE 'Crypto%';

UPDATE layoffs_staging
SET INDUSTRY = 'Crypto'
WHERE INDUSTRY LIKE 'Crypto%';
------------------------------------------------------------------------------------

-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. 
-- Let's standardize this.
-- REMOVE UNUSUAL PUNCTUATION
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging;

UPDATE layoffs_staging
SET COUNTRY = TRIM(TRAILING '.' FROM country)
WHERE COUNTRY LIKE 'United States%';

-- now if we run this again it is fixed
SELECT DISTINCT country
FROM layoffs_staging
ORDER BY country;

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--** DEALING WITH NULL AND BLANCK VALUES 

SELECT *
FROM layoffs_staging
WHERE industry IS NULL OR industry = 'NULL';

SELECT * 
FROM layoffs_staging
WHERE company = 'Airbnb';

-- we should set the blanks to nulls since those are typically easier to work with

UPDATE layoffs_staging
SET industry = NULL
WHERE industry = 'NULL';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all

-- CHECKING VALUES BY JOINING TABLE TO ITSELF 
SELECT * 
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company 
	AND t1.location = t2.location
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- now we need to populate those nulls if possible
-- UPDATE TABLE 
UPDATE layoffs_staging t1
SET industry = t2.industry
FROM layoffs_staging t2
WHERE t1.company = t2.company 
    AND t1.location = t2.location
    AND t1.industry IS NULL 
    AND t2.industry IS NOT NULL;

-- DELETE ROWS WITH NULL VALUES IN BOTH percentage_laid_off AND total_laid_off COLUMNS
SELECT * 
FROM layoffs_staging
WHERE percentage_laid_off IS NULL AND total_laid_off IS NULL;

DELETE 
FROM layoffs_staging
WHERE percentage_laid_off IS NULL AND total_laid_off IS NULL;


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- ***EXPORATORY DATA ANALYSIS (EDA)

-- Here we are jsut going to explore the data and find trends or patterns or anything interesting like outliers

-- normally when you start the EDA process you have some idea of what you're looking for

-- with this info we are just going to look around and see what we find!


-- Which companies had 1 which is basically 100 percent of they company laid off
SELECT * 
FROM layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC NULLS LAST;
-- these are mostly startups it looks like who all went out of business during this time



-- Companies with the most Total Layoffs

SELECT 
	country, company, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY country, company
ORDER BY 3 DESC NULLS LAST;


-- TOTAL LAYOFFS BY INDUSTRY
SELECT 
	industry, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY industry
ORDER BY 2 DESC NULLS LAST;

-- TOTAL LAYOFFS BY COUNTRY
SELECT 
	country, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY country
ORDER BY 2 DESC NULLS LAST;

-- TOTAL LAYOFFS BY STAGE
SELECT 
	stage, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY stage
ORDER BY 2 DESC NULLS LAST;


------------------------------------------------------------------------------------
-- DATASET DATE RANGE FOR TIMESERIES ANALYSIS
SELECT MIN(date), MAX(date)
FROM layoffs_staging;

-- concidering the fact that we have only 3 months of 2023 data in this dataset 
SELECT 
	EXTRACT(YEAR FROM date), SUM(total_laid_off)
FROM layoffs_staging
GROUP BY EXTRACT(YEAR FROM date)
ORDER BY 2 DESC NULLS LAST;


-- GROUPING DATA BY MONTH
SELECT 
	TO_CHAR(date, 'YYYY-MM') AS year_month, 
	SUM(total_laid_off)
FROM layoffs_staging
GROUP BY year_month
ORDER BY year_month;


-- ROLING TOTAL LAID OFF BY MONTH
WITH roling_total AS (
	SELECT 
		TO_CHAR(date, 'YYYY-MM') AS year_month, 
		SUM(total_laid_off) AS total_off
	FROM layoffs_staging
	GROUP BY year_month
	ORDER BY year_month
	)
SELECT 
	year_month, total_off,
	SUM(total_off) OVER(ORDER BY year_month) roling_total_off
FROM roling_total
WHERE year_month IS NOT NULL;

	
------------------------------------------------------------------------------------
-- -- Earlier we looked at Companies with the most Layoffs. Now let's look at that per year. It's a little more difficult.

WITH COMPANY_YEAR AS (
		SELECT 
			company, EXTRACT(YEAR FROM date) AS year,
			SUM(total_laid_off) AS total_off
		FROM layoffs_staging
		GROUP BY company, year
		ORDER BY 3 DESC NULLS LAST), 
		 COMPANY_YEAR_RANK AS (
		 	SELECT 
		 		*,
		 		DENSE_RANK() OVER(PARTITION BY year ORDER BY total_off DESC NULLS LAST) AS rnk
		 	FROM COMPANY_YEAR
		 	WHERE year IS NOT NULL)
SELECT * 
FROM COMPANY_YEAR_RANK
WHERE rnk <= 5;



-- The same but for industries

WITH INDUSTRY_YEAR AS (
		SELECT 
			industry, EXTRACT(YEAR FROM date) AS year,
			SUM(total_laid_off) AS total_off
		FROM layoffs_staging
		GROUP BY industry, year
		ORDER BY 3 DESC NULLS LAST), 
		 INDUSTRY_YEAR_RANK AS (
		 	SELECT 
		 		*,
		 		DENSE_RANK() OVER(PARTITION BY year ORDER BY total_off DESC NULLS LAST) AS rnk
		 	FROM INDUSTRY_YEAR
		 	WHERE year IS NOT NULL)
SELECT * 
FROM INDUSTRY_YEAR_RANK
WHERE rnk <= 5;































































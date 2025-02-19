--creating a staging table 
CREATE TABLE job_postings_staging (
    job_index VARCHAR PRIMARY KEY,
    job_title VARCHAR,
    salary_estimate VARCHAR,
    job_description VARCHAR,
    rating DECIMAL,
    company_name VARCHAR,
    location VARCHAR,
    headquarters VARCHAR,
    size VARCHAR,
    founded INT,
    type_of_owner VARCHAR,
    industry VARCHAR,
    sector VARCHAR,
    revenue VARCHAR,
    competitors VARCHAR
);

--inserting data from job_postings into job_postings_staging
INSERT INTO job_postings_staging
SELECT *
FROM job_postings;

--checking new staging table is set up 
SELECT *
FROM job_postings_staging;

--checking for duplicates
SELECT salary_estimate, 
    job_description, 
    location, 
    COUNT(*) 
FROM job_postings_staging
GROUP BY salary_estimate, job_description, location
HAVING COUNT(*) > 1;

--removing duplicates 
WITH CTE AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY salary_estimate, job_description, location 
        ORDER BY job_index ASC
    ) AS row_num
    FROM job_postings_staging
)
DELETE FROM job_postings_staging
WHERE job_index IN (SELECT job_index FROM CTE WHERE row_num > 1);

--fixing column data types 
ALTER TABLE job_postings_staging
ALTER COLUMN job_index TYPE INT 
USING job_index::INTEGER;

ALTER TABLE job_postings_staging
ALTER COLUMN job_index TYPE DECIMAL 
USING job_index::DECIMAL;

--fixing values in company_name to remove rating 
UPDATE job_postings_staging
SET company_name = REGEXP_REPLACE(company_name, '\s*\d+(\.\d+)?$', '')
WHERE company_name ~ '\s*\d+(\.\d+)?$';

--fixing job_title lower case
ALTER TABLE job_postings_staging
DROP CONSTRAINT job_postings_staging_pkey;

UPDATE job_postings_staging
SET job_title = INITCAP(job_title);

--job_title has similar names and I want to simplify for readability
SELECT DISTINCT job_title 
FROM job_postings_staging
ORDER BY job_title;

UPDATE job_postings_staging
SET job_title = 'Data Scientist'
WHERE job_title LIKE '%Data Scientist%' 
    OR job_title LIKE '%Data Science%';

UPDATE job_postings_staging
SET job_title = 'Machine Learning Engineer'
WHERE job_title LIKE '%Machine Learning%';

UPDATE job_postings_staging
SET job_title = 'Data Engineer'
WHERE job_title LIKE '%Engineer%';

UPDATE job_postings_staging
SET job_title = 'Data Analyst'
WHERE job_title LIKE '%Analy%';

--fixing -1 values 
UPDATE job_postings_staging
SET rating = NULL
WHERE rating = '-1';

UPDATE job_postings_staging
SET headquarters = NULL
WHERE headquarters = '-1';

UPDATE job_postings_staging
SET size = NULL
WHERE size = '-1' 
    OR size = 'Unknown';

UPDATE job_postings_staging
SET founded = NULL
WHERE founded = '-1';

UPDATE job_postings_staging
SET type_of_owner = NULL
WHERE type_of_owner = '-1' 
    OR type_of_owner = 'Unknown';

UPDATE job_postings_staging
SET industry = NULL
WHERE industry = '-1' 
    OR industry = 'Unknown';

UPDATE job_postings_staging
SET sector = NULL
WHERE sector = '-1';

UPDATE job_postings_staging
SET revenue = NULL
WHERE revenue = '-1' 
    OR revenue LIKE '%Unknown%';

UPDATE job_postings_staging
SET competitors = NULL
WHERE competitors = '-1';

--deleting rows with NULL key values
DELETE FROM job_postings_staging
WHERE rating IS NULL
    AND headquarters IS NULL
    AND industry IS NULL;

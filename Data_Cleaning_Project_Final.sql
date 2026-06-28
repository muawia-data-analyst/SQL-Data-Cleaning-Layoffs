-- ============================================
-- DATA CLEANING PROJECT
-- Dataset: Layoffs Dataset (layoffs_staging)
-- Steps: 1) Remove Duplicates
--        2) Standardize Data
--        3) Handle NULL / Blank Values
--        4) Remove Unnecessary Columns
-- ============================================


-- ============================================
-- STEP 1: REMOVE DUPLICATES
-- ============================================

-- Create a staging table with same structure as original
-- We NEVER touch the raw data directly
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Copy all raw data into staging table
INSERT layoffs_staging
SELECT * FROM layoffs;

-- Check the staging table
SELECT * FROM layoffs;

-- Identify duplicates using ROW_NUMBER()
-- Any row with ROW_NUM > 1 is a duplicate
WITH DUPLICATE_CTE AS
(
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY COMPANY, LOCATION, INDUSTRY, TOTAL_LAID_OFF,
        PERCENTAGE_LAID_OFF, `DATE`, STAGE, COUNTRY, FUNDS_RAISED_MILLIONS
    ) AS ROW_NUM
    FROM layoffs_staging
)
SELECT * FROM DUPLICATE_CTE
WHERE ROW_NUM > 1;

-- Create a second staging table with an extra ROW_NUM column
-- This allows us to delete duplicates (CTEs don't allow DELETE directly)
CREATE TABLE `layoffs_staging2` (
    `company` text,
    `location` text,
    `industry` text,
    `total_laid_off` int DEFAULT NULL,
    `percentage_laid_off` text,
    `date` text,
    `stage` text,
    `country` text,
    `funds_raised_millions` int DEFAULT NULL,
    ROW_NUM INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Verify staging2 is empty before inserting
SELECT * FROM layoffs_staging2;

-- Insert all data into staging2 with ROW_NUM column populated
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY COMPANY, LOCATION, INDUSTRY, TOTAL_LAID_OFF,
    PERCENTAGE_LAID_OFF, `DATE`, STAGE, COUNTRY, FUNDS_RAISED_MILLIONS
) AS ROW_NUM
FROM layoffs_staging;

-- Verify duplicates are correctly identified (ROW_NUM > 1)
SELECT * FROM layoffs_staging2
WHERE ROW_NUM > 1;

-- Delete all duplicate rows — keep only ROW_NUM = 1 (first occurrence)
DELETE FROM layoffs_staging2
WHERE ROW_NUM > 1;


-- ============================================
-- STEP 2: STANDARDIZE DATA
-- ============================================

-- Check company names for leading/trailing spaces
SELECT COMPANY, TRIM(COMPANY)
FROM layoffs_staging2;

-- Remove leading and trailing spaces from company names
UPDATE layoffs_staging2
SET COMPANY = TRIM(COMPANY);

-- Check industry values for inconsistencies
SELECT DISTINCT INDUSTRY
FROM layoffs_staging2
ORDER BY 1;

-- Found 'Crypto', 'Crypto Currency', 'CryptoCurrency' — all same industry
-- Standardize all variations to 'Crypto'
SELECT * FROM layoffs_staging2
WHERE INDUSTRY LIKE 'CRYPTO%';

UPDATE layoffs_staging2
SET INDUSTRY = 'Crypto'
WHERE INDUSTRY LIKE 'CRYPTO%';

-- Check country names for inconsistencies
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%';

-- Found 'United States.' with a trailing dot — need to clean it
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Remove trailing dot from country names
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Date column is stored as TEXT — need to convert to proper DATE format
-- STR_TO_DATE converts text 'MM/DD/YYYY' to MySQL DATE format
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Update date column with properly formatted dates
UPDATE layoffs_staging2
SET date = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change the column data type from TEXT to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- ============================================
-- STEP 3: HANDLE NULL AND BLANK VALUES
-- ============================================

-- Find rows where both total_laid_off AND percentage_laid_off are NULL
-- These rows have no useful layoff data at all
SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Set blank industry values to NULL so we can fill them using JOIN
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Check which rows still have NULL or blank industry
SELECT * FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Check if Airbnb has other rows with industry populated
-- (we can use those to fill the NULL rows)
SELECT * FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Self JOIN to find rows where same company has NULL industry
-- but another row of that company has industry filled in
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Fill NULL industry values using matching company rows
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Manually fix any remaining companies whose industry
-- could not be filled by the JOIN (no other matching row existed)
UPDATE layoffs_staging2
SET industry = 'Travel'
WHERE company = 'Airbnb';

UPDATE layoffs_staging2
SET industry = 'Transportation'
WHERE company = 'Carvana';

UPDATE layoffs_staging2
SET industry = 'Gaming'
WHERE company = "Bally's Interactive";

-- Delete rows where both layoff columns are NULL
-- These rows are useless for any analysis
SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


-- ============================================
-- STEP 4: REMOVE UNNECESSARY COLUMNS
-- ============================================

-- Drop the ROW_NUM column — it was only needed to find/delete duplicates
-- It has no analytical value
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final check — clean dataset ready for analysis
SELECT * FROM layoffs_staging2;

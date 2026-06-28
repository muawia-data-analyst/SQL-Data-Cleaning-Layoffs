# Data Cleaning Project — Layoffs Dataset (SQL)

## Overview
A full data cleaning project on a real-world dataset of global company layoffs (2020–2023), using MySQL. Raw data was full of duplicates, inconsistent text formatting, and missing values — this project takes it from messy to analysis-ready.

## Objective
To practice professional data cleaning workflow in SQL: working in staging tables (never touching raw data directly), removing duplicates safely, standardizing inconsistent values, and handling missing data logically.

## Tools Used
- **MySQL / MySQL Workbench**
- **CTEs (Common Table Expressions)**
- **Window Functions** — `ROW_NUMBER() OVER(PARTITION BY ...)`
- **Self JOINs** — to fill in missing values using matching records
- **String functions** — `TRIM`, `STR_TO_DATE`

## Cleaning Steps Performed

1. **Remove Duplicates**
   - Created a staging table to protect the original raw data
   - Used `ROW_NUMBER()` with `PARTITION BY` across all key columns to flag exact duplicate rows
   - Deleted rows where the row number was greater than 1

2. **Standardize Data**
   - Trimmed extra whitespace from company names
   - Standardized inconsistent industry labels (e.g. "Crypto", "CryptoCurrency" → "Crypto")
   - Removed trailing punctuation from country names (e.g. "United States." → "United States")
   - Converted the date column from text to a proper MySQL `DATE` type using `STR_TO_DATE`

3. **Handle NULL and Blank Values**
   - Identified rows with missing industry values
   - Used a self-JOIN on company name to fill in missing industry values from other rows of the same company
   - Manually resolved remaining edge cases where no match existed
   - Removed rows where both `total_laid_off` and `percentage_laid_off` were NULL (no usable data)

4. **Remove Unnecessary Columns**
   - Dropped the helper `row_num` column once duplicates were removed, since it had no analytical value

## Files in This Repository
- `Data_Cleaning_Project_Final.sql` — full commented SQL script, step by step

## How to Use
1. Import the original `layoffs` dataset into a MySQL database
2. Run this script top to bottom in MySQL Workbench
3. End result: a clean `layoffs_staging2` table ready for analysis (see my EDA project for the next step)

Part of my Data Analyst portfolio.

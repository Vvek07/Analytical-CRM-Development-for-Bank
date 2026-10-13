-- ⚠️  BEFORE RUNNING: Update the LOAD DATA LOCAL INFILE paths in Part A
--     to match the folder where you have saved the 7 source CSV files.
--     Default path used: C:/Users/vivek/Downloads/SQL_import_CSVs_Extracted/
--     MySQL version tested: 8.0+   |   Run Parts A → B → C → D → E in order.
-- -----------------------------------------------------------------------
-- Project by Vivek Ajay Patil
-- Analytical CRM Development for a Bank

-- =====================================================================
-- PART A : DATABASE, TABLES, KEYS AND DATA IMPORT
-- =====================================================================

CREATE DATABASE IF NOT EXISTS bank_churn_db;
USE bank_churn_db;

DROP TABLE IF EXISTS Bank_Churn_backup;
DROP TABLE IF EXISTS Bank_Churn;
DROP TABLE IF EXISTS CustomerInfo;
DROP TABLE IF EXISTS Gender;
DROP TABLE IF EXISTS Geography;
DROP TABLE IF EXISTS CreditCard;
DROP TABLE IF EXISTS ActiveCustomer;
DROP TABLE IF EXISTS ExitCustomer;

-- Lookup tables (one code -> one label)
CREATE TABLE Gender (
    GenderID        INT          NOT NULL,
    GenderCategory  VARCHAR(20)  NOT NULL,
    PRIMARY KEY (GenderID)
);

CREATE TABLE Geography (
    GeographyID        INT          NOT NULL,
    GeographyLocation  VARCHAR(30)  NOT NULL,
    PRIMARY KEY (GeographyID)
);

CREATE TABLE CreditCard (
    CreditID  INT          NOT NULL,
    Category  VARCHAR(30)  NOT NULL,
    PRIMARY KEY (CreditID)
);

CREATE TABLE ActiveCustomer (
    ActiveID        INT          NOT NULL,
    ActiveCategory  VARCHAR(20)  NOT NULL,
    PRIMARY KEY (ActiveID)
);

CREATE TABLE ExitCustomer (
    ExitID        INT          NOT NULL,
    ExitCategory  VARCHAR(20)  NOT NULL,
    PRIMARY KEY (ExitID)
);

-- Customer demographics (one row per customer)
CREATE TABLE CustomerInfo (
    CustomerId       INT            NOT NULL,
    Surname          VARCHAR(50)    NOT NULL,
    Age              INT            NOT NULL,
    GenderID         INT            NOT NULL,
    EstimatedSalary  DECIMAL(12,2)  NOT NULL,
    GeographyID      INT            NOT NULL,
    Bank_DOJ         DATE           NOT NULL,
    PRIMARY KEY (CustomerId),
    CONSTRAINT fk_cust_gender    FOREIGN KEY (GenderID)    REFERENCES Gender (GenderID),
    CONSTRAINT fk_cust_geography FOREIGN KEY (GeographyID) REFERENCES Geography (GeographyID)
);

-- Account details (one row per customer)
CREATE TABLE Bank_Churn (
    CustomerId      INT            NOT NULL,
    CreditScore     INT            NOT NULL,
    Tenure          INT            NOT NULL,
    Balance         DECIMAL(12,2)  NOT NULL,
    NumOfProducts   INT            NOT NULL,
    HasCrCard       INT            NOT NULL,
    IsActiveMember  INT            NOT NULL,
    Exited          INT            NOT NULL,
    PRIMARY KEY (CustomerId),
    CONSTRAINT fk_churn_customer FOREIGN KEY (CustomerId)     REFERENCES CustomerInfo (CustomerId),
    CONSTRAINT fk_churn_card     FOREIGN KEY (HasCrCard)      REFERENCES CreditCard (CreditID),
    CONSTRAINT fk_churn_active   FOREIGN KEY (IsActiveMember) REFERENCES ActiveCustomer (ActiveID),
    CONSTRAINT fk_churn_exit     FOREIGN KEY (Exited)         REFERENCES ExitCustomer (ExitID)
);

-- -- Data import (parents first, then children). Change the folder if your CSVs are elsewhere.
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 'ON';

LOAD DATA LOCAL INFILE 'C:/Users/vivek/Downloads/SQL_import_CSVs_Extracted/Gender.csv'
INTO TABLE Gender
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(GenderID, GenderCategory);

LOAD DATA LOCAL INFILE 'C:/Users/vivek/Downloads/SQL_import_CSVs_Extracted/Geography.csv'
INTO TABLE Geography
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(GeographyID, GeographyLocation);

LOAD DATA LOCAL INFILE 'C:/Users/vivek/Downloads/SQL_import_CSVs_Extracted/CreditCard.csv'
INTO TABLE CreditCard
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(CreditID, Category);

LOAD DATA LOCAL INFILE 'C:/Users/vivek/Downloads/SQL_import_CSVs_Extracted/ActiveCustomer.csv'
INTO TABLE ActiveCustomer
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ActiveID, ActiveCategory);

LOAD DATA LOCAL INFILE 'C:/Users/vivek/Downloads/SQL_import_CSVs_Extracted/ExitCustomer.csv'
INTO TABLE ExitCustomer
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ExitID, ExitCategory);

LOAD DATA LOCAL INFILE 'C:/Users/vivek/Downloads/SQL_import_CSVs_Extracted/CustomerInfo.csv'
INTO TABLE CustomerInfo
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(CustomerId, Surname, Age, GenderID, EstimatedSalary, GeographyID, Bank_DOJ);

LOAD DATA LOCAL INFILE 'C:/Users/vivek/Downloads/SQL_import_CSVs_Extracted/Bank_Churn.csv'
INTO TABLE Bank_Churn
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(CustomerId, CreditScore, Tenure, Balance, NumOfProducts, HasCrCard, IsActiveMember, Exited);

-- -- Row counts after import (10000 / 10000 / 2 / 3 / 2 / 2 / 2)
SELECT 'Bank_Churn'     AS table_name, COUNT(*) AS row_count FROM Bank_Churn
UNION ALL SELECT 'CustomerInfo',   COUNT(*) FROM CustomerInfo
UNION ALL SELECT 'Gender',         COUNT(*) FROM Gender
UNION ALL SELECT 'Geography',      COUNT(*) FROM Geography
UNION ALL SELECT 'CreditCard',     COUNT(*) FROM CreditCard
UNION ALL SELECT 'ActiveCustomer', COUNT(*) FROM ActiveCustomer
UNION ALL SELECT 'ExitCustomer',   COUNT(*) FROM ExitCustomer;


-- =====================================================================
-- PART B : DATA CHECKS AND CLEANING
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q14 (Objective, SQL support) : How many tables are in the dataset, and
--      which table has only categorical columns?
-- Logic : information_schema lists every table and column of the database.
--         Run before the backup table below is created.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS Total_Tables
FROM information_schema.tables
WHERE table_schema = 'bank_churn_db'
  AND table_type = 'BASE TABLE';

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'bank_churn_db'
ORDER BY table_name, ordinal_position;

-- ---------------------------------------------------------------------
-- Q24 (Objective, SQL support) : Missing values and duplicates
-- Logic : count NULLs / empty text in every column; the duplicate check
--         groups by CustomerId and keeps groups bigger than 1.
-- ---------------------------------------------------------------------
SELECT
    SUM(CustomerId     IS NULL) AS null_CustomerId,
    SUM(CreditScore    IS NULL) AS null_CreditScore,
    SUM(Tenure         IS NULL) AS null_Tenure,
    SUM(Balance        IS NULL) AS null_Balance,
    SUM(NumOfProducts  IS NULL) AS null_NumOfProducts,
    SUM(HasCrCard      IS NULL) AS null_HasCrCard,
    SUM(IsActiveMember IS NULL) AS null_IsActiveMember,
    SUM(Exited         IS NULL) AS null_Exited
FROM Bank_Churn;

SELECT
    SUM(CustomerId      IS NULL) AS null_CustomerId,
    SUM(Surname IS NULL OR TRIM(Surname) = '') AS blank_Surname,
    SUM(Age             IS NULL) AS null_Age,
    SUM(GenderID        IS NULL) AS null_GenderID,
    SUM(EstimatedSalary IS NULL) AS null_EstimatedSalary,
    SUM(GeographyID     IS NULL) AS null_GeographyID,
    SUM(Bank_DOJ        IS NULL) AS null_Bank_DOJ
FROM CustomerInfo;

SELECT CustomerId, COUNT(*) AS times_repeated          -- expect 0 rows
FROM CustomerInfo
GROUP BY CustomerId
HAVING COUNT(*) > 1;

-- Workbench "safe update" mode blocks UPDATEs without a key in WHERE (Error 1175)
SET SQL_SAFE_UPDATES = 0;

-- ---------------------------------------------------------------------
-- Cleaning : trim surnames (same step as TRIM in Excel)
-- Logic    : TRIM removes leading/trailing spaces, REPLACE turns double
--            inner spaces into one. Only rows that change are updated.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS surnames_needing_clean                -- 0 expected
FROM CustomerInfo
WHERE Surname <> REPLACE(TRIM(Surname), '  ', ' ');

UPDATE CustomerInfo
SET Surname = REPLACE(TRIM(Surname), '  ', ' ')
WHERE Surname <> REPLACE(TRIM(Surname), '  ', ' ');

-- ---------------------------------------------------------------------
-- Q26 (Objective, SQL) : Data discrepancy in IsActiveMember vs Exited
-- Logic : Exited is 100% correct, and a customer who has left the bank
--         cannot still be an active member, so every row with
--         Exited = 1 AND IsActiveMember = 1 is wrong.
-- ---------------------------------------------------------------------
SELECT IsActiveMember, Exited, COUNT(*) AS Customers
FROM Bank_Churn
GROUP BY IsActiveMember, Exited
ORDER BY Exited, IsActiveMember;

SELECT COUNT(*) AS Discrepant_Rows                       -- 735 expected
FROM Bank_Churn
WHERE Exited = 1 AND IsActiveMember = 1;

-- Untouched copy of the original data, then fix the column
CREATE TABLE IF NOT EXISTS Bank_Churn_backup AS
SELECT * FROM Bank_Churn;

UPDATE Bank_Churn
SET IsActiveMember = 0
WHERE Exited = 1 AND IsActiveMember = 1;

SELECT COUNT(*) AS Discrepant_Rows_After_Fix             -- 0 expected
FROM Bank_Churn
WHERE Exited = 1 AND IsActiveMember = 1;

SET SQL_SAFE_UPDATES = 1;

-- From here on IsActiveMember is the corrected value
-- (same as IsActive_Corrected in the Excel workbook: 4,416 active members).


-- =====================================================================
-- PART C : OBJECTIVE QUESTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1 (Objective, SQL) : Distribution of account balance across regions
-- Logic : join CustomerInfo -> Bank_Churn -> Geography, group by region.
--         SUM(SUM()) OVER () gives each region's share of the total balance.
-- ---------------------------------------------------------------------
SELECT geo.GeographyLocation                         AS Region,
       COUNT(*)                                      AS Customers,
       ROUND(SUM(b.Balance), 2)                      AS Total_Balance,
       ROUND(AVG(b.Balance), 2)                      AS Avg_Balance,
       ROUND(MIN(b.Balance), 2)                      AS Min_Balance,
       ROUND(MAX(b.Balance), 2)                      AS Max_Balance,
       SUM(b.Balance = 0)                            AS Zero_Balance_Accounts,
       ROUND(100 * SUM(b.Balance) / SUM(SUM(b.Balance)) OVER (), 2) AS Pct_Of_Total_Balance
FROM CustomerInfo c
JOIN Bank_Churn b  ON c.CustomerId  = b.CustomerId
JOIN Geography geo ON c.GeographyID = geo.GeographyID
GROUP BY geo.GeographyLocation
ORDER BY Total_Balance DESC;

-- ---------------------------------------------------------------------
-- Q2 (Objective, SQL) : Top 5 customers with the highest Estimated Salary
--                       in the last quarter of the year (Oct - Dec)
-- Logic : QUARTER(Bank_DOJ) = 4 keeps customers who joined in Oct-Dec.
--         Q2a = any year, Q2b = only the latest year in the data (2019).
-- ---------------------------------------------------------------------
-- Q2a : all years
SELECT c.CustomerId, c.Surname, c.EstimatedSalary, c.Bank_DOJ
FROM CustomerInfo c
WHERE QUARTER(c.Bank_DOJ) = 4
ORDER BY c.EstimatedSalary DESC
LIMIT 5;

-- Q2b : latest year only
SELECT c.CustomerId, c.Surname, c.EstimatedSalary, c.Bank_DOJ
FROM CustomerInfo c
WHERE QUARTER(c.Bank_DOJ) = 4
  AND YEAR(c.Bank_DOJ) = (SELECT MAX(YEAR(Bank_DOJ)) FROM CustomerInfo)
ORDER BY c.EstimatedSalary DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- Q3 (Objective, SQL) : Average number of products used by customers
--                       who have a credit card
-- Logic : filter HasCrCard = 1 and take AVG(NumOfProducts).
--         The second query shows holders next to non-holders for comparison.
-- ---------------------------------------------------------------------
SELECT ROUND(AVG(NumOfProducts), 4) AS Avg_Products_Credit_Card_Holders
FROM Bank_Churn
WHERE HasCrCard = 1;

SELECT cc.Category AS Card_Status,
       COUNT(*)    AS Customers,
       ROUND(AVG(b.NumOfProducts), 4) AS Avg_Products
FROM Bank_Churn b
JOIN CreditCard cc ON b.HasCrCard = cc.CreditID
GROUP BY cc.Category;

-- ---------------------------------------------------------------------
-- Q4 (Objective, SQL) : Churn rate by gender for the most recent year
-- Logic : the most recent year = MAX(YEAR(Bank_DOJ)) = 2019 (customer-joining
--         year). CAST makes the rate a clean DECIMAL(5,2).
-- ---------------------------------------------------------------------
SELECT YEAR(c.Bank_DOJ)  AS Join_Year,
       g.GenderCategory  AS Gender,
       COUNT(*)          AS Customers,
       SUM(b.Exited)     AS Exited_Customers,
       CAST(100 * SUM(b.Exited) / COUNT(*) AS DECIMAL(5,2)) AS Churn_Rate_Pct
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
JOIN Gender g     ON c.GenderID   = g.GenderID
WHERE YEAR(c.Bank_DOJ) = (SELECT MAX(YEAR(Bank_DOJ)) FROM CustomerInfo)
GROUP BY YEAR(c.Bank_DOJ), g.GenderCategory
ORDER BY Churn_Rate_Pct DESC;

-- ---------------------------------------------------------------------
-- Q5 (Objective, SQL) : Average credit score - exited vs remaining customers
-- Logic : group by the Exited flag and show its label from ExitCustomer.
-- ---------------------------------------------------------------------
SELECT e.ExitCategory              AS Customer_Status,
       COUNT(*)                    AS Customers,
       ROUND(AVG(b.CreditScore),2) AS Avg_Credit_Score
FROM Bank_Churn b
JOIN ExitCustomer e ON b.Exited = e.ExitID
GROUP BY e.ExitCategory;

-- ---------------------------------------------------------------------
-- Q6 (Objective, SQL) : Which gender has the higher average estimated
--                       salary, and how does it relate to active accounts?
-- Logic : per gender - average salary, number of active accounts and the
--         active share of that gender (IsActiveMember is the corrected one).
-- ---------------------------------------------------------------------
SELECT g.GenderCategory                         AS Gender,
       COUNT(*)                                 AS Total_Customers,
       ROUND(AVG(c.EstimatedSalary), 2)         AS Avg_Estimated_Salary,
       SUM(b.IsActiveMember)                    AS Active_Accounts,
       ROUND(100 * SUM(b.IsActiveMember) / COUNT(*), 2) AS Active_Pct
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
JOIN Gender g     ON c.GenderID   = g.GenderID
GROUP BY g.GenderCategory
ORDER BY Avg_Estimated_Salary DESC;

-- ---------------------------------------------------------------------
-- Q7 (Objective, SQL) : Segment customers by credit score and find the
--                       segment with the highest exit rate
-- Logic : CASE-WHEN builds the 5 bands from the brief inside a derived table;
--         RANK() orders the bands by exit rate (rank 1 = highest).
-- ---------------------------------------------------------------------
SELECT Credit_Segment,
       COUNT(*)                              AS Customers,
       SUM(Exited)                           AS Exited_Customers,
       ROUND(100 * SUM(Exited) / COUNT(*), 2) AS Exit_Rate_Pct,
       RANK() OVER (ORDER BY SUM(Exited) / COUNT(*) DESC) AS Exit_Rate_Rank
FROM (
    SELECT Exited,
           CASE WHEN CreditScore >= 800 THEN 'Excellent (800-850)'
                WHEN CreditScore >= 740 THEN 'Very Good (740-799)'
                WHEN CreditScore >= 670 THEN 'Good (670-739)'
                WHEN CreditScore >= 580 THEN 'Fair (580-669)'
                ELSE 'Poor (300-579)' END AS Credit_Segment
    FROM Bank_Churn
) t
GROUP BY Credit_Segment
ORDER BY Exit_Rate_Rank;

-- ---------------------------------------------------------------------
-- Q8 (Objective, SQL) : Region with the most active customers who have
--                       a tenure of more than 5 years
-- Logic : WHERE keeps active members with Tenure > 5, then count per region.
-- ---------------------------------------------------------------------
SELECT geo.GeographyLocation AS Region,
       COUNT(*)              AS Active_Customers_Tenure_Over_5
FROM CustomerInfo c
JOIN Bank_Churn b  ON c.CustomerId  = b.CustomerId
JOIN Geography geo ON c.GeographyID = geo.GeographyID
WHERE b.IsActiveMember = 1
  AND b.Tenure > 5
GROUP BY geo.GeographyLocation
ORDER BY Active_Customers_Tenure_Over_5 DESC;

-- ---------------------------------------------------------------------
-- Q9 (Objective, SQL support) : Impact of having a credit card on churn
-- Logic : churn rate for holders vs non-holders - a small gap means the
--         card on its own does not explain churn.
-- ---------------------------------------------------------------------
SELECT cc.Category                             AS Card_Status,
       COUNT(*)                                AS Customers,
       SUM(b.Exited)                           AS Exited_Customers,
       ROUND(100 * SUM(b.Exited) / COUNT(*), 2) AS Churn_Rate_Pct
FROM Bank_Churn b
JOIN CreditCard cc ON b.HasCrCard = cc.CreditID
GROUP BY cc.Category
ORDER BY Churn_Rate_Pct DESC;

-- ---------------------------------------------------------------------
-- Q10 (Objective, SQL support) : Most common number of products among
--                                customers who have exited
-- Logic : keep Exited = 1, count customers per NumOfProducts, biggest first.
-- ---------------------------------------------------------------------
SELECT NumOfProducts,
       COUNT(*) AS Exited_Customers,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS Pct_Of_Exited
FROM Bank_Churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY Exited_Customers DESC;

-- ---------------------------------------------------------------------
-- Q11 (Objective, SQL) : Trend of customers joining over time and
--                        seasonal patterns (prepare in SQL, chart in Power BI)
-- ---------------------------------------------------------------------
-- Q11a : year x month series (use this one for the line chart)
SELECT YEAR(Bank_DOJ)               AS Join_Year,
       MONTH(Bank_DOJ)              AS Join_Month,
       DATE_FORMAT(Bank_DOJ, '%b')  AS Month_Name,
       COUNT(*)                     AS Customers_Joined
FROM CustomerInfo
GROUP BY YEAR(Bank_DOJ), MONTH(Bank_DOJ), DATE_FORMAT(Bank_DOJ, '%b')
ORDER BY Join_Year, Join_Month;

-- Q11b : yearly trend with year-on-year growth (LAG looks at the previous year)
WITH yearly AS (
    SELECT YEAR(Bank_DOJ) AS Join_Year, COUNT(*) AS Customers_Joined
    FROM CustomerInfo
    GROUP BY YEAR(Bank_DOJ)
)
SELECT Join_Year,
       Customers_Joined,
       LAG(Customers_Joined) OVER (ORDER BY Join_Year) AS Previous_Year,
       ROUND(100 * (Customers_Joined - LAG(Customers_Joined) OVER (ORDER BY Join_Year))
             / LAG(Customers_Joined) OVER (ORDER BY Join_Year), 2) AS YoY_Growth_Pct
FROM yearly
ORDER BY Join_Year;

-- Q11c : seasonality - month of the year pooled over all years
SELECT MONTH(Bank_DOJ)              AS Join_Month,
       DATE_FORMAT(Bank_DOJ, '%b')  AS Month_Name,
       COUNT(*)                     AS Customers_Joined,
       ROUND(COUNT(*) / COUNT(DISTINCT YEAR(Bank_DOJ)), 1) AS Avg_Per_Year
FROM CustomerInfo
GROUP BY MONTH(Bank_DOJ), DATE_FORMAT(Bank_DOJ, '%b')
ORDER BY Join_Month;

-- Q11d : quarterly pattern by year
SELECT YEAR(Bank_DOJ)                   AS Join_Year,
       CONCAT('Q', QUARTER(Bank_DOJ))   AS Join_Quarter,
       COUNT(*)                         AS Customers_Joined
FROM CustomerInfo
GROUP BY YEAR(Bank_DOJ), QUARTER(Bank_DOJ), CONCAT('Q', QUARTER(Bank_DOJ))
ORDER BY Join_Year, QUARTER(Bank_DOJ);

-- ---------------------------------------------------------------------
-- Q12 (Objective, SQL support) : Number of products vs account balance
--                                for customers who have exited
-- Logic : balance statistics per product count (exited customers only);
--         the second query gives the correlation coefficient.
-- ---------------------------------------------------------------------
SELECT NumOfProducts,
       COUNT(*)                   AS Exited_Customers,
       ROUND(AVG(Balance), 2)     AS Avg_Balance,
       ROUND(MIN(Balance), 2)     AS Min_Balance,
       ROUND(MAX(Balance), 2)     AS Max_Balance,
       ROUND(SUM(Balance), 2)     AS Total_Balance
FROM Bank_Churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY NumOfProducts;

-- Pearson correlation = (E[xy] - E[x]E[y]) / (std_x * std_y)   (MySQL has no CORR())
SELECT ROUND((AVG(NumOfProducts * Balance) - AVG(NumOfProducts) * AVG(Balance))
             / (STDDEV_POP(NumOfProducts) * STDDEV_POP(Balance)), 4) AS Corr_Products_Balance_Exited
FROM Bank_Churn
WHERE Exited = 1;

-- ---------------------------------------------------------------------
-- Q13 (Objective, SQL support) : Outliers in balance among retained customers
-- Logic : IQR rule. Q1 / Q3 = values at the 25% / 75% position after sorting
--         with ROW_NUMBER(); outlier if below Q1 - 1.5*IQR or above Q3 + 1.5*IQR.
--         Q13a uses every retained customer; Q13b ignores zero balances,
--         because 3,117 retained customers hold exactly 0 and pull Q1 down to 0.
-- ---------------------------------------------------------------------
-- Q13a : all retained customers
WITH ranked AS (
    SELECT CustomerId, Balance,
           ROW_NUMBER() OVER (ORDER BY Balance) AS rn,
           COUNT(*) OVER ()                     AS n
    FROM Bank_Churn
    WHERE Exited = 0
),
quartiles AS (
    SELECT MAX(CASE WHEN rn = CEIL(0.25 * n) THEN Balance END) AS Q1,
           MAX(CASE WHEN rn = CEIL(0.75 * n) THEN Balance END) AS Q3
    FROM ranked
),
fences AS (
    SELECT Q1, Q3, Q3 - Q1 AS IQR,
           Q1 - 1.5 * (Q3 - Q1) AS Lower_Fence,
           Q3 + 1.5 * (Q3 - Q1) AS Upper_Fence
    FROM quartiles
)
SELECT f.Q1, f.Q3, f.IQR, f.Lower_Fence, f.Upper_Fence,
       SUM(r.Balance < f.Lower_Fence) AS Low_Outliers,
       SUM(r.Balance > f.Upper_Fence) AS High_Outliers
FROM ranked r
CROSS JOIN fences f
GROUP BY f.Q1, f.Q3, f.IQR, f.Lower_Fence, f.Upper_Fence;

-- Q13b : retained customers with a balance above 0
WITH ranked AS (
    SELECT CustomerId, Balance,
           ROW_NUMBER() OVER (ORDER BY Balance) AS rn,
           COUNT(*) OVER ()                     AS n
    FROM Bank_Churn
    WHERE Exited = 0 AND Balance > 0
),
quartiles AS (
    SELECT MAX(CASE WHEN rn = CEIL(0.25 * n) THEN Balance END) AS Q1,
           MAX(CASE WHEN rn = CEIL(0.75 * n) THEN Balance END) AS Q3
    FROM ranked
),
fences AS (
    SELECT Q1, Q3, Q3 - Q1 AS IQR,
           Q1 - 1.5 * (Q3 - Q1) AS Lower_Fence,
           Q3 + 1.5 * (Q3 - Q1) AS Upper_Fence
    FROM quartiles
)
SELECT f.Q1, f.Q3, f.IQR, f.Lower_Fence, f.Upper_Fence,
       SUM(r.Balance < f.Lower_Fence) AS Low_Outliers,
       SUM(r.Balance > f.Upper_Fence) AS High_Outliers
FROM ranked r
CROSS JOIN fences f
GROUP BY f.Q1, f.Q3, f.IQR, f.Lower_Fence, f.Upper_Fence;

-- ---------------------------------------------------------------------
-- Q15 (Objective, SQL) : Gender-wise average income in each geography,
--                        and rank the genders by that average
-- Logic : average salary per (geography, gender) in a CTE, then
--         RANK() restarts for every geography (PARTITION BY).
-- ---------------------------------------------------------------------
WITH avg_income AS (
    SELECT c.GeographyID,
           geo.GeographyLocation AS Geography,
           g.GenderCategory      AS Gender,
           ROUND(AVG(c.EstimatedSalary), 2) AS Avg_Income
    FROM CustomerInfo c
    JOIN Gender g      ON c.GenderID    = g.GenderID
    JOIN Geography geo ON c.GeographyID = geo.GeographyID
    GROUP BY c.GeographyID, geo.GeographyLocation, g.GenderCategory
)
SELECT GeographyID, Geography, Gender, Avg_Income,
       RANK() OVER (PARTITION BY GeographyID ORDER BY Avg_Income DESC) AS Income_Rank
FROM avg_income
ORDER BY GeographyID, Income_Rank;

-- ---------------------------------------------------------------------
-- Q16 (Objective, SQL) : Average tenure of exited customers in each age
--                        bracket (18-30, 31-50, 50+)
-- ---------------------------------------------------------------------
SELECT CASE WHEN c.Age <= 30 THEN '18-30'
            WHEN c.Age <= 50 THEN '31-50'
            ELSE '50+' END           AS Age_Bracket,
       COUNT(*)                      AS Exited_Customers,
       ROUND(AVG(b.Tenure), 2)       AS Avg_Tenure_Years
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
WHERE b.Exited = 1
GROUP BY Age_Bracket
ORDER BY MIN(c.Age);

-- ---------------------------------------------------------------------
-- Q17 (Objective, SQL support) : Correlation between salary and balance
--                                (all customers, exited, retained)
-- ---------------------------------------------------------------------
WITH d AS (
    SELECT c.EstimatedSalary AS salary, b.Balance AS balance, b.Exited
    FROM CustomerInfo c
    JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
)
SELECT 'All customers' AS Segment,
       ROUND((AVG(salary * balance) - AVG(salary) * AVG(balance))
             / (STDDEV_POP(salary) * STDDEV_POP(balance)), 4) AS Corr_Salary_Balance
FROM d
UNION ALL
SELECT 'Exited',
       ROUND((AVG(salary * balance) - AVG(salary) * AVG(balance))
             / (STDDEV_POP(salary) * STDDEV_POP(balance)), 4)
FROM d WHERE Exited = 1
UNION ALL
SELECT 'Retained',
       ROUND((AVG(salary * balance) - AVG(salary) * AVG(balance))
             / (STDDEV_POP(salary) * STDDEV_POP(balance)), 4)
FROM d WHERE Exited = 0;

-- ---------------------------------------------------------------------
-- Q18 (Objective, SQL support) : Correlation between salary and credit score
-- ---------------------------------------------------------------------
SELECT ROUND((AVG(c.EstimatedSalary * b.CreditScore) - AVG(c.EstimatedSalary) * AVG(b.CreditScore))
             / (STDDEV_POP(c.EstimatedSalary) * STDDEV_POP(b.CreditScore)), 4) AS Corr_Salary_CreditScore
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId;

-- ---------------------------------------------------------------------
-- Q19 (Objective, SQL) : Rank each credit-score bucket by the number of
--                        customers who churned
-- Logic : count churned customers per bucket in a CTE, rank them with RANK().
-- ---------------------------------------------------------------------
WITH bucket AS (
    SELECT CASE WHEN CreditScore >= 800 THEN 'Excellent (800-850)'
                WHEN CreditScore >= 740 THEN 'Very Good (740-799)'
                WHEN CreditScore >= 670 THEN 'Good (670-739)'
                WHEN CreditScore >= 580 THEN 'Fair (580-669)'
                ELSE 'Poor (300-579)' END AS Credit_Bucket,
           COUNT(*)    AS Customers,
           SUM(Exited) AS Churned_Customers
    FROM Bank_Churn
    GROUP BY Credit_Bucket
)
SELECT Credit_Bucket, Customers, Churned_Customers,
       RANK() OVER (ORDER BY Churned_Customers DESC) AS Churn_Rank
FROM bucket
ORDER BY Churn_Rank;

-- ---------------------------------------------------------------------
-- Q20 (Objective, SQL) : Number of credit-card customers per age bucket, and
--                        the buckets below the average per bucket
-- Logic : Q20a counts card holders per bucket. Q20b keeps buckets whose
--         count is lower than the average across buckets (AVG() OVER ()).
-- ---------------------------------------------------------------------
-- Q20a
SELECT CASE WHEN c.Age <= 30 THEN '18-30'
            WHEN c.Age <= 50 THEN '31-50'
            ELSE '50+' END       AS Age_Bucket,
       SUM(b.HasCrCard)          AS Credit_Card_Customers
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
GROUP BY Age_Bucket
ORDER BY MIN(c.Age);

-- Q20b
WITH bucket AS (
    SELECT CASE WHEN c.Age <= 30 THEN '18-30'
                WHEN c.Age <= 50 THEN '31-50'
                ELSE '50+' END   AS Age_Bucket,
           SUM(b.HasCrCard)      AS Credit_Card_Customers
    FROM CustomerInfo c
    JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
    GROUP BY Age_Bucket
),
with_avg AS (
    SELECT Age_Bucket, Credit_Card_Customers,
           ROUND(AVG(Credit_Card_Customers) OVER (), 2) AS Avg_Per_Bucket
    FROM bucket
)
SELECT Age_Bucket, Credit_Card_Customers, Avg_Per_Bucket
FROM with_avg
WHERE Credit_Card_Customers < Avg_Per_Bucket;

-- ---------------------------------------------------------------------
-- Q21 (Objective, SQL) : Rank the locations by number of churned customers
--                        and by average balance
-- Logic : one row per location; two RANK() columns on the aggregates.
-- ---------------------------------------------------------------------
SELECT geo.GeographyLocation                    AS Location,
       SUM(b.Exited)                            AS Churned_Customers,
       RANK() OVER (ORDER BY SUM(b.Exited) DESC) AS Churn_Rank,
       ROUND(AVG(b.Balance), 2)                 AS Avg_Balance,
       RANK() OVER (ORDER BY AVG(b.Balance) DESC) AS Balance_Rank
FROM CustomerInfo c
JOIN Bank_Churn b  ON c.CustomerId  = b.CustomerId
JOIN Geography geo ON c.GeographyID = geo.GeographyID
GROUP BY geo.GeographyLocation
ORDER BY Churn_Rank;

-- ---------------------------------------------------------------------
-- Q22 (Objective, SQL) : Column in the format "CustomerID_Surname"
-- Logic : CONCAT joins the id, an underscore and the surname; CAST turns
--         the integer id into text first.
-- ---------------------------------------------------------------------
SELECT CustomerId,
       Surname,
       CONCAT(CAST(CustomerId AS CHAR), '_', Surname) AS CustomerID_Surname
FROM CustomerInfo
ORDER BY CustomerId
LIMIT 20;

-- ---------------------------------------------------------------------
-- Q23 (Objective, SQL) : Bring ExitCategory into Bank_Churn WITHOUT a JOIN
-- Logic : a correlated scalar subquery looks up the label for each row.
-- ---------------------------------------------------------------------
SELECT b.CustomerId,
       b.Exited,
       (SELECT e.ExitCategory
        FROM ExitCustomer e
        WHERE e.ExitID = b.Exited) AS ExitCategory
FROM Bank_Churn b
ORDER BY b.CustomerId
LIMIT 20;

-- ---------------------------------------------------------------------
-- Q25 (Objective, SQL) : Customer ids, surname and active status for
--                        customers whose surname ends with "on"
-- Logic : LIKE '%on' = anything followed by "on" at the end of the text.
-- ---------------------------------------------------------------------
SELECT c.CustomerId,
       c.Surname,
       a.ActiveCategory AS Activity_Status
FROM CustomerInfo c
JOIN Bank_Churn b     ON c.CustomerId  = b.CustomerId
JOIN ActiveCustomer a ON b.IsActiveMember = a.ActiveID
WHERE c.Surname LIKE '%on'
ORDER BY c.CustomerId;


-- =====================================================================
-- PART D : SUBJECTIVE QUESTIONS - SQL SUPPORT
--          (the written insights for these go in the Word document)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Subjective Q1 (SQL) : Long-term vs new customers - behaviour & loyalty
-- Logic : Tenure is 3-7 years in this data, so New = 3-4, Mid = 5, Long-term = 6-7.
-- ---------------------------------------------------------------------
SELECT CASE WHEN b.Tenure <= 4 THEN 'New (3-4 yrs)'
            WHEN b.Tenure = 5  THEN 'Mid (5 yrs)'
            ELSE 'Long-term (6-7 yrs)' END   AS Tenure_Group,
       COUNT(*)                              AS Customers,
       ROUND(AVG(b.Balance), 2)              AS Avg_Balance,
       ROUND(AVG(c.EstimatedSalary), 2)      AS Avg_Salary,
       ROUND(AVG(b.NumOfProducts), 2)        AS Avg_Products,
       ROUND(AVG(b.CreditScore), 0)          AS Avg_Credit_Score,
       ROUND(100 * SUM(b.IsActiveMember) / COUNT(*), 2) AS Active_Pct,
       ROUND(100 * SUM(b.Exited) / COUNT(*), 2)         AS Churn_Rate_Pct
FROM Bank_Churn b
JOIN CustomerInfo c ON b.CustomerId = c.CustomerId
GROUP BY Tenure_Group
ORDER BY MIN(b.Tenure);

-- ---------------------------------------------------------------------
-- Subjective Q2 (SQL) : Product affinity - what is used together
-- Logic : how many products customers hold, whether they also hold the
--         credit card, and how each combination behaves.
-- ---------------------------------------------------------------------
SELECT b.NumOfProducts,
       cc.Category                                   AS Card_Status,
       COUNT(*)                                      AS Customers,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY b.NumOfProducts), 2) AS Pct_Within_Product_Group,
       ROUND(AVG(b.Balance), 2)                      AS Avg_Balance,
       ROUND(100 * SUM(b.Exited) / COUNT(*), 2)      AS Churn_Rate_Pct
FROM Bank_Churn b
JOIN CreditCard cc ON b.HasCrCard = cc.CreditID
GROUP BY b.NumOfProducts, cc.Category
ORDER BY b.NumOfProducts, cc.Category;

-- ---------------------------------------------------------------------
-- Subjective Q3 (SQL) : Geographic trends - active accounts and churn
-- ---------------------------------------------------------------------
SELECT geo.GeographyLocation                          AS Region,
       COUNT(*)                                       AS Customers,
       SUM(b.IsActiveMember)                          AS Active_Accounts,
       ROUND(100 * SUM(b.IsActiveMember) / COUNT(*), 2) AS Active_Pct,
       SUM(b.Exited)                                  AS Exited_Customers,
       ROUND(100 * SUM(b.Exited) / COUNT(*), 2)       AS Churn_Rate_Pct,
       ROUND(AVG(c.EstimatedSalary), 2)               AS Avg_Salary,
       ROUND(AVG(b.Balance), 2)                       AS Avg_Balance,
       ROUND(AVG(b.CreditScore), 0)                   AS Avg_Credit_Score,
       ROUND(AVG(b.NumOfProducts), 2)                 AS Avg_Products
FROM CustomerInfo c
JOIN Bank_Churn b  ON c.CustomerId  = b.CustomerId
JOIN Geography geo ON c.GeographyID = geo.GeographyID
GROUP BY geo.GeographyLocation
ORDER BY Churn_Rate_Pct DESC;

-- ---------------------------------------------------------------------
-- Subjective Q4 (SQL) : Risk management - which segments are riskiest
-- Logic : segment = age bucket x region. Financial risk = balance that
--         left the bank with churned customers; ranked highest first.
-- ---------------------------------------------------------------------
WITH seg AS (
    SELECT CASE WHEN c.Age <= 30 THEN '18-30'
                WHEN c.Age <= 50 THEN '31-50'
                ELSE '50+' END                     AS Age_Bucket,
           geo.GeographyLocation                   AS Region,
           COUNT(*)                                AS Customers,
           SUM(b.Exited)                           AS Exited_Customers,
           ROUND(100 * SUM(b.Exited) / COUNT(*), 2) AS Churn_Rate_Pct,
           ROUND(SUM(CASE WHEN b.Exited = 1 THEN b.Balance ELSE 0 END), 2) AS Balance_Lost,
           ROUND(SUM(b.Balance), 2)                AS Total_Balance
    FROM CustomerInfo c
    JOIN Bank_Churn b  ON c.CustomerId  = b.CustomerId
    JOIN Geography geo ON c.GeographyID = geo.GeographyID
    GROUP BY Age_Bucket, Region
)
SELECT Age_Bucket, Region, Customers, Exited_Customers, Churn_Rate_Pct,
       Balance_Lost, Total_Balance,
       RANK() OVER (ORDER BY Balance_Lost DESC) AS Risk_Rank
FROM seg
ORDER BY Risk_Rank;

-- ---------------------------------------------------------------------
-- Subjective Q5 (SQL) : Tenure value by segment
-- Logic : a simple proxy for value = Avg_Balance x Avg_Tenure x Retention
--         rate. It is an illustration for ranking segments, not a forecast.
-- ---------------------------------------------------------------------
WITH seg AS (
    SELECT CASE WHEN c.Age <= 30 THEN '18-30'
                WHEN c.Age <= 50 THEN '31-50'
                ELSE '50+' END                AS Age_Bucket,
           geo.GeographyLocation              AS Region,
           COUNT(*)                           AS Customers,
           AVG(b.Tenure)                      AS Avg_Tenure,
           AVG(b.Balance)                     AS Avg_Balance,
           1 - AVG(b.Exited)                  AS Retention_Rate
    FROM CustomerInfo c
    JOIN Bank_Churn b  ON c.CustomerId  = b.CustomerId
    JOIN Geography geo ON c.GeographyID = geo.GeographyID
    GROUP BY Age_Bucket, Region
)
SELECT Age_Bucket, Region, Customers,
       ROUND(Avg_Tenure, 2)      AS Avg_Tenure_Years,
       ROUND(Avg_Balance, 2)     AS Avg_Balance,
       ROUND(100 * Retention_Rate, 2) AS Retention_Pct,
       ROUND(Avg_Balance * Avg_Tenure * Retention_Rate, 0) AS Tenure_Value_Score,
       RANK() OVER (ORDER BY Avg_Balance * Avg_Tenure * Retention_Rate DESC) AS Value_Rank
FROM seg
ORDER BY Value_Rank;


-- ---------------------------------------------------------------------
-- Subjective Q6 (SQL) : Marketing campaign effectiveness — joining month
--                        vs churn rate (seasonal pattern)
-- Logic : group by the month customers joined to see if certain joining
--         months correlate with higher churn (proxy for campaign cohorts).
-- ---------------------------------------------------------------------
SELECT MONTH(c.Bank_DOJ)              AS Join_Month,
       DATE_FORMAT(c.Bank_DOJ, '%b')  AS Month_Name,
       COUNT(*)                       AS Customers,
       SUM(b.Exited)                  AS Exited_Customers,
       ROUND(100 * SUM(b.Exited) / COUNT(*), 2) AS Churn_Rate_Pct
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
GROUP BY MONTH(c.Bank_DOJ), DATE_FORMAT(c.Bank_DOJ, '%b')
ORDER BY Join_Month;


-- ---------------------------------------------------------------------
-- Subjective Q7 (SQL) : What do customers who exited have in common?
-- Logic : average profile of exited vs retained customers side by side.
--         Active_Pct uses the ORIGINAL IsActiveMember (Bank_Churn_backup)
--         because the corrected column marks every exited customer inactive.
-- ---------------------------------------------------------------------
SELECT e.ExitCategory                               AS Customer_Status,
       COUNT(*)                                     AS Customers,
       ROUND(AVG(c.Age), 1)                         AS Avg_Age,
       ROUND(AVG(b.CreditScore), 0)                 AS Avg_Credit_Score,
       ROUND(AVG(b.Balance), 2)                     AS Avg_Balance,
       ROUND(AVG(c.EstimatedSalary), 2)             AS Avg_Salary,
       ROUND(AVG(b.Tenure), 2)                      AS Avg_Tenure,
       ROUND(AVG(b.NumOfProducts), 2)               AS Avg_Products,
       ROUND(100 * AVG(o.IsActiveMember), 2)        AS Active_Pct_Original,
       ROUND(100 * AVG(b.HasCrCard), 2)             AS Credit_Card_Pct,
       ROUND(100 * AVG(geo.GeographyLocation = 'Germany'), 2) AS Germany_Pct,
       ROUND(100 * AVG(g.GenderCategory = 'Female'), 2)       AS Female_Pct
FROM Bank_Churn b
JOIN Bank_Churn_backup o ON b.CustomerId = o.CustomerId
JOIN CustomerInfo c      ON b.CustomerId = c.CustomerId
JOIN ExitCustomer e      ON b.Exited     = e.ExitID
JOIN Geography geo       ON c.GeographyID = geo.GeographyID
JOIN Gender g            ON c.GenderID    = g.GenderID
GROUP BY e.ExitCategory;

-- ---------------------------------------------------------------------
-- Subjective Q8 (SQL) : Are Tenure, NumOfProducts, IsActiveMember and
--                       EstimatedSalary useful for predicting churn?
-- Logic : churn rate for each value / band of the four fields. A big gap
--         between the highest and lowest churn rate = a useful predictor.
--         IsActiveMember is read from Bank_Churn_backup (original values),
--         otherwise the correction would leak the answer into the feature.
--         Salary is cut into 4 equal-sized bands with NTILE(4).
-- ---------------------------------------------------------------------
-- Q8a : churn rate for each value / band
WITH feature AS (
    SELECT 'Tenure' AS Feature, CAST(Tenure AS CHAR) AS Value_Group, Exited FROM Bank_Churn
    UNION ALL
    SELECT 'NumOfProducts', CAST(NumOfProducts AS CHAR), Exited FROM Bank_Churn
    UNION ALL
    SELECT 'IsActiveMember (original)', CAST(IsActiveMember AS CHAR), Exited FROM Bank_Churn_backup
    UNION ALL
    SELECT 'EstimatedSalary quartile', CONCAT('Band ', NTILE(4) OVER (ORDER BY c.EstimatedSalary)), b.Exited
    FROM CustomerInfo c
    JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
)
SELECT Feature, Value_Group,
       COUNT(*)                                 AS Customers,
       SUM(Exited)                              AS Exited_Customers,
       ROUND(100 * SUM(Exited) / COUNT(*), 2)   AS Churn_Rate_Pct
FROM feature
GROUP BY Feature, Value_Group
ORDER BY Feature, Value_Group;

-- Q8b : spread of churn rate per feature (bigger spread = stronger predictor)
WITH feature AS (
    SELECT 'Tenure' AS Feature, CAST(Tenure AS CHAR) AS Value_Group, Exited FROM Bank_Churn
    UNION ALL
    SELECT 'NumOfProducts', CAST(NumOfProducts AS CHAR), Exited FROM Bank_Churn
    UNION ALL
    SELECT 'IsActiveMember (original)', CAST(IsActiveMember AS CHAR), Exited FROM Bank_Churn_backup
    UNION ALL
    SELECT 'EstimatedSalary quartile', CONCAT('Band ', NTILE(4) OVER (ORDER BY c.EstimatedSalary)), b.Exited
    FROM CustomerInfo c
    JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
),
rates AS (
    SELECT Feature, Value_Group, 100 * SUM(Exited) / COUNT(*) AS Churn_Rate_Pct
    FROM feature
    GROUP BY Feature, Value_Group
)
SELECT Feature,
       ROUND(MIN(Churn_Rate_Pct), 2) AS Lowest_Churn_Pct,
       ROUND(MAX(Churn_Rate_Pct), 2) AS Highest_Churn_Pct,
       ROUND(MAX(Churn_Rate_Pct) - MIN(Churn_Rate_Pct), 2) AS Spread_Pct
FROM rates
GROUP BY Feature
ORDER BY Spread_Pct DESC;

-- ---------------------------------------------------------------------
-- Subjective Q9 (SQL) : Segment customers by demographics and account details
-- Logic : age bucket x gender x region, with size, money and churn per segment.
-- ---------------------------------------------------------------------
SELECT CASE WHEN c.Age <= 30 THEN '18-30'
            WHEN c.Age <= 50 THEN '31-50'
            ELSE '50+' END                      AS Age_Bucket,
       g.GenderCategory                         AS Gender,
       geo.GeographyLocation                    AS Region,
       COUNT(*)                                 AS Customers,
       ROUND(AVG(c.EstimatedSalary), 2)         AS Avg_Salary,
       ROUND(AVG(b.Balance), 2)                 AS Avg_Balance,
       ROUND(AVG(b.CreditScore), 0)             AS Avg_Credit_Score,
       ROUND(AVG(b.NumOfProducts), 2)           AS Avg_Products,
       ROUND(100 * SUM(b.Exited) / COUNT(*), 2) AS Churn_Rate_Pct
FROM CustomerInfo c
JOIN Bank_Churn b  ON c.CustomerId  = b.CustomerId
JOIN Gender g      ON c.GenderID    = g.GenderID
JOIN Geography geo ON c.GeographyID = geo.GeographyID
GROUP BY Age_Bucket, Gender, Region
ORDER BY Churn_Rate_Pct DESC;

-- ---------------------------------------------------------------------
-- Subjective Q11 (SQL) : Churn rate per year and overall
-- Logic : "year" = the year the customer joined the bank (Bank_DOJ), because
--         the data has no exit date. The last row is the overall churn rate.
-- ---------------------------------------------------------------------
SELECT CAST(YEAR(c.Bank_DOJ) AS CHAR)           AS Join_Year,
       COUNT(*)                                 AS Customers,
       SUM(b.Exited)                            AS Exited_Customers,
       ROUND(100 * SUM(b.Exited) / COUNT(*), 2) AS Churn_Rate_Pct
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
GROUP BY Join_Year
UNION ALL
SELECT 'Overall',
       COUNT(*),
       SUM(b.Exited),
       ROUND(100 * SUM(b.Exited) / COUNT(*), 2)
FROM Bank_Churn b
ORDER BY Join_Year;


-- =====================================================================
-- PART E : COLUMN RENAME AND POWER BI VIEW
-- =====================================================================

-- ---------------------------------------------------------------------
-- Subjective Q14 (SQL) : Rename HasCrCard to Has_creditcard in Bank_Churn
-- Logic : ALTER TABLE changes the table structure, not the data.
--         Run after Parts C and D, which use the old name HasCrCard.
-- ---------------------------------------------------------------------
ALTER TABLE Bank_Churn RENAME COLUMN HasCrCard TO Has_creditcard;

DESCRIBE Bank_Churn;

-- ---------------------------------------------------------------------
-- View : one flat customer table with the same helper columns as Excel
-- Logic : joins all 7 tables once, so Power BI or any query reads one object.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_master AS
SELECT c.CustomerId,
       c.Surname,
       CONCAT(CAST(c.CustomerId AS CHAR), '_', c.Surname) AS CustomerID_Surname,
       c.Age,
       CASE WHEN c.Age <= 30 THEN '18-30'
            WHEN c.Age <= 50 THEN '31-50'
            ELSE '50+' END                              AS Age_Bucket,
       g.GenderCategory                                 AS Gender,
       geo.GeographyLocation                            AS Geography,
       c.EstimatedSalary,
       c.Bank_DOJ,
       YEAR(c.Bank_DOJ)                                 AS Join_Year,
       MONTH(c.Bank_DOJ)                                AS Join_Month,
       DATE_FORMAT(c.Bank_DOJ, '%b')                    AS Month_Name,
       CONCAT('Q', QUARTER(c.Bank_DOJ))                 AS Join_Quarter,
       b.CreditScore,
       CASE WHEN b.CreditScore >= 800 THEN 'Excellent'
            WHEN b.CreditScore >= 740 THEN 'Very Good'
            WHEN b.CreditScore >= 670 THEN 'Good'
            WHEN b.CreditScore >= 580 THEN 'Fair'
            ELSE 'Poor' END                             AS Credit_Score_Bucket,
       b.Tenure,
       b.Balance,
       b.NumOfProducts,
       b.Has_creditcard,
       cc.Category                                      AS Card_Category,
       b.IsActiveMember,
       a.ActiveCategory                                 AS Active_Category,
       b.Exited,
       e.ExitCategory                                   AS Exit_Category
FROM CustomerInfo c
JOIN Bank_Churn b      ON c.CustomerId     = b.CustomerId
JOIN Gender g          ON c.GenderID       = g.GenderID
JOIN Geography geo     ON c.GeographyID    = geo.GeographyID
JOIN CreditCard cc     ON b.Has_creditcard = cc.CreditID
JOIN ActiveCustomer a  ON b.IsActiveMember = a.ActiveID
JOIN ExitCustomer e    ON b.Exited         = e.ExitID;

SELECT * FROM vw_customer_master ORDER BY CustomerId LIMIT 10;

-- Totals that must match Excel and Power BI:
-- Customers 10000 | Exited 2037 | Churn 20.37% | Active 4416
SELECT COUNT(*)                          AS Total_Customers,
       SUM(Exited)                       AS Exited_Customers,
       ROUND(100 * AVG(Exited), 2)       AS Churn_Rate_Pct,
       SUM(IsActiveMember)               AS Active_Members,
       SUM(Has_creditcard)               AS Credit_Card_Holders,
       ROUND(AVG(Balance), 2)            AS Avg_Balance,
       ROUND(AVG(EstimatedSalary), 2)    AS Avg_Salary,
       ROUND(AVG(CreditScore), 2)        AS Avg_Credit_Score
FROM vw_customer_master;
-- ============================================================
-- FINTRUST BANK - WEEK 2 SQL ANALYSIS
-- AnalystLab Africa Experience Lab Internship
-- Data Analytics Track
-- Student: Tsholofelo Hope Motlhatlhedi
-- Database: PostgreSQL
--
-- Purpose:
-- This file contains the SQL analysis for Part B of the Week 2
--
-- The analysis answers the eight business questions developed during Week 1 and includes comments explaining what each query
-- measures and how the result should be interpreted.
--
-- Tables assumed to already exist and contain the imported data:
--   1. customer_data
--   2. transaction_data
--
-- IMPORTANT:
-- This file does NOT delete or recreate the tables and does not
-- re-import the CSV files. It is safe to run after the data has
-- already been imported.
-- ============================================================


-- ============================================================
-- 0. BASIC DATA VALIDATION
-- ============================================================

-- Check the number of records in each table.
-- Expected dataset size:
-- customer_data    = 1,500 records
-- transaction_data = 12,000 records

SELECT
    (SELECT COUNT(*) FROM customer_data) AS customer_records,
    (SELECT COUNT(*) FROM transaction_data) AS transaction_records;


-- Check that every transaction Customer_ID has a matching
-- customer in customer_data.
-- A result of 0 means there are no unmatched transaction customers.

SELECT COUNT(*) AS unmatched_transaction_customers
FROM transaction_data t
LEFT JOIN customer_data c
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ============================================================
-- BUSINESS QUESTION 1
-- ============================================================
-- What proportion of FinTrust customers actively use digital
-- banking channels, and how does digital engagement vary across
-- customer segments?
--
-- Digital transaction channels used in this analysis:
-- Mobile App, Web and USSD.
--
-- NOTE:
-- Digital adoption is measured from actual transaction Channel
-- usage, rather than Preferred_Channel. This identifies customers
-- who actually used a digital channel during the observation
-- period.
-- ============================================================

-- Q1A: Digital banking adoption

WITH digital_customers AS (
    SELECT DISTINCT customer_id
    FROM transaction_data
    WHERE channel IN ('Mobile App', 'Web', 'USSD')
)
SELECT
    COUNT(DISTINCT d.customer_id) AS digital_customers,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(
        COUNT(DISTINCT d.customer_id) * 100.0
        / COUNT(DISTINCT c.customer_id),
        2
    ) AS digital_adoption_rate_pct
FROM customer_data c
LEFT JOIN digital_customers d
    ON c.customer_id = d.customer_id;


-- Q1B: Average digital engagement score by customer segment

SELECT
    customer_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(digital_engagement_score), 2)
        AS average_engagement_score
FROM customer_data
GROUP BY customer_segment
ORDER BY average_engagement_score DESC;


-- Q1 RESULT / BUSINESS INTERPRETATION
--
-- Digital banking adoption is very high, with 1,497 of 1,500
-- customers (99.80%) completing at least one transaction through
-- a digital channel during the observation period.
--
-- Average digital engagement scores are relatively similar across
-- customer segments:
--
-- Everyday  = 68.37
-- SME       = 68.34
-- Student   = 67.91
-- Premium   = 66.71
--
-- Everyday customers have the highest average engagement score,
-- while Premium customers have the lowest. The relatively small
-- difference between the segments suggests that digital engagement
-- is broadly similar across the customer segments represented in
-- this dataset.


-- ============================================================
-- BUSINESS QUESTION 2
-- ============================================================
-- Which banking channels are most frequently used by customers,
-- and how does channel usage vary by customer segment?
-- ============================================================

SELECT
    c.customer_segment,
    t.channel,
    COUNT(t.transaction_id) AS transaction_count,
    COUNT(DISTINCT t.customer_id) AS unique_customers
FROM customer_data c
JOIN transaction_data t
    ON c.customer_id = t.customer_id
GROUP BY
    c.customer_segment,
    t.channel
ORDER BY
    c.customer_segment,
    transaction_count DESC;


-- Q2 RESULT / BUSINESS INTERPRETATION
--
-- Mobile App is the most frequently used transaction channel
-- across every customer segment.
--
-- Transaction counts by segment and channel:
--
-- EVERYDAY:
--   Mobile App = 2,368
--   POS        = 1,120
--   Web        =   899
--   ATM        =   846
--   USSD       =   411
--
-- PREMIUM:
--   Mobile App =   996
--   POS        =   478
--   Web        =   361
--   ATM        =   353
--   USSD       =   173
--
-- SME:
--   Mobile App =   707
--   POS        =   376
--   Web        =   257
--   ATM        =   226
--   USSD       =   140
--
-- STUDENT:
--   Mobile App = 1,031
--   POS        =   419
--   Web        =   352
--   ATM        =   322
--   USSD       =   165
--
-- The Everyday segment has the highest transaction volume across
-- all channels, while the Mobile App is the dominant channel for
-- every segment.


-- ============================================================
-- BUSINESS QUESTION 3
-- ============================================================
-- Which devices are most commonly used for transactions, and how
-- does device usage differ in terms of transaction volume and
-- number of unique customers?
--
-- Missing Device_Type values are excluded from the device-level
-- analysis.
-- ============================================================

SELECT
    device_type,
    COUNT(transaction_id) AS transaction_count,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(
        COUNT(transaction_id) * 100.0
        / SUM(COUNT(transaction_id)) OVER (),
        2
    ) AS transaction_share_pct
FROM transaction_data
WHERE device_type IS NOT NULL
GROUP BY device_type
ORDER BY transaction_count DESC;


-- Q3 RESULT / BUSINESS INTERPRETATION
--
-- Device results:
--
-- Android       = 4,797 transactions | 1,458 customers | 39.98%
-- iOS           = 2,920 transactions | 1,299 customers | 24.33%
-- POS Terminal  = 1,571 transactions | 1,030 customers | 13.09%
-- Web Browser   = 1,447 transactions | 1,010 customers | 12.06%
-- ATM Terminal  = 1,169 transactions |   982 customers |  9.74%
--
-- Android is the most commonly used device category, accounting
-- for 39.98% of transactions and involving the highest number of
-- unique customers.
--
-- iOS is the second most-used device category.
--
-- There are 96 transactions with missing Device_Type values.
-- These are excluded from the device comparison.
--
-- NOTE:
-- Unique customers are counted separately within each device
-- category. A customer can appear in more than one device
-- category, so the unique-customer figures should not be added
-- together.


-- ============================================================
-- BUSINESS QUESTION 4
-- ============================================================
-- How does transaction activity vary across the geographic
-- locations represented in the dataset?
--
-- Missing Location values are excluded from the location-level
-- analysis.
-- ============================================================

SELECT
    location,
    COUNT(transaction_id) AS transaction_count,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(amount_ngn), 2) AS total_transaction_value_ngn,
    ROUND(
        COUNT(transaction_id) * 100.0
        / SUM(COUNT(transaction_id)) OVER (),
        2
    ) AS transaction_share_pct
FROM transaction_data
WHERE location IS NOT NULL
GROUP BY location
ORDER BY transaction_count DESC;


-- Q4 RESULT / BUSINESS INTERPRETATION
--
-- Location results:
--
-- Ibadan:
--   1,550 transactions
--   1,032 unique customers
--   NGN 81,415,629.64 total value
--
-- Kano:
--   1,526 transactions
--   1,021 unique customers
--   NGN 74,414,462.27 total value
--
-- Port Harcourt:
--   1,520 transactions
--   1,017 unique customers
--   NGN 71,379,838.80 total value
--
-- Enugu:
--   1,484 transactions
--   1,015 unique customers
--   NGN 69,101,538.42 total value
--
-- Kaduna:
--   1,481 transactions
--   1,008 unique customers
--   NGN 70,378,742.65 total value
--
-- Abuja:
--   1,461 transactions
--   1,003 unique customers
--   NGN 62,051,569.38 total value
--
-- Benin City:
--   1,451 transactions
--   1,007 unique customers
--   NGN 63,387,171.11 total value
--
-- Lagos:
--   1,431 transactions
--   1,000 unique customers
--   NGN 63,978,344.62 total value
--
-- Ibadan has the highest transaction volume and transaction value
-- among the locations represented in the dataset.
--
-- Transaction activity is relatively evenly distributed across
-- the eight supplied locations.
--
-- There are 96 transactions with missing Location values.
-- These are excluded from this location comparison.
--
-- NOTE:
-- The geographic analysis is limited to the locations actually
-- supplied in the dataset. It should not be interpreted as a
-- complete representation of all FinTrust geographic activity.


-- ============================================================
-- BUSINESS QUESTION 5
-- ============================================================
-- How do age, income band, customer segment and account type
-- relate to digital banking engagement and transaction behaviour?
--
-- Monthly_Income_Band is treated as a categorical/ordinal field.
-- The dataset does not provide an exact numerical income value,
-- so the analysis does not attempt to calculate an actual income.
-- ============================================================

WITH customer_activity AS (
    SELECT
        c.customer_id,
        c.age,
        c.monthly_income_band,
        c.customer_segment,
        c.account_type,
        c.digital_engagement_score,
        COUNT(t.transaction_id) AS transaction_count
    FROM customer_data c
    LEFT JOIN transaction_data t
        ON c.customer_id = t.customer_id
    GROUP BY
        c.customer_id,
        c.age,
        c.monthly_income_band,
        c.customer_segment,
        c.account_type,
        c.digital_engagement_score
)

-- Age bands
SELECT
    'Age Band' AS dimension,
    CASE
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 65 THEN '55-65'
    END AS category,
    COUNT(*) AS customers,
    ROUND(AVG(digital_engagement_score), 2)
        AS avg_engagement_score,
    SUM(transaction_count) AS total_transactions,
    ROUND(AVG(transaction_count), 2)
        AS avg_transactions_per_customer
FROM customer_activity
GROUP BY 2

UNION ALL

-- Income bands
SELECT
    'Income Band' AS dimension,
    monthly_income_band AS category,
    COUNT(*) AS customers,
    ROUND(AVG(digital_engagement_score), 2),
    SUM(transaction_count),
    ROUND(AVG(transaction_count), 2)
FROM customer_activity
GROUP BY monthly_income_band

UNION ALL

-- Customer segments
SELECT
    'Customer Segment' AS dimension,
    customer_segment AS category,
    COUNT(*) AS customers,
    ROUND(AVG(digital_engagement_score), 2),
    SUM(transaction_count),
    ROUND(AVG(transaction_count), 2)
FROM customer_activity
GROUP BY customer_segment

UNION ALL

-- Account types
SELECT
    'Account Type' AS dimension,
    account_type AS category,
    COUNT(*) AS customers,
    ROUND(AVG(digital_engagement_score), 2),
    SUM(transaction_count),
    ROUND(AVG(transaction_count), 2)
FROM customer_activity
GROUP BY account_type

ORDER BY dimension, category;


-- Q5 RESULT / BUSINESS INTERPRETATION
--
-- AGE:
-- 18-24 = 217 customers | Avg engagement 68.77 | 1,776 transactions
-- 25-34 = 297 customers | Avg engagement 68.21 | 2,382 transactions
-- 35-44 = 322 customers | Avg engagement 66.55 | 2,533 transactions
-- 45-54 = 343 customers | Avg engagement 67.40 | 2,691 transactions
-- 55-65 = 321 customers | Avg engagement 69.16 | 2,618 transactions
--
-- The 55-65 age group has the highest average engagement score,
-- while the 35-44 group has the lowest. Transaction activity is
-- broadly similar across the age groups.
--
-- INCOME BAND:
-- Below 100k = 265 customers | Avg engagement 69.17
-- 100k-249k  = 430 customers | Avg engagement 67.11
-- 250k-499k  = 416 customers | Avg engagement 67.78
-- 500k-999k  = 255 customers | Avg engagement 68.11
-- 1m+        = 134 customers | Avg engagement 68.50
--
-- The Below 100k group has the highest average engagement score.
-- The differences between income bands are relatively modest.
--
-- CUSTOMER SEGMENT:
-- Everyday = 711 customers | Avg engagement 68.37 | 5,644 transactions
-- Premium  = 295 customers | Avg engagement 66.71 | 2,361 transactions
-- SME      = 216 customers | Avg engagement 68.34 | 1,706 transactions
-- Student  = 278 customers | Avg engagement 67.91 | 2,289 transactions
--
-- Everyday customers account for the largest transaction volume,
-- which is consistent with Everyday being the largest customer
-- segment in the dataset.
--
-- ACCOUNT TYPE:
-- Savings = 893 customers | Avg engagement 68.22 | 7,149 transactions
-- Current = 378 customers | Avg engagement 67.22 | 3,023 transactions
-- Premium = 229 customers | Avg engagement 68.14 | 1,828 transactions
--
-- Savings accounts generate the largest transaction volume,
-- consistent with Savings customers representing the largest
-- account-type population.
--
-- Overall, the results show differences in engagement and
-- transaction activity across the customer characteristics, but
-- the engagement-score differences are generally modest.


-- ============================================================
-- BUSINESS QUESTION 6
-- ============================================================
-- Which transaction types and channels generate the highest
-- transaction values?
-- ============================================================

-- Transaction type analysis
SELECT
    'Transaction Type' AS dimension,
    transaction_type AS category,
    COUNT(transaction_id) AS transaction_count,
    ROUND(SUM(amount_ngn), 2)
        AS total_transaction_value_ngn,
    ROUND(AVG(amount_ngn), 2)
        AS average_transaction_value_ngn
FROM transaction_data
GROUP BY transaction_type

UNION ALL

-- Channel analysis
SELECT
    'Channel' AS dimension,
    channel AS category,
    COUNT(transaction_id) AS transaction_count,
    ROUND(SUM(amount_ngn), 2)
        AS total_transaction_value_ngn,
    ROUND(AVG(amount_ngn), 2)
        AS average_transaction_value_ngn
FROM transaction_data
GROUP BY channel

ORDER BY total_transaction_value_ngn DESC;


-- Q6 RESULT / BUSINESS INTERPRETATION
--
-- TRANSACTION TYPES:
--
-- Transfer:
--   3,549 transactions
--   NGN 237,916,663.56 total
--   NGN 67,037.67 average
--
-- Deposit:
--   1,328 transactions
--   NGN 130,985,052.28 total
--   NGN 98,633.33 average
--
-- Card Purchase:
--   3,033 transactions
--   NGN 85,863,413.48 total
--   NGN 28,309.73 average
--
-- Cash Withdrawal:
--   1,430 transactions
--   NGN 67,772,356.33 total
--   NGN 47,393.26 average
--
-- Bill Payment:
--   1,475 transactions
--   NGN 28,163,647.51 total
--   NGN 19,094.00 average
--
-- Airtime/Data:
--   1,185 transactions
--   NGN 9,776,171.40 total
--   NGN 8,249.93 average
--
-- Transfer generates the highest total transaction value among
-- transaction types.
--
-- Deposit has the highest average transaction value, even though
-- its transaction count is lower than Transfer.
--
-- CHANNELS:
--
-- Mobile App:
--   5,102 transactions
--   NGN 240,104,407.78 total
--   NGN 47,060.83 average
--
-- POS:
--   2,393 transactions
--   NGN 104,346,699.10 total
--   NGN 43,604.96 average
--
-- Web:
--   1,869 transactions
--   NGN 89,325,003.75 total
--   NGN 47,792.94 average
--
-- ATM:
--   1,747 transactions
--   NGN 83,942,341.25 total
--   NGN 48,049.43 average
--
-- USSD:
--     889 transactions
--   NGN 42,758,902.97 total
--   NGN 48,097.81 average
--
-- Mobile App generates the highest total transaction value among
-- the channels, mainly because it also has the highest transaction
-- volume.


-- ============================================================
-- BUSINESS QUESTION 7
-- ============================================================
-- Which transaction channels and transaction types have the
-- highest rates of failed or reversed transactions?
--
-- The combined failure/reversal rate is calculated as:
--
--   (Failed + Reversed transactions) / Total transactions * 100
--
-- This identifies operational performance patterns. It does not
-- by itself establish the reason for a failure or reversal.
-- ============================================================

-- Channel and transaction-type failure/reversal rates

SELECT
    'Channel' AS dimension,
    channel AS category,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (
        WHERE transaction_status IN ('Failed', 'Reversed')
    ) AS failed_or_reversed,
    ROUND(
        COUNT(*) FILTER (
            WHERE transaction_status IN ('Failed', 'Reversed')
        ) * 100.0 / COUNT(*),
        2
    ) AS failure_reversal_rate_pct
FROM transaction_data
GROUP BY channel

UNION ALL

SELECT
    'Transaction Type' AS dimension,
    transaction_type AS category,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (
        WHERE transaction_status IN ('Failed', 'Reversed')
    ) AS failed_or_reversed,
    ROUND(
        COUNT(*) FILTER (
            WHERE transaction_status IN ('Failed', 'Reversed')
        ) * 100.0 / COUNT(*),
        2
    ) AS failure_reversal_rate_pct
FROM transaction_data
GROUP BY transaction_type

ORDER BY failure_reversal_rate_pct DESC;


-- Q7 RESULT / BUSINESS INTERPRETATION
--
-- CHANNELS:
--
-- USSD       = 8.66%
-- Mobile App = 8.64%
-- POS        = 7.73%
-- Web        = 7.12%
-- ATM        = 6.87%
--
-- USSD has the highest combined failure/reversal rate, closely
-- followed by Mobile App.
--
-- TRANSACTION TYPES:
--
-- Airtime/Data    = 8.95%
-- Bill Payment    = 8.14%
-- Cash Withdrawal = 8.11%
-- Card Purchase   = 8.08%
-- Transfer        = 7.72%
-- Deposit         = 7.15%
--
-- Airtime/Data has the highest combined failure/reversal rate
-- among transaction types.
--
-- These results can help identify transaction areas that may
-- warrant further operational investigation.


-- ============================================================
-- BUSINESS QUESTION 8
-- ============================================================
-- What customer, transaction, channel, device and geographic
-- characteristics are associated with transactions flagged for
-- risk review?
--
-- IMPORTANT:
-- Risk_Review_Flag is treated as the supplied dataset label.
-- It should not automatically be interpreted as proof of fraud
-- or suspicious activity.
-- ============================================================

-- Customer segment

SELECT
    'Customer Segment' AS dimension,
    c.customer_segment AS category,
    COUNT(t.transaction_id) AS total_transactions,
    COUNT(*) FILTER (
        WHERE t.risk_review_flag = 'Yes'
    ) AS risk_review_count,
    ROUND(
        COUNT(*) FILTER (
            WHERE t.risk_review_flag = 'Yes'
        ) * 100.0 / COUNT(*),
        2
    ) AS risk_review_rate_pct
FROM transaction_data t
JOIN customer_data c
    ON t.customer_id = c.customer_id
GROUP BY c.customer_segment

UNION ALL

-- Transaction type

SELECT
    'Transaction Type' AS dimension,
    transaction_type AS category,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (
        WHERE risk_review_flag = 'Yes'
    ) AS risk_review_count,
    ROUND(
        COUNT(*) FILTER (
            WHERE risk_review_flag = 'Yes'
        ) * 100.0 / COUNT(*),
        2
    ) AS risk_review_rate_pct
FROM transaction_data
GROUP BY transaction_type

UNION ALL

-- Channel

SELECT
    'Channel' AS dimension,
    channel AS category,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (
        WHERE risk_review_flag = 'Yes'
    ) AS risk_review_count,
    ROUND(
        COUNT(*) FILTER (
            WHERE risk_review_flag = 'Yes'
        ) * 100.0 / COUNT(*),
        2
    ) AS risk_review_rate_pct
FROM transaction_data
GROUP BY channel

UNION ALL

-- Device

SELECT
    'Device' AS dimension,
    device_type AS category,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (
        WHERE risk_review_flag = 'Yes'
    ) AS risk_review_count,
    ROUND(
        COUNT(*) FILTER (
            WHERE risk_review_flag = 'Yes'
        ) * 100.0 / COUNT(*),
        2
    ) AS risk_review_rate_pct
FROM transaction_data
WHERE device_type IS NOT NULL
GROUP BY device_type

UNION ALL

-- Location

SELECT
    'Location' AS dimension,
    location AS category,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (
        WHERE risk_review_flag = 'Yes'
    ) AS risk_review_count,
    ROUND(
        COUNT(*) FILTER (
            WHERE risk_review_flag = 'Yes'
        ) * 100.0 / COUNT(*),
        2
    ) AS risk_review_rate_pct
FROM transaction_data
WHERE location IS NOT NULL
GROUP BY location

ORDER BY risk_review_rate_pct DESC;


-- Q8 RESULT / BUSINESS INTERPRETATION
--
-- CUSTOMER SEGMENT:
--
-- Premium  = 20.33%
-- Student  = 19.75%
-- SME      = 19.40%
-- Everyday = 19.29%
--
-- Premium has the highest risk-review rate among the customer
-- segments in this dataset.
--
-- TRANSACTION TYPE:
--
-- Transfer        = 28.49%
-- Cash Withdrawal = 25.31%
-- Deposit         = 16.19%
-- Airtime/Data    = 15.19%
-- Card Purchase   = 13.02%
-- Bill Payment    = 12.81%
--
-- Transfer has the highest risk-review rate among transaction
-- types.
--
-- CHANNEL:
--
-- Web        = 21.35%
-- ATM        = 21.18%
-- Mobile App = 19.40%
-- POS        = 18.35%
-- USSD       = 17.32%
--
-- Web has the highest risk-review rate among channels.
--
-- DEVICE:
--
-- ATM Terminal = 21.64%
-- Web Browser  = 20.11%
-- Android      = 19.95%
-- POS Terminal = 18.78%
-- iOS          = 18.49%
--
-- ATM Terminal has the highest risk-review rate among the
-- available device categories.
--
-- LOCATION:
--
-- Benin City   = 20.68%
-- Ibadan       = 20.58%
-- Kaduna       = 20.05%
-- Port Harcourt= 19.80%
-- Kano         = 19.66%
-- Lagos        = 19.50%
-- Enugu        = 18.87%
-- Abuja        = 18.00%
--
-- Benin City has the highest risk-review rate among the supplied
-- locations.
--
-- There are 96 missing Device_Type values and 96 missing Location
-- values. Device and location risk-review rates therefore exclude
-- those missing records.
--
-- These results identify characteristics associated with higher
-- risk-review rates. They do not establish that any particular
-- characteristic causes a transaction to be flagged.


-- ============================================================
-- OVERALL SQL ANALYSIS SUMMARY
-- ============================================================
--
-- The eight business questions provide a view of FinTrust's
-- customer and transaction behaviour during the observation
-- period.
--
-- Key findings:
--
-- 1. Digital adoption is very high at 99.80%, with 1,497 of
--    1,500 customers using at least one digital transaction
--    channel.
--
-- 2. Mobile App is the most frequently used transaction channel
--    across all customer segments.
--
-- 3. Android is the most common device category, accounting for
--    39.98% of transactions with non-missing device information.
--
-- 4. Ibadan records the highest transaction volume and total
--    transaction value among the eight supplied locations.
--
-- 5. Customer engagement and transaction activity show some
--    differences across age, income band, customer segment and
--    account type, although average engagement differences are
--    relatively modest.
--
-- 6. Transfer generates the highest total transaction value among
--    transaction types, while Mobile App generates the highest
--    total transaction value among channels.
--
-- 7. USSD has the highest combined failure/reversal rate among
--    channels, while Airtime/Data has the highest rate among
--    transaction types.
--
-- 8. Transfer transactions have the highest risk-review rate among
--    transaction types. Web has the highest rate among channels,
--    ATM Terminal among devices, Premium among customer segments,
--    and Benin City among the supplied locations.
--
-- These findings should be considered within the limitations of
-- the dataset, including the January-March 2026 observation period
-- and missing Device_Type and Location values.
-- ============================================================

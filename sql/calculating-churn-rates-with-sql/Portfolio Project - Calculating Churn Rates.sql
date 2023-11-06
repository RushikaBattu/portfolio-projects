/* Calculating Churn Rates - 

This SQL query calculates subscription churn rates for Codefix, a fictional company, focusing on two user segments acquired through 
distinct channels. It assess churn rates while adhering to a minimum subscription length requirement of 31 days.
*/


-- View the first 100 rows of the table and identify different segments
SELECT *
FROM subscriptions
LIMIT 100;


-- Determine the range of months available in the data for calculating churn
SELECT MIN(subscription_start), MAX(subscription_start)
FROM subscriptions;


-- Create a temporary table 'months' for the three months of 2017
WITH months AS
(SELECT
'2017-01-01' as first_day,
'2017-01-31' as last_day
UNION
SELECT
'2017-02-01' as first_day,
'2017-02-28' as last_day
UNION
SELECT
'2017-03-01' as first_day,
'2017-03-31' as last_day
),

-- Create a temporary table 'cross_join' by joining subscriptions with 'months'
cross_join AS
(SELECT * FROM subscriptions
CROSS JOIN months
),

-- Creating a temporary table 'status' to determine the status of each subscription
status AS
(SELECT
id,
first_day AS month,
CASE
  WHEN (subscription_start < first_day) AND
  (subscription_end > first_day 
  OR subscription_end IS NULL) AND
  (segment = 87)
  THEN 1
  ELSE 0
END AS is_active_87,
CASE
  WHEN (subscription_start < first_day) AND
  (subscription_end > first_day 
  OR subscription_end IS NULL) AND
  (segment = 30)
  THEN 1
  ELSE 0
END AS is_active_30,
CASE
  WHEN (subscription_end BETWEEN first_day AND last_day) AND
  (segment = 87)
  THEN 1 
  ELSE 0
END AS is_canceled_87,
CASE
  WHEN (subscription_end BETWEEN first_day AND last_day) AND
  (segment = 30)
  THEN 1 
  ELSE 0
END AS is_canceled_30
FROM cross_join
),

-- Create a temporary table 'status_aggregate' to summarize the status of subscriptions
status_aggregate AS
(SELECT month,
SUM (is_active_87) AS sum_active_87,
SUM (is_active_30) AS sum_active_30,
SUM (is_canceled_87) AS sum_canceled_87,
SUM (is_canceled_30) AS sum_canceled_30
FROM status
GROUP BY month
)

-- Calculate the churn rates for both segments over the three-month period
SELECT month,
1.0 * sum_canceled_87/sum_active_87 AS churn_rate_87,
1.0 * sum_canceled_30/sum_active_30 AS churn_rate_30
FROM status_aggregate;


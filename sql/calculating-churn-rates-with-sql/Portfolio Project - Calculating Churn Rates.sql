/* Calculating Churn Rates - 
This SQL query calculates subscription churn rates for a subscription services company, focusing on user segments acquired through 
distinct channels. It assess churn rates while adhering to a minimum subscription length requirement of 31 days.
*/


-- View the first 100 rows of the table and identify different segments
SELECT *
FROM subscriptions
LIMIT 100;


-- Range of months available in the data for calculating churn
SELECT MIN(subscription_start), MAX(subscription_start)
FROM subscriptions;


-- CTE for the three months available in the data
WITH months AS (
  SELECT '2017-01-01' as first_day, '2017-01-31' as last_day
  UNION
  SELECT '2017-02-01' as first_day, '2017-02-28' as last_day
  UNION
  SELECT '2017-03-01' as first_day, '2017-03-31' as last_day
),

-- CTE by cross joining subscriptions with 'months'
cross_join AS (
  SELECT s.id, m.first_day, m.last_day, s.segment, s.subscription_start, s.subscription_end
  FROM subscriptions s
  CROSS JOIN months m
),

-- CTE to determine the status of each subscription
status AS (
  SELECT
    id,
    first_day AS month,
    segment,
    CASE
      WHEN (subscription_start < first_day) AND
           (subscription_end > last_day OR subscription_end IS NULL)
      THEN 1
      ELSE 0
    END AS is_active,
    CASE
      WHEN (subscription_end BETWEEN first_day AND last_day)
      THEN 1
      ELSE 0
    END AS is_canceled
  FROM cross_join
),

-- CTE to summarize the status of subscriptions
status_aggregate AS (
  SELECT month,
    segment,
    SUM(is_active) AS sum_active,
    SUM(is_canceled) AS sum_canceled
  FROM status
  GROUP BY month, segment
)

-- Calculate the churn rates for all segments over the three-month period
SELECT 
  month,
  segment,
  1.0 * SUM(sum_canceled) / NULLIF(SUM(sum_active), 0) AS churn_rate
FROM status_aggregate
GROUP BY month, segment;

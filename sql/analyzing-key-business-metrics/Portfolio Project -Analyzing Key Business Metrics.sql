/* Analyzing Key Business Metrics - 
The SQL queries are centered on extracting key business metrics used to evaluate and improve company performance, 
drawn from a simulated food delivery startup data, which closely mimics real-world business operations. 
The primary purpose is to produce data that is readily suitable for further generating reports and analysis.

PART 1: Revenue, Cost, and Profit
PART 2: User-Centric KPIs
PART 3: ARPU, Histograms, and Percentiles
PART 4: Generating Data For Executive Reports 
*/

/* Cleaning Dates */

UPDATE orders SET order_date = STR_TO_DATE(order_date, '%m/%d/%y');
UPDATE stock SET stocking_date = STR_TO_DATE(stocking_date, '%m/%d/%y');
ALTER TABLE orders MODIFY COLUMN order_date DATE;
ALTER TABLE stock MODIFY COLUMN stocking_date DATE;


/* PART 1: Revenue, Cost, and Profit */

-- 1. Total Revenue
SELECT SUM(meal_price * order_quantity) AS revenue
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id;

-- 2. Total Cost
SELECT SUM(meal_cost * stocked_quantity) AS cost
FROM meals
JOIN stock ON meals.meal_id = stock.meal_id;

-- 3. Profit per Eatery
WITH revenue AS (
  SELECT eatery,
         SUM(meal_price * order_quantity) AS revenue
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id
  GROUP BY eatery
),

cost AS (
  SELECT eatery,
         SUM(meal_cost * stocked_quantity) AS cost
  FROM meals
  JOIN stock ON meals.meal_id = stock.meal_id
  GROUP BY eatery
)

-- Calculate profit per eatery
SELECT revenue.eatery,
       revenue.revenue - cost.cost AS profit
FROM revenue
JOIN cost ON revenue.eatery = cost.eatery
ORDER BY profit DESC;
    

-- 4. Profit per Month
WITH monthly_profit AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m-01') AS delivr_month,
        SUM(meal_price * order_quantity) AS revenue
    FROM meals
    JOIN orders ON meals.meal_id = orders.meal_id
    GROUP BY delivr_month
),

cost AS (
    SELECT
        DATE_FORMAT(stocking_date, '%Y-%m-01') AS delivr_month,
        SUM(meal_cost * stocked_quantity) AS cost
    FROM meals
    JOIN stock ON meals.meal_id = stock.meal_id
    GROUP BY delivr_month
)

-- Calculate profit per month
SELECT
    COALESCE(r.delivr_month, c.delivr_month) AS delivr_month,
    COALESCE(r.revenue, 0) - COALESCE(c.cost, 0) AS profit
FROM monthly_profit r
LEFT JOIN cost c 
ON r.delivr_month = c.delivr_month
ORDER BY STR_TO_DATE(COALESCE(r.delivr_month, c.delivr_month), '%Y-%m-01') ASC;

------

/* PART 2: User-Centric KPIs */

-- 1. Registrations running total
WITH regs AS (
  SELECT
    MIN(order_date) AS reg_date,
    COUNT(DISTINCT user_id) AS regs
  FROM orders
  GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
)

-- Calculate the registrations running total by month
SELECT
  reg_date AS delivr_month,
  regs,
  SUM(regs) OVER (ORDER BY reg_date ASC) AS regs_rt
FROM regs
ORDER BY reg_date ASC;


-- 2. Monthly Active Users (MAU) growth rate
WITH mau AS (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m-01') AS delivr_month,
    COUNT(DISTINCT user_id) AS mau
  FROM orders
  GROUP BY delivr_month
),

mau_with_lag AS (
  SELECT
    delivr_month,
    mau,
    GREATEST(LAG(mau) OVER (ORDER BY delivr_month ASC),1) AS last_mau
  FROM mau
)

-- Calculate the month-on-month MAU growth rates
SELECT
  delivr_month,
  mau,
  ROUND(IFNULL((mau - last_mau) / last_mau, 0),2) AS growth
FROM mau_with_lag
ORDER BY delivr_month ASC;


-- 3. Monthly order growth rate
WITH orders AS (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m-01') AS delivr_month,
    COUNT(DISTINCT order_id) AS orders
  FROM orders
  GROUP BY delivr_month
),

orders_with_lag AS (
  SELECT
    delivr_month,
    orders,
    COALESCE(LAG(orders) OVER (ORDER BY delivr_month ASC),1) AS last_orders
  FROM orders
)

-- Calculate the month-on-month order growth rate:
SELECT
  delivr_month,
  orders,
  ROUND(IFNULL((orders - last_orders) / last_orders, 0),2) AS growth
FROM orders_with_lag
ORDER BY delivr_month ASC;


-- 4. Monthly retention rate
WITH user_monthly_activity AS (
  SELECT 
	DISTINCT DATE_FORMAT(order_date, '%Y-%m-01') AS delivr_month,
    user_id
  FROM orders
)

-- Calculate the month-on-month retention rate
SELECT
  previous.delivr_month,
  ROUND(COUNT(DISTINCT current.user_id) / GREATEST(COUNT(DISTINCT previous.user_id), 1),2) AS retention_rate
FROM user_monthly_activity AS previous
LEFT JOIN user_monthly_activity AS current
ON previous.user_id = current.user_id
AND previous.delivr_month = (current.delivr_month - INTERVAL 1 MONTH)
GROUP BY previous.delivr_month
ORDER BY previous.delivr_month ASC;

------

/* PART 3: Unit Economics, Histograms, and Category Bucketing */

-- 1. Create a view for user revenues
DROP VIEW IF EXISTS user_revenues;

CREATE VIEW user_revenues AS
SELECT
  user_id,
  SUM(m.meal_price * o.order_quantity) AS revenue
FROM meals AS m
JOIN orders AS o ON m.meal_id = o.meal_id
GROUP BY user_id;


-- 2. Create a view for user KPIs
DROP VIEW IF EXISTS user_kpi;

CREATE VIEW user_kpi AS
SELECT
  user_id,
  COUNT(DISTINCT order_id) AS orders,
  COUNT(DISTINCT user_id) AS users
FROM orders
GROUP BY user_id;


-- 3. Average revenue per user (ARPU)
SELECT ROUND(AVG(revenue), 2) AS arpu
FROM user_revenues;

-- 4. Average orders per user
SELECT ROUND(SUM(orders) / GREATEST(SUM(users), 1), 2) AS average_orders_per_user
FROM user_kpi;

-- 5. Histogram of revenue: Frequency table of revenues by user
SELECT
  ROUND(revenue, -2) AS revenue_100,
  COUNT(DISTINCT user_id) AS users
FROM user_revenues
GROUP BY revenue_100
ORDER BY revenue_100 ASC;

-- 6. Histogram of orders: Frequency table of orders by user
SELECT
  orders,
  COUNT(DISTINCT user_id) AS users
FROM user_kpi
GROUP BY orders
ORDER BY orders ASC;

-- 7. Bucketing users by revenue
SELECT
  CASE
    WHEN revenue < 150 THEN 'Low-revenue users'
    WHEN revenue < 300 THEN 'Mid-revenue users'
    ELSE 'High-revenue users'
  END AS revenue_group,
  COUNT(DISTINCT user_id) AS users
FROM user_revenues
GROUP BY revenue_group;

-- 8. Bucketing users by orders
SELECT
  CASE
    WHEN orders < 8 THEN 'Low-orders users'
    WHEN orders < 15 THEN 'Mid-orders users'
    ELSE 'High-orders users'
  END AS order_group,
  COUNT(DISTINCT user_id) AS users
FROM user_kpi
GROUP BY order_group;

------

 /*  PART 4: Ranking and Pivots */
  
-- 1. Rank users by their count of orders
SELECT
  user_id,
  DENSE_RANK() OVER (ORDER BY count_orders DESC) AS count_orders_rank
FROM (
  SELECT
    user_id,
    COUNT(DISTINCT order_id) AS count_orders
  FROM orders
  WHERE EXTRACT(YEAR_MONTH FROM order_date) = 201808
  GROUP BY user_id
) AS user_count_orders
ORDER BY count_orders_rank ASC
LIMIT 3;


-- 2. Pivoting user revenues by month
SELECT
  user_id,
  MAX(CASE WHEN delivr_month = '2018-06-01' THEN revenue END) AS `2018-06-01`,
  MAX(CASE WHEN delivr_month = '2018-07-01' THEN revenue END) AS `2018-07-01`,
  MAX(CASE WHEN delivr_month = '2018-08-01' THEN revenue END) AS `2018-08-01`
FROM (
  SELECT
    user_id,
    DATE_FORMAT(order_date, '%Y-%m-01') AS delivr_month,
    SUM(meal_price * order_quantity) AS revenue
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id
  WHERE user_id IN (0, 1, 2, 3, 4)
    AND order_date < '2018-09-01'
  GROUP BY user_id, delivr_month
) AS subquery
GROUP BY user_id
ORDER BY user_id ASC;


-- 3. Pivoting costs per month
SELECT
  eatery,
  MAX(CASE WHEN delivr_month = '2018-11-01' THEN cost END) AS `2018-11-01`,
  MAX(CASE WHEN delivr_month = '2018-12-01' THEN cost END) AS `2018-12-01`
FROM (
  SELECT
    eatery,
    DATE_FORMAT(stocking_date, '%Y-%m-01') AS delivr_month,
    SUM(meal_cost * stocked_quantity) AS cost
  FROM meals
  JOIN stock ON meals.meal_id = stock.meal_id
  WHERE DATE_FORMAT(stocking_date, '%Y-%m-01') > '2018-10-01'
  GROUP BY eatery, delivr_month
) AS subquery
GROUP BY eatery
ORDER BY eatery ASC;


-- 4. Pivot the previous query by quarter
SELECT
  eatery,
  MAX(CASE WHEN delivr_quarter = 'Q2 2018' THEN users_rank END) AS `Q2 2018`,
  MAX(CASE WHEN delivr_quarter = 'Q3 2018' THEN users_rank END) AS `Q3 2018`,
  MAX(CASE WHEN delivr_quarter = 'Q4 2018' THEN users_rank END) AS `Q4 2018`
FROM (
  SELECT
    eatery,
    COUNT(DISTINCT user_id) AS users,
    CONCAT('Q', QUARTER(order_date), ' ', YEAR(order_date)) AS delivr_quarter,
    RANK() OVER (PARTITION BY CONCAT('Q', QUARTER(order_date), ' ', YEAR(order_date)) ORDER BY COUNT(DISTINCT user_id) DESC) AS users_rank
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id
  GROUP BY eatery, delivr_quarter
) AS subquery
GROUP BY eatery
ORDER BY `Q4 2018`;

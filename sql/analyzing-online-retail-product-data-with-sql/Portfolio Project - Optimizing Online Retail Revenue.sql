/* Optimizing Online Retail Revenue - 

The SQL query is focused on analyzing product data for an online sports retail company to enhance revenue. 
It involves handling various data types related to pricing, revenue, ratings, reviews, descriptions, and website traffic. 
The objective is to offer insights for revenue optimization, including tasks like assessing price disparities between brands, 
categorizing price ranges, and investigating the relationship between revenue and reviews. 
The goal is to help the company maximize its revenue in the sports clothing sector.
*/


-- 1. Count Missing Values

SELECT COUNT(*) AS total_rows, 
    COUNT(IF(i.description IS NOT NULL, 1, NULL)) AS count_description, 
    COUNT(IF(f.listing_price IS NOT NULL, 1, NULL)) AS count_listing_price, 
    COUNT(IF(t.last_visited IS NOT NULL, 1, NULL)) AS count_last_visited 
FROM info AS i
INNER JOIN finance AS f
    ON i.product_id = f.product_id
INNER JOIN traffic AS t
    ON t.product_id = f.product_id;
 
 
-- 2. Brands Pricing

SELECT b.brand, CAST(f.listing_price AS SIGNED) AS listing_price, COUNT(*) AS count_products
FROM finance AS f
INNER JOIN brands AS b 
    ON f.product_id = b.product_id
WHERE f.listing_price > 0
GROUP BY b.brand, listing_price
ORDER BY listing_price DESC;


-- 3. Labeling Price Ranges

SELECT b.brand, COUNT(*) AS count_products, SUM(f.revenue) AS total_revenue,
    CASE 
        WHEN f.listing_price < 42 THEN 'Budget'
        WHEN f.listing_price >= 42 AND f.listing_price < 74 THEN 'Average'
        WHEN f.listing_price >= 74 AND f.listing_price < 129 THEN 'Expensive'
        ELSE 'Elite'
    END AS price_category
FROM finance AS f
INNER JOIN brands AS b 
    ON f.product_id = b.product_id
WHERE b.brand IS NOT NULL
GROUP BY b.brand, price_category
ORDER BY total_revenue DESC;


-- 4. Average Discount by Brand

SELECT b.brand, 
       AVG(IFNULL(f.discount, 0)) * 100 AS average_discount
FROM brands AS b
INNER JOIN finance AS f 
    ON b.product_id = f.product_id
GROUP BY b.brand
HAVING b.brand IS NOT NULL
ORDER BY average_discount;


-- 5. Correlation Between Revenues and Reviews (Pearson correlation coefficient)
  
SELECT
    (SUM(r.reviews * f.revenue) - SUM(r.reviews) * SUM(f.revenue) / COUNT(r.product_id)) / 
    (SQRT((SUM(r.reviews * r.reviews) - (SUM(r.reviews) * SUM(r.reviews) / COUNT(r.product_id))) *
            (SUM(f.revenue * f.revenue) - (SUM(f.revenue) * SUM(f.revenue) / COUNT(f.product_id))))
    ) AS review_revenue_corr
FROM reviews AS r
INNER JOIN finance AS f 
    ON r.product_id = f.product_id;


-- 6. Ratings and Reviews by Product Description Length

SELECT ROUND(LENGTH(i.description), -2) AS description_length,
    ROUND(AVG(CAST(r.rating AS DECIMAL)), 2) AS average_rating
FROM info AS i
INNER JOIN reviews AS r 
    ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;


-- 7. Reviews by Month and Brand

SELECT b.brand, MONTH(t.last_visited) AS month, COUNT(*) AS num_reviews
FROM brands AS b
INNER JOIN traffic AS t 
    ON b.product_id = t.product_id
INNER JOIN reviews AS r 
    ON t.product_id = r.product_id
WHERE b.brand IS NOT NULL
    AND MONTH(t.last_visited) IS NOT NULL
GROUP BY b.brand, month
ORDER BY b.brand, month;


-- 8. Footwear Product Performance

WITH footwear AS
(
    SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f 
        ON i.product_id = f.product_id
    WHERE (LOWER(i.description) LIKE '%shoe%'
        OR LOWER(i.description) LIKE '%trainer'
        OR LOWER(i.description) LIKE '%foot%')
        AND i.description IS NOT NULL
)

SELECT
    COUNT(*) AS num_footwear_products,
    (
        SELECT AVG(revenue)
        FROM (
            SELECT revenue
            FROM footwear
            ORDER BY revenue
            LIMIT 2, 1
        ) AS subquery
    ) AS median_footwear_revenue
FROM footwear;


-- 9. Clothing Product Performance

WITH clothing AS
(
    SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f 
        ON i.product_id = f.product_id
    WHERE (LOWER(i.description) NOT LIKE '%shoe%'
        AND LOWER(i.description) NOT LIKE '%trainer'
        AND LOWER(i.description) NOT LIKE '%foot%')
        AND i.description IS NOT NULL
)

SELECT
    COUNT(*) AS num_clothing_products,
    (
        SELECT AVG(revenue)
        FROM (
            SELECT revenue
            FROM clothing
            ORDER BY revenue
            LIMIT 2, 1
        ) AS subquery
    ) AS median_clothing_revenue
FROM clothing;

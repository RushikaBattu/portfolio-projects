/* Analyze Internationl Debt Statistics - 

This SQL project utilizes The World Bank's international debt data to answer critical questions about global debt. 
It explores the total debt across listed countries, identifies the country with the highest debt, and calculates the average debt 
based on various indicators. 
The dataset spans from 1970 to 2015 and offers valuable insights into international debt trends.
*/

-- Number of Distinct Countries
SELECT 
	COUNT (DISTINCT international_debt.country_name) AS total_distinct_countries
FROM international_debt;


-- Distinct Debt Indicators
SELECT 
    DISTINCT international_debt.indicator_code AS distinct_debt_indicators
FROM international_debt
ORDER BY distinct_debt_indicators;


-- Total Debt
SELECT 
    ROUND(SUM(international_debt.debt)/1000000, 2) AS total_debt
FROM international_debt; 


-- Highest Debt Country
SELECT 
    international_debt.country_name, 
    SUM(international_debt.debt) AS total_debt
FROM international_debt
GROUP BY country_name
ORDER BY total_debt DESC
LIMIT 1;


-- Average Debt per Indicator
SELECT 
    international_debt.indicator_code AS debt_indicator,
    international_debt.indicator_name,
    AVG(international_debt.debt) AS average_debt
FROM international_debt
GROUP BY debt_indicator, indicator_name
ORDER BY average_debt DESC
LIMIT 10;


-- Highest Principal Repayment within the "DT.AMT.DLXF.CD" Debt Indicator Category
SELECT 
    international_debt.country_name, 
    international_debt.indicator_name
FROM international_debt
WHERE debt = (SELECT 
                  MAX(debt)
              FROM international_debt
              WHERE indicator_code='DT.AMT.DLXF.CD');
              
              
-- Most Common Debt Indicator
SELECT 
    indicator_code,
    COUNT(indicator_code) AS indicator_count
FROM international_debt
GROUP BY indicator_code
ORDER BY indicator_count DESC, indicator_code DESC
LIMIT 20;


-- Maximum Amount of Debt Owed per Country
SELECT 
    country_name, 
    MAX(debt) AS maximum_debt
FROM international_debt
GROUP BY country_name
ORDER BY maximum_debt DESC
LIMIT 10;
              
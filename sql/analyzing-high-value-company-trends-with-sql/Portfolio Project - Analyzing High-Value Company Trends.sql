/* Analyzing High-Value Company Trends - 
This SQL query aims to identify industries with the highest-valued companies, focusing on those worth over $1 billion, 
between 2019 and 2021.
It provides insights for potential investors, highlighting booming sectors and the annual emergence of new high-value companies, 
enabling informed investment decisions in the ever-evolving financial landscape.
*/

-- Number of new high-value companies created in 2019 - 2021 for each industry
WITH top_industries AS
(
    SELECT i.industry, 
        COUNT(*) AS industry_count
    FROM industries AS i
    INNER JOIN dates AS d
        ON i.company_id = d.company_id
    WHERE YEAR(d.date_joined) IN (2019, 2020, 2021)
    GROUP BY i.industry
    ORDER BY industry_count DESC
    LIMIT 3
),

-- Number of high-value companies, the year a company became a high-value company, and the average valuation for each industry and year
yearly_rankings AS 
(
    SELECT COUNT(*) AS num_unicorns,
        i.industry,
        YEAR(d.date_joined) AS year,
        AVG(f.valuation) AS average_valuation
    FROM industries AS i
    INNER JOIN dates AS d
        ON i.company_id = d.company_id
    INNER JOIN funding AS f
        ON d.company_id = f.company_id
    GROUP BY i.industry, year
)

-- Retrieving the industry, year, number of high-value companies, and the average valuation in billions 
-- for the top 3 industries and the specified years.
SELECT industry,
    year,
    SUM(num_unicorns) AS num_high_value_companies,
    ROUND(AVG(average_valuation / 1000000000), 2) AS average_valuation_billions
FROM yearly_rankings
WHERE year in (2019, 2020, 2021)
    AND industry in (SELECT industry
                    FROM top_industries)
GROUP BY industry, year
ORDER BY year DESC, num_unicorns DESC;

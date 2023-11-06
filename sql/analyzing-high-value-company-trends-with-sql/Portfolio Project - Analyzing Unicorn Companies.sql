/* Analyzing Unicorn Companies To Discover Investment Opportunities - 

This SQL query aims to identify industries with the highest-valued companies, focusing on those worth over $1 billion, 
between 2019 and 2021.
It provides essential insights for potential investors, highlighting booming sectors and the annual emergence of new high-value companies, 
thus enabling informed investment decisions in the ever-evolving financial landscape.

*/

-- Calculate the number of new unicorns created in the years 2019, 2020, and 2021 for each industry
WITH top_industries AS
(
    SELECT i.industry, 
        COUNT(i.*)
    FROM industries AS i
    INNER JOIN dates AS d
        ON i.company_id = d.company_id
    WHERE EXTRACT(year FROM d.date_joined) in ('2019', '2020', '2021')
    GROUP BY industry
    ORDER BY count DESC
    LIMIT 3
),

-- Calculate the number of unicorns, the year a company became a unicorn, and the average valuation for each industry and year
yearly_rankings AS 
(
    SELECT COUNT(i.*) AS num_unicorns,
        i.industry,
        EXTRACT(year FROM d.date_joined) AS year,
        AVG(f.valuation) AS average_valuation
    FROM industries AS i
    INNER JOIN dates AS d
        ON i.company_id = d.company_id
    INNER JOIN funding AS f
        ON d.company_id = f.company_id
    GROUP BY industry, year
)

-- Retrieve the industry, year, number of unicorns, and the average valuation in billions 
-- for the top 3 industries and the specified years.
SELECT industry,
    year,
    num_unicorns,
    ROUND(AVG(average_valuation / 1000000000), 2) AS average_valuation_billions
FROM yearly_rankings
WHERE year in ('2019', '2020', '2021')
    AND industry in (SELECT industry
                    FROM top_industries)
GROUP BY industry, num_unicorns, year
ORDER BY year DESC, num_unicorns DESC;


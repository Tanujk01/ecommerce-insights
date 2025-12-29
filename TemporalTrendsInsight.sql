 
 USE final_ecommerce_project;
 
 -- 4.1. What are the monthly sales trends over the past year?
 SELECT YEAR(O.OrderDate) AS `Year`,
		MONTH(O.OrderDate) AS `Month`,
        SUM(OD.Quantity * P.Price) AS Revenue
FROM orders O 
JOIN orderdetails OD ON OD.OrderID = O.OrderID
JOIN products P ON P.ProductID = OD.ProductID
WHERE O.IsReturned = False AND O.OrderDate >= CURRENT_DATE() - INTERVAL 12 MONTH
GROUP BY `Year`, `Month`
ORDER BY `Year`, `Month`;

WITH MonthlySales AS (
    SELECT 
        DATE_FORMAT(O.OrderDate, '%Y-%m') AS Month,
        SUM(OD.Quantity * P.Price) AS MonthlyRevenue
    FROM orders O
    JOIN orderdetails OD ON OD.OrderID = O.OrderID
    JOIN products P ON P.ProductID = OD.ProductID
    WHERE 
        O.IsReturned = False
        AND O.OrderDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY Month
)
SELECT 
    Month,
    MonthlyRevenue,
    LAG(MonthlyRevenue) OVER (ORDER BY Month) AS PreviousMonthRevenue,
    ROUND(
        (MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY Month))
        * 100 / NULLIF(LAG(MonthlyRevenue) OVER (ORDER BY Month), 0),
        2
    ) AS MoM_Growth_Percent
FROM MonthlySales
ORDER BY Month;

-- 4.2. How does the average order value (AOV) change by month or week?

SELECT DATE_FORMAT(O.OrderDate, '%Y-%m') AS Period,
		ROUND(
				CAST(SUM(OD.Quantity * P.Price) AS DECIMAL(10,2))/ NULLIF(COUNT(DISTINCT O.OrderID),0), 2
			  ) AS AOV
FROM orders O 
JOIN orderdetails OD ON OD.OrderID = O.OrderID 
JOIN products P ON P.ProductID = OD.ProductID
WHERE O.IsReturned = False 
GROUP BY Period
ORDER BY Period;

-- 4.3. Order volume trend by month
WITH OrdersByMonth AS (
    SELECT 
        DATE_FORMAT(O.OrderDate, '%Y-%m') AS Month,
        COUNT(DISTINCT O.OrderID) AS MonthlyOrders
    FROM orders O
    WHERE O.IsReturned = False
    GROUP BY Month
)
SELECT 
    Month,
    MonthlyOrders,
    ROUND(
        ((MonthlyOrders - LAG(MonthlyOrders) OVER(ORDER BY Month)) * 100) /
        NULLIF(LAG(MonthlyOrders) OVER(ORDER BY Month), 0),
        2
    ) AS MoMOrderVolumeGrowthPercent
FROM OrdersByMonth
ORDER BY Month;

-- 4.4. Seasonal patterns in revenue (peak vs off-season months)

WITH RevenueByMonth AS(
		SELECT MONTH(O.OrderDate) AS MonthNumber,
				MONTHNAME(O.OrderDate) AS MonthName,
                SUM(OD.Quantity * P.Price) AS MonthlyRevenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
        GROUP BY MonthNumber, MonthName
),
RankedMonths AS(
		SELECT *,
				NTILE(4) OVER(ORDER BY MonthlyRevenue DESC) RevenueQuartile
		FROM RevenueByMonth
)
SELECT MonthNumber, MonthName, MonthlyRevenue,
		CASE WHEN RevenueQuartile = 1 THEN 'Peak Season'
			 WHEN RevenueQuartile = 4 THEN 'Off-Season'
             ELSE 'Normal'
		END AS SeasonType
FROM RankedMonths
ORDER BY MonthlyRevenue DESC;

-- 4.5. Comparison of weekday vs weekend sales performance

WITH OrderDayType AS(
		SELECT O.OrderID,
			CASE WHEN DAYOFWEEK(O.OrderDate) IN(1,7) THEN 'Weekend'
				 ELSE 'Weekday'
			END AS DayType,
            OD.Quantity * P.Price AS OrderRevenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
)
SELECT DayType,
		SUM(OrderRevenue) AS TotalRevenue,
        COUNT(DISTINCT OrderID) AS TotalOrders,
        ROUND(
					CAST(SUM(OrderRevenue) AS DECIMAL(10,2))/ NULLIF( COUNT(DISTINCT OrderID), 0), 2
			  ) AS AOV -- AOV = Average Order Value
FROM OrderDayType
GROUP BY DayType
ORDER BY TotalRevenue DESC;
		
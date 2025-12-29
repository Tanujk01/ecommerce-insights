
USE final_ecommerce_project;
-- 5.1. Which regions have the highest order volume and which have the lowest?

WITH OrderVolumeByRegion AS (
    SELECT R.RegionName,
           COUNT(DISTINCT O.OrderID) AS OrderVolume
    FROM orders O
    JOIN customers C ON C.CustomerID = O.CustomerID
    JOIN regions R ON R.RegionID = C.RegionID
    WHERE O.IsReturned = False
    GROUP BY R.RegionName
),
RankedOrderVolume AS (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY OrderVolume DESC) AS VolumeRankDesc,
           DENSE_RANK() OVER (ORDER BY OrderVolume ASC) AS VolumeRankAsc
    FROM OrderVolumeByRegion
)
SELECT RegionName,
       OrderVolume,
       CASE 
           WHEN VolumeRankDesc = 1 THEN 'Highest'
           WHEN VolumeRankAsc = 1 THEN 'Lowest'
           ELSE 'Middle'
       END AS VolumeType
FROM RankedOrderVolume
ORDER BY OrderVolume DESC;

-- 5.2. What is the revenue per region and how does it compare across different regions?

WITH RevenueByRegion AS (
    SELECT R.RegionName,
           SUM(OD.Quantity * P.Price) AS Revenue
    FROM orders O
    JOIN orderdetails OD ON OD.OrderID = O.OrderID
    JOIN products P ON P.ProductID = OD.ProductID
    JOIN customers C ON C.CustomerID = O.CustomerID
    JOIN regions R ON R.RegionID = C.RegionID
    WHERE O.IsReturned = False
    GROUP BY R.RegionName
),
RankedRevenue AS (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY Revenue DESC) AS RevenueRank
    FROM RevenueByRegion
)
SELECT RegionName, Revenue, RevenueRank,
       CASE
           WHEN RevenueRank = 1 THEN 'Highest'
           WHEN RevenueRank <= 3 THEN 'High'
           WHEN RevenueRank <= 5 THEN 'Medium'
           ELSE 'Lower'
       END AS RevenueType
FROM RankedRevenue
ORDER BY Revenue DESC;

-- 5.3. Average order value (AOV) by region

SELECT R.RegionName, 
		ROUND(
			(SUM(OD.Quantity * P.Price) * 1.0)/ NULLIF( COUNT(DISTINCT O.OrderID), 0), 2
			) AS AvgOrderValue
FROM orders O 
JOIN customers C ON C.CustomerID = O.CustomerID
JOIN regions R ON C.RegionID = R.RegionID
JOIN orderdetails OD ON OD.OrderID = O.OrderID
JOIN products P ON P.ProductID = OD.ProductID
WHERE O.IsReturned = False
GROUP BY R.RegionName
ORDER BY AvgOrderValue DESC;

-- 5.4. Revenue contribution % by region

WITH RevenueByRegion AS(
		SELECT R.RegionName,
				SUM(OD.Quantity * P.Price) AS Revenue,
                SUM(SUM(OD.Quantity * P.Price)) OVER() AS TotalRevenue
		FROM orders O 
        JOIN customers C ON C.CustomerID = O.CustomerID
        JOIN regions R ON R.RegionID = C.RegionID
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
        GROUP BY R.RegionName
)
SELECT RegionName, Revenue,
		ROUND(
				(Revenue * 100.0) / (NULLIF( TotalRevenue , 0)), 2
			) AS RevenueContributionPercent
FROM RevenueByRegion
ORDER BY Revenue DESC;

-- 5.5. Region-wise product category performance

SELECT R.RegionName, P.Category,
		SUM(OD.Quantity * P.Price) AS Revenue,
        COUNT(DISTINCT O.OrderID) AS TotalOrders,
        SUM(OD.Quantity) AS TotalQtySold
FROM orders O 
JOIN orderdetails OD ON OD.OrderID = O.OrderID 
JOIN customers C ON C.CustomerID = O.CustomerID
JOIN products P ON P.ProductID = OD.ProductID
JOIN regions R ON R.RegionID = C.RegionID
WHERE O.IsReturned = False
GROUP BY R.RegionName, P.Category
ORDER BY Revenue DESC;

-- Above query with ranking and revenue contribution %
WITH RegionCategoryMetrics AS (
    SELECT
        R.RegionName,
        P.Category,
        SUM(OD.Quantity * P.Price) AS CategoryRevenue,
        COUNT(DISTINCT O.OrderID) AS TotalOrders,
        SUM(OD.Quantity) AS TotalQtySold
    FROM orders O
    JOIN orderdetails OD ON OD.OrderID = O.OrderID
    JOIN customers C ON C.CustomerID = O.CustomerID
    JOIN products P ON P.ProductID = OD.ProductID
    JOIN regions R ON R.RegionID = C.RegionID
    WHERE O.IsReturned = False
    GROUP BY R.RegionName, P.Category
),
RegionTotals AS (
    SELECT
        RegionName,
        SUM(CategoryRevenue) AS RegionRevenue
    FROM RegionCategoryMetrics
    GROUP BY RegionName
)
SELECT
    RCM.RegionName,
    RCM.Category,
    RCM.CategoryRevenue,
    RCM.TotalOrders,
    RCM.TotalQtySold,

    -- Rank category inside each region
    DENSE_RANK() OVER (
        PARTITION BY RCM.RegionName
        ORDER BY RCM.CategoryRevenue DESC
    ) AS CategoryRankInRegion,

    -- Contribution % of category within region
    ROUND(
        (RCM.CategoryRevenue * 100.0) /
        NULLIF(RT.RegionRevenue, 0),
        2
    ) AS CategoryRevenueContributionPercent

FROM RegionCategoryMetrics RCM
JOIN RegionTotals RT
    ON RCM.RegionName = RT.RegionName
ORDER BY RCM.RegionName, CategoryRankInRegion;











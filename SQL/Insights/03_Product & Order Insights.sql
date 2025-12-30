
USE final_ecommerce_project;

-- 3.1. What are the top 10 most sold products (by quantity)?
WITH TopProducts AS(
SELECT OD.ProductID, P.ProductName, SUM(OD.Quantity) AS TotalQuantitySold,
		DENSE_RANK() OVER(ORDER BY SUM(OD.Quantity) DESC) AS Ranking
FROM orderdetails OD
JOIN products P ON P.ProductID = OD.ProductID
JOIN orders O ON O.OrderID = OD.OrderID
WHERE O.IsReturned = False 
GROUP BY OD.ProductID, P.ProductName
)
SELECT ProductID, ProductName, TotalQuantitySold, Ranking
FROM TopProducts
WHERE Ranking < 11
ORDER BY Ranking;

-- 3.2. What are the top 10 most sold products (by revenue)? AND also Revenue contribution % of top 10 products
WITH TopProducts AS(
		SELECT OD.ProductID, P.ProductName, SUM(OD.Quantity * P.Price) AS ProductRevenue,
				DENSE_RANK() OVER( ORDER BY SUM(OD.Quantity * P.Price) DESC) AS ProductRevenueRank,
                SUM(SUM(OD.Quantity * P.Price)) OVER () AS TotalRevenue
		FROM orderdetails OD 
        JOIN products P ON P.ProductID = OD.ProductID
        JOIN orders O ON O.OrderID = OD.OrderID
        WHERE O.IsReturned = False 
        GROUP BY OD.ProductID, P.ProductName
)
SELECT ProductID, ProductName, ProductRevenue,
		ROUND(
				(ProductRevenue/ TotalRevenue)*100, 2
            ) AS ProductContributionPercent
		, ProductRevenueRank
FROM TopProducts
WHERE ProductRevenueRank <= 10
ORDER BY ProductRevenueRank;

-- Top products by region (by revenue)
WITH RegionProductRevenue AS(
		SELECT R.RegionName, P.ProductID, P.ProductName,
				SUM(OD.Quantity * P.Price) AS Revenue
		FROM orders O 
        JOIN customers C ON C.CustomerID = O.CustomerID 
        JOIN regions R ON R.RegionID = C.RegionID
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
        GROUP BY R.RegionName, P.ProductID, P.ProductName
)
SELECT *, 
		DENSE_RANK() OVER(PARTITION BY RegionName ORDER BY Revenue DESC) AS RegionRanking
FROM RegionProductRevenue
ORDER BY  RegionName, RegionRanking;

-- 3.3. Which products have the highest return rate?

WITH ReturnedOrders AS(
		SELECT P.ProductID, P.ProductName,COUNT( DISTINCT OD.OrderID) AS TotalReturnedOrders
		FROM orderdetails OD
		JOIN orders O ON O.OrderID = OD.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
		WHERE O.Isreturned =True
		GROUP BY P.ProductID,P.ProductName
),
TotalOrdersPerProduct AS(
		SELECT P.ProductID,P.ProductName, COUNT( DISTINCT OD.OrderID) AS TotalOrders
		FROM orderdetails OD
        JOIN products P ON P.ProductID = OD.ProductID
		GROUP BY P.ProductID, P.ProductName
)
SELECT TOP.ProductID,TOP.ProductName, COALESCE(RO.TotalReturnedOrders,0) AS TotalReturnedOrders, TOP.TotalOrders,
		ROUND(
			    (COALESCE(RO.TotalReturnedOrders,0)/ NULLIF(TOP.TotalOrders,0)) * 100, 2
              ) AS ReturnRate
FROM TotalOrdersPerProduct TOP
LEFT JOIN ReturnedOrders RO ON TOP.ProductID = RO.ProductID
ORDER BY ReturnRate DESC;

-- 3.4. Return Rate by Category

WITH ReturnedCategory AS (
		SELECT P.Category, COUNT(DISTINCT OD.OrderID) AS ReturnedCategoryOrders
        FROM orderdetails OD
        JOIN products P ON P.ProductID = OD.ProductID
        JOIN orders O ON O.OrderID = OD.OrderID
        WHERE O.IsReturned = True
        GROUP BY P.Category
),
TotalOrdersPerCategory AS(
		SELECT P.Category, COUNT(DISTINCT OD.OrderID) AS TotalOrders
        FROM orderdetails OD
        JOIN products P ON P.ProductID = OD.ProductID
        GROUP BY P.Category
)
SELECT RC.Category, COALESCE(RC.ReturnedCategoryOrders,0) AS ReturnedOrders, TOC.TotalOrders,
		ROUND(
				(COALESCE(RC.ReturnedCategoryOrders,0) *100)/ NULLIF(TOC.TotalOrders,0), 2
			  ) AS ReturnRate
FROM TotalOrdersPerCategory TOC
LEFT JOIN ReturnedCategory RC ON RC.Category = TOC.Category
ORDER BY ReturnRate DESC;

-- 3.5. What is the average price of products per region? [Avg Price = (Total Revenue / Total Qty)]

SELECT R.RegionName, 
		ROUND(
				(SUM(OD.Quantity * P.Price) / NULLIF(SUM(OD.Quantity), 0 )), 2
              ) AS AvgPrice
FROM orderdetails OD 
JOIN products P ON P.ProductID = OD.ProductID
JOIN orders O ON O.OrderID = OD.OrderID
JOIN customers C ON C.CustomerID = O.CustomerID
JOIN regions R ON R.RegionID = C.RegionID
 WHERE O.IsReturned = False
GROUP BY R.RegionName
ORDER BY AvgPrice DESC;

-- 3.6. What is the sales trend for each product category?
-- MoM By Category
WITH MonthlyRevenueByCategory AS(
		SELECT P.Category, DATE_FORMAT(O.OrderDate, '%Y-%m') AS `Month`,
				SUM(OD.Quantity * P.Price) AS Revenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
        GROUP BY P.Category, `Month`
)
SELECT *,
		ROUND(
				(((Revenue - LAG(Revenue) OVER(PARTITION BY Category ORDER BY `Month`))*100)/ NULLIF(LAG(Revenue) OVER(PARTITION BY Category ORDER BY `Month`) ,0)), 2
			  ) AS CategoryMoMGrowthPercent
FROM MonthlyRevenueByCategory;

-- YoY By Category
With YearlyRevenueByCategory AS(
		SELECT P.Category, YEAR(O.OrderDate) AS `Year`,
				SUM( OD.Quantity * P.Price) AS Revenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False 
        GROUP BY P.Category, `Year`
)
SELECT *,
		ROUND(
				((Revenue - LAG(Revenue) OVER(PARTITION BY Category ORDER BY `Year`))*100 / NULLIF(LAG(Revenue) OVER(PARTITION BY Category ORDER BY `Year`),0)), 2
           ) AS CategoryYoYGrowthPercent
FROM YearlyRevenueByCategory;

-- Monthly YOY (Same Month Last Year)
WITH MonthlyRevenueByCategory AS(
		SELECT P.Category, 
				YEAR(O.OrderDate) AS `Year`,
                MONTH(O.OrderDate) AS `Month`,
                SUM(OD.Quantity * P.Price) AS Revenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False 
        GROUP BY P.Category,  `Year`, `Month`
)
SELECT *,
		LAG(Revenue) OVER(PARTITION BY Category, `Month` ORDER BY `Year`) AS LastYearSameMonthRevenue,
        ROUND(
				(Revenue - LAG(Revenue) OVER(PARTITION BY Category, `Month` ORDER BY `Year`)) * 100 / 
                   NULLIF(LAG(Revenue) OVER(PARTITION BY Category, `Month` ORDER BY `Year`), 0)
                , 2
			  ) AS MonthlyYoYGrowthPercent
FROM MonthlyRevenueByCategory
ORDER BY Category,  `Month`,`Year`;

-- 3.7. Products contributing to top 80% of revenue

WITH ProductRevenue AS(
		SELECT P.ProductID, P.ProductName,
				SUM(OD.Quantity * P.Price) AS Revenue
		FROM orderdetails OD 
        JOIN products P ON P.ProductID = OD.ProductID
        JOIN orders O ON O.OrderID = OD.OrderID
        GROUP BY P.ProductID, P.ProductName
),
RevenueComulative AS(
		SELECT *,
				SUM(Revenue) OVER(ORDER BY Revenue DESC) AS ComulativeRevenue,
                SUM(Revenue) OVER() AS TotalRevenue
		FROM ProductRevenue
)
SELECT *,
		ROUND(
					(ComulativeRevenue * 100 / NULLIF(TotalRevenue, 0)), 2
               ) AS CumulativeRevenuePercent
FROM RevenueComulative
WHERE (ComulativeRevenue/ NULLIF(TotalRevenue, 0)) <= 0.80
ORDER BY Revenue DESC;

-- 3.8. Products with declining sales trends over time

WITH MonthlyProductRevenue AS(
		SELECT P.ProductID, P.ProductName,
			DATE_FORMAT(O.OrderDate, '%Y-%m') AS `Month`,
			SUM(OD.Quantity * P.Price) AS Revenue
        FROM orderdetails OD
        JOIN products P ON P.ProductID = OD.ProductID
        JOIN orders O ON O.OrderID = OD.OrderID
        WHERE O.IsReturned = False 
        GROUP BY P.ProductID, P.ProductName, `Month`
),
RevenueTrend AS(
		SELECT *,
				(Revenue - LAG(Revenue) OVER(PARTITION BY ProductID ORDER BY `Month`)) AS RevenueChange
                FROM MonthlyProductRevenue
)
SELECT DISTINCT ProductID, ProductName
FROM RevenueTrend
WHERE RevenueChange < 0
ORDER BY ProductName;

-- 3.9. Average order quantity per product

SELECT P.ProductID, P.ProductName, 
		ROUND(
			SUM(OD.Quantity)/ NULLIF( COUNT( DISTINCT OD.OrderID), 0),2
              ) AS AvgOrderQty
FROM orderdetails OD
JOIN products P ON P.ProductID = OD.ProductID
JOIN orders O ON O.OrderID = OD.OrderID
WHERE O.IsReturned = False
GROUP BY P.ProductID, P.ProductName
ORDER BY AvgOrderQty DESC;

-- 3.10. Category-wise revenue vs quantity comparison (price-driven vs volume-driven)

WITH CategoryMetrics AS (
    SELECT 
        P.Category,
        SUM(OD.Quantity) AS TotalQuantity,
        SUM(OD.Quantity * P.Price) AS TotalRevenue
    FROM orders O
    JOIN orderdetails OD ON OD.OrderID = O.OrderID
    JOIN products P ON P.ProductID = OD.ProductID
    WHERE O.IsReturned = False
    GROUP BY P.Category
),
OverAllTotal AS (
    SELECT 
        SUM(TotalQuantity) AS OverAllQty,
        SUM(TotalRevenue) AS OverAllRevenue
    FROM CategoryMetrics
),
CategoryShare AS (
    SELECT 
        CM.Category,
        CM.TotalQuantity,
        CM.TotalRevenue,
        CAST(CM.TotalQuantity AS DECIMAL(12,4)) / NULLIF(OAT.OverAllQty, 0) AS QuantityRatio,
        CAST(CM.TotalRevenue AS DECIMAL(12,4)) / NULLIF(OAT.OverAllRevenue, 0) AS RevenueRatio
    FROM CategoryMetrics CM
    CROSS JOIN OverAllTotal OAT
)
SELECT 
    Category,
    TotalQuantity,
    TotalRevenue,
    ROUND(QuantityRatio * 100, 2) AS QuantityPercent,
    ROUND(RevenueRatio * 100, 2) AS RevenuePercent,
    CASE 
        WHEN RevenueRatio > QuantityRatio THEN 'Price Driven'
        WHEN RevenueRatio < QuantityRatio THEN 'Volume Driven'
        ELSE 'Balanced'
    END AS CategoryType
FROM CategoryShare
ORDER BY RevenuePercent DESC;

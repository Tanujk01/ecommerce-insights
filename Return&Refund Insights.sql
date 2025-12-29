
USE final_ecommerce_project;
-- 6.1. What is the overall return rate by product category?

WITH CategoryOrders AS (
    SELECT
        P.Category,
        COUNT(DISTINCT O.OrderID) AS TotalOrders,
        COUNT(DISTINCT CASE 
            WHEN O.IsReturned = TRUE THEN O.OrderID 
        END) AS ReturnedOrders
    FROM orders O
    JOIN orderdetails OD ON OD.OrderID = O.OrderID
    JOIN products P ON P.ProductID = OD.ProductID
    GROUP BY P.Category
)
SELECT
    Category,
    ReturnedOrders,
    TotalOrders,
    ROUND(
        (ReturnedOrders * 100.0) / NULLIF(TotalOrders, 0),
        2
    ) AS ReturnRatePercent
FROM CategoryOrders
ORDER BY ReturnRatePercent DESC;

-- 6.2. What is the overall return rate by region?

WITH RegionOrders AS(
		SELECT R.RegionName,
				COUNT(DISTINCT O.OrderID) AS TotalOrders,
                COUNT(DISTINCT CASE WHEN O.IsReturned = True THEN  O.OrderID END) AS ReturnedOrders
		FROM orders O 
        JOIN customers C ON C.CustomerID = O.CustomerID
        JOIN regions R ON R.RegionID = C.RegionID
        GROUP BY R.RegionName
)
SELECT RegionName, ReturnedOrders, TotalOrders,
		ROUND(
				(ReturnedOrders * 100.0) / NULLIF( TotalOrders, 0), 2 
			  ) AS ReturnRatePercent
FROM RegionOrders
ORDER BY ReturnRatePercent DESC;

-- Region - Category return rate matrix
WITH CategoryRegionMatrix AS(
		SELECT R.RegionID, R.RegionName, P.Category,
				COUNT(DISTINCT O.OrderID) AS TotalOrders,
                COUNT(DISTINCT CASE WHEN O.IsReturned = True THEN O.OrderID END) AS ReturnedOrders
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        JOIN customers C ON C.CustomerID = O.CustomerID
        JOIN regions R ON R.RegionID = C.RegionID
        GROUP BY R.RegionID, R.RegionName, P.Category
)
SELECT RegionID, RegionName, Category, ReturnedOrders, TotalOrders,
		ROUND(
				((ReturnedOrders * 100.0)/ NULLIF(TotalOrders, 0)), 2
			  ) AS ReturnRatePercent
FROM CategoryRegionMatrix
ORDER BY ReturnRatePercent DESC;

-- 6.3. Which customers are making frequent returns?
WITH ReturnsByCustomers AS(
	SELECT C.CustomerID, C.CustomerName,
			COUNT(DISTINCT CASE WHEN O.IsReturned = True THEN O.OrderID END) AS ReturnedOrders,
			COUNT(DISTINCT O.OrderID) AS TotalOrders
	FROM orders O 
	JOIN customers C ON C.CustomerID = O.CustomerID
	GROUP BY C.CustomerID, C.CustomerName
)
SELECT *,
		 ROUND(
					((ReturnedOrders * 100.0)/ NULLIF(TotalOrders, 0)) , 2
			  ) AS ReturnRatePercent
FROM ReturnsByCustomers
WHERE ReturnedOrders >= 4
ORDER BY ReturnRatePercent DESC;

-- 6.4. Revenue loss due to returns (absolute & percentage)

WITH RevenueCalculate AS(
		SELECT SUM( CASE WHEN O.IsReturned = True THEN (OD.Quantity * P.Price)  ELSE 0 END) AS RevenueReturned,
				SUM(OD.Quantity * P.Price) AS TotalRevenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
)
SELECT     TotalRevenue, RevenueReturned AS AbsoluteRevenueLoss,
		(TotalRevenue - RevenueReturned) AS NetRevenue,
		ROUND(
				(( RevenueReturned * 100.0)/ NULLIF(TotalRevenue, 0) ), 2
			  ) AS RevenueLossPercent
FROM RevenueCalculate;

-- 6.5. Products with highest return impact on revenue

WITH RevenueCal AS (
		SELECT P.ProductID, P.ProductName,
				SUM( CASE WHEN O.IsReturned = True THEN ( OD.Quantity * P.Price) ELSE 0 END) AS RevenueReturned,
				SUM(OD.Quantity * P.Price) AS TotalRevenue
		FROM orders O 
		JOIN orderdetails OD ON OD.OrderID = O.OrderID
		JOIN products P ON P.ProductID = OD.ProductID
		GROUP BY P.ProductID, P.ProductName
)
SELECT *,
		ROUND(
				((RevenueReturned * 100.0)/ NULLIF(TotalRevenue, 0)), 2
			  ) AS ReturnImpactPercent
FROM RevenueCal
ORDER BY ReturnImpactPercent DESC;

-- 6.6. Return rate comparison: repeat customers vs new customers

WITH IdentifyCustomer AS (
		SELECT  C.CustomerID,
					CASE WHEN COUNT(DISTINCT O.OrderID) = 1 THEN 'New Customer'
					ELSE 'Repeat Customer'
					END AS CustomerType
		FROM customers C 
        JOIN orders O ON O.CustomerID = C.CustomerID
		GROUP BY C.CustomerID
)
SELECT CustomerType,
		COUNT(DISTINCT CASE WHEN O.IsReturned = True THEN O.OrderID END) AS ReturnedOrders,
		COUNT(DISTINCT O.OrderID) AS TotalOrders,
        ROUND(
				((COUNT(DISTINCT CASE WHEN O.IsReturned = True THEN O.OrderID END) * 100.0)/ NULLIF(COUNT(DISTINCT O.OrderID), 0)), 2
			 ) AS ReturnRatePercent
FROM IdentifyCustomer IC
JOIN orders O ON O.CustomerID = IC.CustomerID
GROUP BY CustomerType
ORDER BY ReturnRatePercent DESC;
             


        


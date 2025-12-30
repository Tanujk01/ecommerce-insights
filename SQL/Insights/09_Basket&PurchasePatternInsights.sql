USE final_ecommerce_project;
-- 9.1. Average number of items per order

SELECT ROUND(AVG(TotalItems), 2) AS AvgNoOfItemsPerOrder
FROM ( SELECT OrderID,
			  SUM(Quantity) AS TotalItems
		FROM orderdetails
        GROUP BY OrderID
		) T;
        
-- 9.2. Most common product category combinations in a single order

WITH CategoryCombinations AS(
		SELECT OD.OrderID, 
				GROUP_CONCAT(DISTINCT P.Category ORDER BY P.Category SEPARATOR ', ') AS CombinedCategory,
                COUNT(DISTINCT P.Category) AS CategoryCount
		FROM orderdetails OD
		JOIN products P ON P.ProductID = OD.ProductID
		GROUP BY OD.OrderID
)
SELECT CombinedCategory, COUNT(OrderID) AS CombinationCount
FROM CategoryCombinations
WHERE CategoryCount > 1
GROUP BY CombinedCategory
ORDER BY CombinationCount DESC;

-- 9.3. Revenue generated from multi-item orders vs single-item orders

WITH OrderRevenue AS (
    SELECT 
        OD.OrderID,
        SUM(OD.Quantity) AS TotalItems,
        SUM(OD.Quantity * P.Price) AS Revenue
    FROM orderdetails OD
    JOIN products P ON P.ProductID = OD.ProductID
    JOIN orders O ON O.OrderID = OD.OrderID
    WHERE O.IsReturned = False
    GROUP BY OD.OrderID
)
SELECT 
    CASE 
        WHEN TotalItems = 1 THEN 'Single-item Order'
        ELSE 'Multi-item Order'
    END AS OrderType,
    SUM(Revenue) AS Revenue
FROM OrderRevenue
GROUP BY OrderType;
        
-- 9.4. High-value baskets (orders with large quantities or high total value)

WITH OrderLevelMetrics AS (
		SELECT O.OrderID,
				SUM(OD.Quantity) AS TotalQuantity,
                SUM(OD.Quantity * P.Price) AS TotalOrderValue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
        GROUP BY O.OrderID
),
OrderAverages AS(
		SELECT AVG(TotalQuantity) AS AvgQuantity,
				AVG(TotalOrderValue) AS AvgOrderValue
		FROM OrderLevelMetrics
)
SELECT OLM.OrderID, OLM.TotalQuantity, OLM.TotalOrderValue,
		CASE WHEN OLM.TotalQuantity >= OA.AvgQuantity AND OLM.TotalOrderValue >= OA.AvgOrderValue THEN 'High Quantity & High Value'
			 WHEN OLM.TotalQuantity >= OA.AvgQuantity THEN 'High Quantity Basket'
             WHEN OLM.TotalOrderValue >= OA.AvgOrderValue THEN 'High Value Basket'
             ELSE 'Normal Basket'
		END AS 'Basket Type'
FROM OrderLevelMetrics OLM
CROSS JOIN OrderAverages OA
ORDER BY OLM.TotalOrderValue DESC;

-- 9.5. Order value distribution based on basket size

WITH OrderBasket AS (
		SELECT O.OrderID,
				SUM(OD.Quantity) AS BasketSize,
                SUM(OD.Quantity * P.Price) AS OrderValue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
        GROUP BY O.OrderID
)

SELECT CASE WHEN BasketSize = 1 THEN '1 Item'
			WHEN BasketSize BETWEEN 2 AND 3 THEN '2-3 Items'
			WHEN BasketSize BETWEEN 4 AND 5 THEN '4-5 Items'
            WHEN BasketSize BETWEEN 6 AND 10 THEN '6-10 Items'
            ELSE '10+ Items'
		END AS BasketSizeGroup,
        COUNT(DISTINCT OrderID) AS TotalOrders,
        ROUND( AVG(OrderValue), 2) AS AvgOrderValue,
        ROUND( SUM(OrderValue), 2) AS TotalRevenue
FROM OrderBasket
GROUP BY BasketSizeGroup
ORDER BY TotalRevenue DESC;



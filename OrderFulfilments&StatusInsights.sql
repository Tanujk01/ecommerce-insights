USE final_ecommerce_project;
-- 8.1. Distribution of orders by status (Completed, Returned)

SELECT COUNT(DISTINCT OrderID) AS TotalOrders,
		COUNT(DISTINCT CASE WHEN IsReturned = True THEN OrderID END) AS ReturnedOrders,
        COUNT(DISTINCT CASE WHEN IsReturned = False THEN OrderID END) AS CompletedOrders
FROM orders;
        
-- 8.2. Order completion rate Vs Return Rate across the entire period

SELECT ROUND(
				(COUNT(DISTINCT CASE WHEN IsReturned = False THEN OrderID END) * 100.0)/ NULLIF( COUNT(DISTINCT OrderID), 0), 2
			  ) AS CompletionRatePercent,
		ROUND(
				(COUNT(DISTINCT CASE WHEN IsReturned = True THEN OrderID END) * 100.0)/ NULLIF( COUNT(DISTINCT OrderID), 0), 2
			  ) AS ReturnRatePercent
FROM orders;
		
-- 8.5. Trend of completed vs returned orders over time

SELECT DATE_FORMAT(OrderDate, '%Y-%M') AS `Month`,
		COUNT(DISTINCT OrderID) AS TotalOrders,
        COUNT(DISTINCT CASE WHEN IsReturned = False THEN OrderID END) AS CompletedOrders,
        COUNT(DISTINCT CASE WHEN IsReturned = True THEN OrderID END) AS ReturnedOrders,
        ROUND(
				(COUNT(DISTINCT CASE WHEN IsReturned = False THEN OrderID END) * 100.0)/ NULLIF( COUNT(DISTINCT OrderID), 0), 2
			  ) AS CompletionRatePercent,
		ROUND(
				(COUNT(DISTINCT CASE WHEN IsReturned = True THEN OrderID END) * 100.0)/ NULLIF( COUNT(DISTINCT OrderID), 0), 2
			  ) AS ReturnRatePercent
FROM orders
GROUP BY `Month`
ORDER BY MIN(OrderDate);




USE final_ecommerce_project;

-- 2.1. Who are the top 10 customers by total revenue spent?

SELECT C.CustomerID, C.CustomerName, SUM(OD.Quantity * P.Price) AS TotalSpent
FROM orderdetails OD 
JOIN products P ON P.ProductID = OD.ProductID
JOIN orders O ON O.OrderID = OD.OrderID
JOIN customers C ON C.CustomerID = O.CustomerID
WHERE O.IsReturned = False
GROUP BY C.CustomerID, C.CustomerName
ORDER BY TotalSpent DESC
LIMIT 10;
-- WITH RANK FUNCTION 
WITH CustomerRevenue AS(
		SELECT C.CustomerID, C.CustomerName, SUM(OD.Quantity * P.Price) AS TotalSpent
		FROM orderdetails OD 
		JOIN products P ON P.ProductID = OD.ProductID
		JOIN orders O ON O.OrderID = OD.OrderID
		JOIN customers C ON C.CustomerID = O.CustomerID
		WHERE O.IsReturned = False 
		GROUP BY C.CustomerID, C.CustomerName
),
RankedCustomers AS(
		SELECT CustomerID, CustomerName, TotalSpent,
				DENSE_RANK() OVER(ORDER BY TotalSpent DESC) AS RankedRevenue
		FROM CustomerRevenue
)
SELECT CustomerID, CustomerName, TotalSpent, RankedRevenue
FROM RankedCustomers
WHERE RankedRevenue < 11;

-- Top customers with contribution %
WITH CustomerRevenue AS (
		SELECT C.CustomerID, C.CustomerName, SUM(OD.Quantity * P.Price) AS TotalSpent
        FROM orderdetails OD
        JOIN products P ON P.ProductID = OD.ProductID
        JOIN orders O ON O.OrderID = OD.OrderID
        JOIN customers C ON C.CustomerID = O.CustomerID
        WHERE O.IsReturned = FALSE
        GROUP BY C.CustomerID, C.CustomerName
),
RankedCustomers AS (
		SELECT CustomerID, CustomerName, TotalSpent, 
				DENSE_RANK() OVER(ORDER BY TotalSpent DESC) AS RankedRevenue,
                SUM(TotalSpent) OVER() AS TotalRevenue
        FROM CustomerRevenue
)
SELECT CustomerID, CustomerName, TotalSpent,
		 ROUND(
				((TotalSpent/ NULLIF(TotalRevenue, 0 )) * 100) ,2
                )AS ContributionPercent,
		RankedRevenue
FROM RankedCustomers
WHERE RankedRevenue < 11;

-- 2.2. What is the repeat customer rate?  [Repeat Customers Rate = (cusomer with more then 1 order) / (customer with at last 1 order)]
SELECT ROUND((COUNT( DISTINCT CASE WHEN OrderCount > 1 THEN CustomerID END)/ NULLIF(COUNT(DISTINCT CustomerID),0))*100 ,2)AS RepeatCustomerRate
FROM (SELECT CustomerID, COUNT(OrderID) AS OrderCount
		FROM orders
        WHERE IsReturned = FALSE
		GROUP BY CustomerID) T;
        
-- 2.3. What is the average time between two consecutive orders for the same customer (Region-wise)?
WITH RankedOrders AS(
		SELECT O.CustomerID, O.OrderDate, C.RegionID,
				ROW_NUMBER() OVER(PARTITION BY O.CustomerID ORDER BY O.OrderDate ) AS rn
	    FROM orders O 
        JOIN customers C ON C.CustomerID = O.CustomerID
),
OrderPairs AS(
		SELECT curr.CustomerID, curr.RegionID, DATEDIFF(curr.OrderDate,`prev`.OrderDate) DaysBetWeen
        FROM RankedOrders curr
        JOIN RankedOrders `prev` ON curr.CustomerID = `prev`.CustomerID AND curr.rn =`prev`.rn+1
),
Region AS(
		SELECT CustomerID, RegionName, DaysBetWeen
        FROM OrderPairs OP
        JOIN regions R ON OP.RegionID = R.RegionID
)
SELECT RegionName, ROUND(AVG(DaysBetWeen),2) AvgDaysBetween
FROM Region
GROUP BY RegionName
ORDER BY AvgDaysBetween;

-- 2.4. Customer Segment (based on total spend)
-- • Platinum: Total Spend > 1500
-- • Gold: 1000–1500
-- • Silver: 500–999
--   • Bronze: < 500

WITH CustomerSpend AS(
		SELECT O.CustomerID, SUM( OD.Quantity * P.Price ) AS TotalSpend
        FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = FALSE
        GROUP BY O.CustomerID
)
SELECT C.CustomerName,
		CASE WHEN TotalSpend > 1500 THEN 'Platinum'
			 WHEN TotalSpend BETWEEN 1000 AND 1500 THEN 'Gold'
             WHEN TotalSpend BETWEEN 500 AND 999 THEN 'Silver'
             ELSE 'Bronze'
		END AS Segment
FROM CustomerSpend CS
JOIN customers C ON C.CustomerID = CS.CustomerID;

-- 2.5. What is the customer lifetime value (CLV)?  [CLV = Total Revenue per customer] 

SELECT C.CustomerID, C.CustomerName, SUM(OD.Quantity * P.Price) AS CLV
FROM orderdetails OD 
JOIN products P ON P.ProductID = OD.ProductID
JOIN orders O ON O.OrderID = OD.OrderID
JOIN customers C ON C.CustomerID = O.CustomerID
WHERE O.IsReturned = False
GROUP BY C.CustomerID, C.CustomerName
ORDER BY CLV DESC;

-- 2.6. Average order value by customer segment
WITH CustomerSegment AS (
		SELECT O.CustomerID, 
				CASE 
						WHEN SUM(OD.Quantity * P.Price) > 1500 THEN 'Platinum'
                        WHEN SUM(OD.Quantity * P.Price) BETWEEN 1000 AND 1500 THEN 'Gold'
                        WHEN SUM(OD.Quantity * P.Price) BETWEEN 500 AND 999 THEN 'Silver'
                        ELSE 'Bronze'
				END AS Segment
	  FROM orders O 
      JOIN orderdetails OD ON OD.OrderID = O.OrderID
      JOIN products P ON P.ProductID = OD.ProductID
      WHERE O.IsReturned = False
      GROUP BY O.CustomerID
),
OrderRevenue AS(
		SELECT O.CustomerID, O.OrderID,
				SUM(OD.Quantity * P.Price) AS OrderValue
		FROM orders O
    JOIN orderdetails OD ON OD.OrderID = O.OrderID
    JOIN products P ON P.ProductID = OD.ProductID
    WHERE O.IsReturned = FALSE
    GROUP BY O.OrderID, O.CustomerID
)
SELECT CS.Segment,
		ROUND(
				SUM(ORV.OrderValue)/  COUNT(DISTINCT ORV.OrderID ),2
				) AS AverageOrderValue
FROM OrderRevenue ORV
JOIN CustomerSegment CS ON CS.CustomerID = ORV.CustomerID
GROUP BY CS.Segment
ORDER BY AverageOrderValue DESC;

-- 2.7. Revenue contribution by each customer segment
WITH CustomerSegment AS(
		SELECT O.CustomerID, 
			CASE	
				WHEN SUM(OD.Quantity * P.Price) > 1500 THEN 'Platinum'
                WHEN SUM(OD.Quantity * P.Price) BETWEEN 1000 AND 1500 THEN 'Gold'
                WHEN SUM(OD.Quantity * P.Price) BETWEEN 500 AND 999 THEN 'Silver'
			    ELSE 'Bronze'
			END AS Segment
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
        GROUP BY O.CustomerID
),
SegmentRevenue AS(
		SELECT CS.Segment, 
				SUM(OD.Quantity * P.Price) AS RevenueSegment
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        JOIN CustomerSegment CS ON CS.CustomerID = O.CustomerID
        WHERE O.IsReturned = False
        GROUP BY CS.Segment
)
SELECT Segment,RevenueSegment,
		ROUND(
				(RevenueSegment/ SUM(RevenueSegment) OVER()) *100, 2
			) SegmentContributioPercent
FROM SegmentRevenue
ORDER BY SegmentContributioPercent DESC;

-- 2.8. New vs repeats customers revenue split

WITH CustomerOrders AS(
		SELECT CustomerID,
				COUNT(OrderID) AS OrderCount
		FROM orders
        WHERE IsReturned = False
        GROUP BY CustomerID
),
CustomerType AS(
		SELECT CustomerID, 
				CASE WHEN OrderCount = 1 THEN 'New Customer'
					 ELSE 'Repeat Customer'
			    END AS CustomerType
		FROM CustomerOrders
),
CustomerRevenue AS(
		SELECT CustomerType,
				SUM(OD.Quantity * P.Price) AS Revenue
		FROM orders O 
        JOIN CustomerType CT ON CT.CustomerID = O.CustomerID
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
        GROUP BY CustomerType
)
SELECT CustomerType, Revenue,
		ROUND(
				(Revenue / SUM(Revenue) OVER())*100,2
			   ) AS RevenueContributionPercent
FROM CustomerRevenue;

-- 2.9. Customers with highest number of orders (frequency-based ranking)

SELECT CustomerID,
		COUNT(DISTINCT OrderID) AS OrderCount,
        DENSE_RANK() OVER(ORDER BY COUNT( DISTINCT OrderID) DESC) AS Ranking
FROM orders
WHERE IsReturned = False
GROUP BY CustomerID;

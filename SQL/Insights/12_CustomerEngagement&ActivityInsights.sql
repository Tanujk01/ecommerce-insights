USE final_ecommerce_project;

-- 12.1. Average number of orders per customer

WITH OrdersPerCustomer AS (
		SELECT CustomerID, COUNT(OrderID) AS OrderCount
		FROM orders
		GROUP BY CustomerID
)
SELECT 
    ROUND(AVG(OrderCount), 2) AS AvgOrdersPerCustomer
FROM OrdersPerCustomer;

-- 12.2. Customer inactivity rate (customers with only one order)

WITH OrderCountByCustomer AS(
		SELECT CustomerID, COUNT(DISTINCT OrderID) AS OrderCount
		FROM orders
        WHERE IsReturned = False
		GROUP BY CustomerID
),
CustomerSummary AS(
		SELECT COUNT(DISTINCT CustomerID) AS TotalCustomer,
				COUNT( DISTINCT CASE WHEN OrderCount = 1 THEN CustomerID END) AS InactiveCustomer,
                COUNT( DISTINCT CASE WHEN OrderCount > 1 THEN CustomerID END) AS ActiveCustomer
		FROM OrderCountByCustomer
)
SELECT  TotalCustomer, InactiveCustomer, ActiveCustomer,
		ROUND(
				(InactiveCustomer * 100.0)/ NULLIF(TotalCustomer, 0 ), 2
			 ) AS InactiveCustomerPercent,
	   ROUND(
				(ActiveCustomer * 100.0)/ NULLIF(TotalCustomer, 0 ), 2
			 ) AS ActiveCustomerPercent
FROM CustomerSummary;

-- 12.3. Time gap between first and last order per customer

WITH CustomerOrderLifecycle AS(
		SELECT CustomerID, COUNT(DISTINCT OrderID) AS PurchaseCount, 
				MAX(OrderDate) AS LatestOrderDate, MIN(OrderDate) AS FirstOrderDate, DATEDIFF(MAX(OrderDate), MIN(OrderDate)) AS TimeGap
		FROM orders
        WHERE IsReturned = False
		GROUP BY CustomerID
)
SELECT CustomerID, PurchaseCount, LatestOrderDate, FirstOrderDate, TimeGap,
		CASE WHEN TimeGap = 0 AND PurchaseCount =1 THEN 'One Time Buyer'
			 WHEN TimeGap = 0 AND PurchaseCount > 1 THEN 'Same Day Repeat Buyer'
			 WHEN TimeGap < 30 THEN 'Short-term Buyer'
             WHEN TimeGap < 180 THEN 'Mid-term Buyer'
             ELSE 'Long-term Buyer'
		END AS CustomerType
FROM CustomerOrderLifecycle
ORDER BY TimeGap DESC;

-- 12.4. Revenue contribution from highly active customers

WITH CustomerOrders AS(
		SELECT CustomerID,
				COUNT(DISTINCT OrderID) AS PurchaseCount
		FROM orders O
        WHERE IsReturned = False
        GROUP BY CustomerID
),
CustomerRevenue AS(
		SELECT O.CustomerID,
				SUM(OD.Quantity * P.Price) AS Revenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        WHERE O.IsReturned = False
        GROUP BY O.CustomerID
),
CustomerClassification AS(
		SELECT CR.CustomerID, CR.Revenue,
				CASE WHEN PurchaseCount >= 5 THEN 'Highly Active Customer'
					 ELSE 'Others'
				END AS CustomerType
		FROM CustomerRevenue CR 
        JOIN CustomerOrders CO ON CO.CustomerID = CR.CustomerID
),
RevenueSummary AS (
		SELECT SUM(Revenue) AS TotalRevenue,
				SUM(CASE WHEN CustomerType = 'Highly Active Customer' THEN Revenue ELSE 0 END) AS HighlyActiveCustomerRevenue
		FROM CustomerClassification
)
SELECT TotalRevenue, HighlyActiveCustomerRevenue,
		ROUND(
				(HighlyActiveCustomerRevenue * 100.0) / NULLIF( TotalRevenue, 0), 2
			  ) AS HighlyActiveCustomerRevenuePercentContribution
FROM RevenueSummary;

-- 12.5. Order frequency trend over time

WITH OrdersByMonth AS (
		SELECT DATE_FORMAT(OrderDate, '%Y-%m-01') MonthDate,
			   DATE_FORMAT(OrderDate, '%Y-%M') MonthLabel,
			   COUNT(DISTINCT OrderID) TotalOrders
		FROM orders 
        WHERE IsReturned = False
		GROUP BY MonthDate, MonthLabel
)
SELECT MonthLabel,TotalOrders,
		ROUND(
					(TotalOrders - LAG(TotalOrders) OVER(ORDER BY MonthDate )) * 100.0 / NULLIF(LAG(TotalOrders) OVER(ORDER BY MonthDate ), 0), 2
			  ) AS MoM_Growth_OrderPercent
FROM OrdersByMonth;
		




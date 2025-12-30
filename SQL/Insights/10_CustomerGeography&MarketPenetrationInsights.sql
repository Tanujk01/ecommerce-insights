USE final_ecommerce_project;

-- 10.1. Number of active customers per region

SELECT R.RegionName,
		COUNT(DISTINCT O.CustomerID) AS ActiveCustomers
FROM orders O 
JOIN customers C ON C.CustomerID = O.CustomerID
JOIN regions R ON R.RegionID = C.RegionID
GROUP BY R.RegionName
ORDER BY ActiveCustomers DESC;

-- 10.2. Average revenue per customer by region

SELECT RegionName, AVG(TotalRevenue) AS AvgRevenue
FROM (SELECT R.RegionName, C.CustomerID, C.CustomerName,
				SUM(OD.Quantity * P.Price) AS TotalRevenue 
		FROM orders O 
		JOIN orderdetails OD ON OD.OrderID = O.OrderID
		JOIN products P ON P.ProductID = OD.ProductID
		JOIN customers C ON C.CustomerID = O.CustomerID
		JOIN regions R ON R.RegionID = C.RegionID
		WHERE O.IsReturned = False
		GROUP BY R.RegionName, C.CustomerID, C.CustomerName) T
GROUP BY RegionName
ORDER BY AvgRevenue DESC;

-- 10.3. Regions with high order volume but low revenue (price sensitivity)

SELECT R.RegionName, 
		COUNT(DISTINCT O.OrderID) AS TotalOrders,
        SUM(OD.Quantity * P.Price) AS Revenue,
		ROUND(
				((SUM(OD.Quantity * P.Price) * 1.0)
				/ NULLIF(COUNT(DISTINCT O.OrderID), 0)), 2
    ) AS AvgRevenuePerOrder
FROM orders O 
JOIN orderdetails OD ON OD.OrderID = O.OrderID
JOIN products P ON P.ProductID = OD.ProductID
JOIN customers C ON C.CustomerID = O.CustomerID
JOIN regions R ON R.RegionID = C.RegionID
WHERE O.IsReturned = False
GROUP BY R.RegionName
ORDER BY TotalOrders DESC , Revenue ASC;

-- 10.4. Regions contributing to top percentage of total revenue

WITH RevenueByRegion AS(
		SELECT R.RegionName,
				SUM(OD.Quantity * P.Price) AS Revenue,
				SUM(SUM(OD.Quantity * P.Price)) OVER() AS TotalRevenue
		FROM orders O 
		JOIN orderdetails OD ON OD.OrderID = O.OrderID
		JOIN products P ON P.ProductID = OD.ProductID
		JOIN customers C ON C.CustomerID = O.CustomerID
		JOIN regions R ON R.RegionID = C.RegionID
		WHERE O.IsReturned = False
		GROUP BY R.RegionName
)
SELECT RegionName, Revenue, 
		ROUND(
					(Revenue * 100.0) / NULLIF(TotalRevenue, 0) , 2
			  ) AS RevenueContributionPercent
FROM RevenueByRegion
ORDER BY RevenueContributionPercent DESC;
	
-- 10.5. Regional growth trend in revenue over time

WITH RegionalRevenue AS(
		SELECT  R.RegionName,
				DATE_FORMAT(O.OrderDate, '%Y-%m-01') AS MonthDate,
                DATE_FORMAT(O.OrderDate, '%Y-%M') AS MonthLabel,
                SUM(OD.Quantity * P.Price) AS Revenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        JOIN customers C ON C.CustomerID = O.CustomerID
        JOIN regions R ON R.RegionID = C.RegionID
        WHERE O.IsReturned = False
        GROUP BY R.RegionName, MonthDate, MonthLabel
)
SELECT RegionName, MonthLabel AS `Month`, Revenue,
	   ROUND(
				((Revenue - LAG(Revenue) OVER (PARTITION BY RegionName ORDER BY MonthDate)) * 100.0)/
					NULLIF(LAG(Revenue) OVER (PARTITION BY RegionName ORDER BY MonthDate),0) , 2
			 ) AS Regional_MoM_RevenueGrowth
FROM RegionalRevenue
ORDER BY RegionName, MonthDate;


















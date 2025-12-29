
USE final_ecommerce_project;

-- GENERAL SALES INSIGHT --

-- 1.1. What is the total revenue generated over the entire period?  HINT- Total Revenue = SUM(Quantity * Price)

SELECT SUM(OD.Quantity * P.Price) AS TotalRevenue
FROM orderdetails OD
JOIN products P ON P.ProductID = OD.ProductID;

-- 1.2. Revenue Excluding Returned Orders

SELECT SUM(OD.Quantity * P.Price) AS Revenue_ExludingReturns
FROM orderdetails OD
JOIN products P ON P.ProductID = OD.ProductID
JOIN orders O ON O.OrderID = OD.OrderID
WHERE O.IsReturned = False;

-- 1.3. Total Revenue per Year / Month

SELECT YEAR(O.OrderDate) AS `Year`, 
		MONTH(O.OrderDate) AS `Month`,
        SUM(OD.Quantity * P.Price) AS MonthlyRevenue
FROM orderdetails OD
JOIN products P ON P.ProductID = OD.ProductID
JOIN orders O ON O.OrderID = OD.OrderID
GROUP BY `Year`, `Month`
ORDER BY `Year` DESC, `Month` DESC;

-- 1.4. Revenue by Product / Category

SELECT P.ProductName AS Product, 
		P.Category AS Category,
        SUM(OD.Quantity * P.Price) AS ProductRevenue
FROM orderdetails OD
JOIN products P ON P.ProductID = OD.ProductID
GROUP BY Product, Category
ORDER BY Category, ProductRevenue DESC;
-- Revenue By Category
SELECT P.Category AS Category,
        SUM(OD.Quantity * P.Price) AS ProductRevenue
FROM orderdetails OD
JOIN products P ON P.ProductID = OD.ProductID
GROUP BY Category
ORDER BY ProductRevenue DESC;

-- 1.5. What is the average order value (AOV) across all orders? HINT -  AOV = Total Revenue / Number Of Orders

SELECT AVG(TotalOrderValue) AS AverageOrderVale
FROM (SELECT O.OrderID, SUM(OD.Quantity * P.Price) AS TotalOrderValue 
		FROM orders O 
		JOIN orderdetails OD ON OD.OrderID = O.OrderID
		JOIN products P ON P.ProductID = OD.ProductID
		GROUP BY O.OrderID) T;

-- 1.6. AOV per Year / Month

SELECT YEAR(OrderDate) AS `Year`,
		MONTH(OrderDate) AS `Month`,
        AVG(TotalOrderValue) AS AverageOrderValue
FROM(SELECT O.OrderID, O.OrderDate, SUM(OD.Quantity * P.Price) AS TotalOrderValue
	FROM orders O 
	JOIN orderdetails OD ON OD.OrderID = O.OrderID
	JOIN products P ON P.ProductID = OD.ProductID
	GROUP BY O.OrderID) T
GROUP BY `Year` , `Month`
ORDER BY `Year` DESC , `Month` DESC;

-- 1.7. What is the average order size by region?

SELECT RegionName,AVG(TotalOrderSize) AS AvgOrderSize
FROM (SELECT R.RegionName, OD.OrderID, SUM(OD.Quantity) AS TotalOrderSize
		FROM orderdetails OD
		JOIN orders O ON O.OrderID = OD.OrderID 
		JOIN customers C ON C.CustomerID = O.CustomerID
		JOIN regions R ON R.RegionID = C.RegionID
		GROUP BY R.RegionName, OD.OrderID)T
GROUP BY RegionName
ORDER BY AvgOrderSize DESC;

-- 1.8. Gross Revenue vs Net Revenue comparison (impact of returns)  HINT - Return Impact = Gross Revenue − Net Revenue 

SELECT SUM(OD.Quantity * P.Price) AS GorssRevenue,
		SUM( CASE WHEN O.IsReturned = False THEN (OD.Quantity * P.Price)
			  ELSE 0 
			  END ) AS NetRevenue,
		SUM( CASE WHEN O.IsReturned = True THEN (OD.Quantity * P.Price)
			  ELSE 0 
			  END ) AS ReturnedRevenue,
    
       ROUND( SUM(
            CASE
                WHEN O.IsReturned = TRUE THEN OD.Quantity * P.Price
                ELSE 0
            END
        ) * 100.0 / SUM(OD.Quantity * P.Price),2)
 AS ReturnImpactPercentage
FROM orders O 
JOIN orderdetails OD ON OD.OrderID = O.OrderID
JOIN products P ON P.ProductID = OD.ProductID;

-- 1.9. Month-over-Month (MoM), Year-over-Year (YoY) , Monthly YOY revenue growth
-- MoM
WITH MonthlyRevenue AS(
	SELECT DATE_FORMAT(O.OrderDate, '%Y-%m') AS `Month`,
			SUM(OD.Quantity * P.Price) AS Revenue
	FROM orders O 
    JOIN orderdetails OD ON OD.OrderID = O.OrderID
    JOIN products P ON P.ProductID = OD.ProductID
    GROUP BY `Month`
)
SELECT `Month`, Revenue,
		LAG(Revenue) OVER(ORDER BY `Month`) AS PrevMonthRevenue,
        ROUND(
				(((Revenue - LAG(Revenue) OVER(ORDER BY `Month`)) *100) / NULLIF(LAG(Revenue) OVER(ORDER BY `Month`),0)),2                
                ) AS MoM_Growth_Percent
FROM MonthlyRevenue;
-- YoY
WITH YearlyRevenue AS(
	SELECT YEAR(O.OrderDate) AS `Year`,
			SUM(OD.Quantity * P.Price) AS Revenue
	FROM orders O 
	JOIN orderdetails OD ON OD.OrderID = O.OrderID
	JOIN products P ON P.ProductID = OD.ProductID
	GROUP BY `Year`
)
SELECT `Year`, Revenue,
		LAG(Revenue) OVER(ORDER BY `Year`) AS PrevYearRevenue,
        ROUND(
				((Revenue - LAG(Revenue) OVER(ORDER BY `Year`))*100)/NULLIF(LAG(Revenue) OVER(ORDER BY `Year`),0) ,2
				) AS YoY_Growth_Percent
FROM YearlyRevenue;
-- Monthly YOY (Same Month Last Year)

WITH MonthlyRevenue AS(
		SELECT YEAR(O.OrderDate) AS `Year`,
				MONTH(O.OrderDate) AS `Month`,
                DATE_FORMAT(O.OrderDate, '%Y-%m') AS YearMonth,
                SUM(OD.Quantity * P.Price) AS Revenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        GROUP BY `Year`,`Month`,YearMonth
)
SELECT `Year`, `Month`, YearMonth,Revenue,
        LAG(Revenue) OVER(PARTITION BY `Month` ORDER BY `Year`) AS LastYearSameMonthRevenue,
        ROUND(
				((Revenue - LAG(Revenue) OVER(PARTITION BY `Month` ORDER BY `Year`))*100)/NULLIF(LAG(Revenue) OVER(PARTITION BY `Month` ORDER BY `Year`),0),2
				) AS Monthly_YoY_Growth_Percent
FROM MonthlyRevenue;

-- 1.10. Highest and lowest revenue months in the entire period

WITH MonthlyRevenue AS(
		SELECT DATE_FORMAT(O.OrderDate, '%Y-%m') AS YearMonth,
				SUM(OD.Quantity * P.Price) AS Revenue
		FROM orders O 
        JOIN orderdetails OD ON OD.OrderID = O.OrderID
        JOIN products P ON P.ProductID = OD.ProductID
        GROUP BY YearMonth
),
RankedMonths AS(
		SELECT YearMonth, Revenue,
				RANK() OVER(ORDER BY Revenue DESC) AS HighRank,
				RANK() OVER(ORDER BY Revenue ASC) AS LowRank
		FROM MonthlyRevenue        
)
SELECT YearMonth, Revenue
FROM RankedMonths
WHERE HighRank = 1 OR LowRank = 1;

-- 1.11. Contribution % of top products/categories to total revenue
-- By Categories Contribution %
WITH CategoryRevenue AS(
		SELECT P.Category, SUM(OD.Quantity * P.Price) AS CategoryRevenue
        FROM orderdetails OD 
        JOIN products P ON P.ProductID = OD.ProductID
        GROUP BY P.Category
),
RankedCategories AS(
		SELECT Category, CategoryRevenue,
				DENSE_RANK() OVER(ORDER BY CategoryRevenue DESC) AS RevenueRank,
				SUM(CategoryRevenue) OVER() AS TotalRevenue
		FROM CategoryRevenue
)
SELECT Category, CategoryRevenue,
	   ROUND(
				(CategoryRevenue/TotalRevenue)*100,2
			) AS ContributionPercent,
            RevenueRank
FROM RankedCategories
ORDER BY RevenueRank;

-- By Top Product Contribution %
WITH ProductRevenue AS(
		SELECT P.ProductName, SUM(OD.Quantity * P.Price) AS ProductRevenue
        FROM orderdetails OD 
        JOIN products P ON P.ProductID = OD.ProductID
        GROUP BY P.ProductName
),
RankedProducts AS(
		SELECT ProductName, ProductRevenue,
			DENSE_RANK() OVER(ORDER BY ProductRevenue DESC) AS RevenueRank,
			SUM(ProductRevenue) OVER() AS TotalRevenue
        FROM ProductRevenue
)
SELECT ProductName, ProductRevenue,
	   ROUND(
					(ProductRevenue/NULLIF(TotalRevenue,0)) * 100 ,2
            ) AS ContributionPercent, 
	   (SUM(ProductRevenue) OVER(ORDER BY ProductRevenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
								) / TotalRevenue) * 100 AS CumulativeContributionPercent,
		RevenueRank
FROM RankedProducts
WHERE RevenueRank < 11
ORDER BY RevenueRank;


        
		




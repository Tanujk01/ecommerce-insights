-- Create database script
CREATE DATABASE final_ecommerce_project;
USE final_ecommerce_project;

CREATE TABLE regions(
RegionID INT PRIMARY KEY,
RegionName VARCHAR(100),
Country VARCHAR(100)
);

CREATE TABLE customers(
CustomerID INT PRIMARY KEY,
CustomerName VARCHAR(100),
Email VARCHAR(100),
Phone VARCHAR(20),
RegionID INT,
CreatedAt DATE,
FOREIGN KEY (RegionID) REFERENCES regions(RegionID)
);

CREATE TABLE products(
ProductID INT PRIMARY KEY,
ProductName VARCHAR(100),
Category VARCHAR(100),
Price DECIMAL(10,2)
);

CREATE TABLE orders(
OrderID INT PRIMARY KEY,
CustomerID INT,
OrderDate DATE,
IsReturned BOOLEAN,
FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID)
);

CREATE TABLE orderdetails(
OrderDetailID INT PRIMARY KEY,
OrderID INT,
ProductID INT,
Quantity INT,
FOREIGN KEY (OrderID) REFERENCES orders(OrderID),
FOREIGN KEY (ProductID) REFERENCES products(ProductID)
);

ALTER TABLE customers
MODIFY COLUMN Phone VARCHAR(40);





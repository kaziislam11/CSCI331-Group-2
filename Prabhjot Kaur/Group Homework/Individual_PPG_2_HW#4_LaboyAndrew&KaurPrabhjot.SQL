---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 04 - Subqueries
-- � Itzik Ben-Gan 
---------------------------------------------------------------------


---------------------------------------------------------------------
-- Self-Contained Subqueries
---------------------------------------------------------------------


---------------------------------------------------------------------
-- Scalar Subqueries
---------------------------------------------------------------------


-- Order with the maximum order ID
/*  CHAPTER 4 PROPOSITIONS:
Proposition 1: Use a subquery to find the most recent order and filter results based on the highest OrderId to track the lastest transactions in the system 
Solution 1: We can make a query that selects from the orders table and filter the results using a condition that comapres the OrderID to the maximum orderID allowing the query to return the latest order.

Proposition 2: We can have a case where we use a multi valued subquery with IN to retrieve orders placed by employees with a specific last name pattern so we can filter data based on employee groups
Solution 2: We can write a query that finds employee IDs based on a name pattern and then use that list with the IN operator to return the orders handled only by those employees. 

Proposition 3: Identifying customers who did not palce any orders by using NOT IN and NOT EXISTS to track inactive customers.
Solution 3: We will compare all customers against the orders table and return only those who do not appear in it. This is done by checking for missing matches between the two tables.

Proposition 4: We can montior a customers recent activity by using a corrlated subquery to return the latest order per customer. 
Solution 4: We can build a subquery that checks each customers orders and selects the highest or most recent order for that specific customer.

Proposition 5: Calculating a percentage contribution of each order to the cutomers total spending amount so we can understand how much each order contributes to overall revenue.
Solution 5: We first calculate the total amount spent by each customer, then compare each order amount against that total to determine its percentage contribution.

--SCALAR FUNCTION QUERY----
 */
CREATE OR ALTER FUNCTION dbo.GetFiscalQuarter (@InputDate DATE)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @FiscalYear INT;
    DECLARE @Quarter INT;

    IF MONTH(@InputDate) >= 10
        SET @FiscalYear = YEAR(@InputDate) + 1; --Check for month input. Add 1 to calender year for fiscal
    ELSE
        SET @FiscalYear = YEAR(@InputDate); --else jan-sep do nothing

    SET @Quarter = CASE    --Assign month to quarters
        WHEN MONTH(@InputDate) IN (10, 11, 12) THEN 1  
        WHEN MONTH(@InputDate) IN (1, 2, 3)    THEN 2
        WHEN MONTH(@InputDate) IN (4, 5, 6)    THEN 3
        WHEN MONTH(@InputDate) IN (7, 8, 9)    THEN 4
    END;

    RETURN 'FY' + CAST(@FiscalYear AS VARCHAR) + ' Q' + CAST(@Quarter AS VARCHAR); --return results
END;

SELECT 
    dbo.GetFiscalQuarter(OrderDate) AS FiscalQuarter, --call function for each order date
    COUNT(OrderID) AS TotalOrders, --orders exsits
    SUM(Freight) AS TotalFreight, 
    MAX(OrderDate) AS LatestDateInQuarter --recent data (for sorting)
FROM Sales.[Order] --order keyword and error prevention
GROUP BY dbo.GetFiscalQuarter(OrderDate) 
ORDER BY MAX(OrderDate) DESC; --sort

--------------------------------------------------------------------------------------------------------

DECLARE @maxid AS INT = (SELECT MAX(OrderId)
                         FROM Sales.[Order]);


SELECT OrderId, OrderDate, EmployeeId, CustomerId --Retrive order with highest OrderID 
FROM Sales.[Order]
WHERE OrderId = @maxid;




SELECT OrderId, orderdate, EmployeeId, CustomerId -- Retrive order with highest OrderID but by usinf maximum OrderID
FROM Sales.[Order]
WHERE OrderId = (SELECT MAX(O.OrderId)
                 FROM Sales.[Order] AS O);


--2 Scalar subquery expected to return one value
SELECT OrderId
FROM Sales.[Order]
WHERE EmployeeId =                     -- last name start with C
  (SELECT E.EmployeeId
   FROM HumanResources.Employee AS E
   WHERE E.EmployeeLastName LIKE N'C%');
GO


SELECT OrderId
FROM Sales.[Order]
WHERE EmployeeId = 
  (SELECT E.EmployeeId                         -- Last name D
   FROM HumanResources.Employee AS E
   WHERE E.EmployeeLastName LIKE N'D%');
GO


SELECT OrderId
FROM Sales.[Order]
WHERE EmployeeId =                      -- Last name A
  (SELECT E.EmployeeId
   FROM HumanResources.Employee AS E
   WHERE E.EmployeeLastName LIKE N'A%');


---------------------------------------------------------------------
--3 Multi-Valued Subqueries
---------------------------------------------------------------------


SELECT OrderId
FROM Sales.[Order]
WHERE EmployeeId IN
  (SELECT E.EmployeeId                --All orders handled by employees with last name starting with D
   FROM HumanResources.Employee AS E
   WHERE E.EmployeeLastName LIKE N'D%');


SELECT O.OrderId
FROM HumanResources.Employee AS E
  INNER JOIN Sales.[Order] AS O
    ON E.EmployeeId = O.EmployeeId   --All orders handled by employees with last name starting with D but by joining employee and orders table
WHERE E.EmployeeLastName LIKE N'D%';


--4 Orders placed by US customers
SELECT CustomerId, OrderId, OrderDate, EmployeeId
FROM Sales.[Order]                     --returns orders that belong to customers with given value 
WHERE CustomerId IN
  (SELECT C.CustomerId
   FROM Sales.Customer AS C
   WHERE C.CustomerCompanyName = N'USA');


--5 Customers who placed no orders
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId NOT IN       -- Customer who do not appear in the table
  (SELECT O.CustomerId
   FROM Sales.[Order] AS O);


-- Missing order IDs

DROP TABLE IF EXISTS dbo.[Order];
CREATE TABLE dbo.[Order](OrderId INT NOT NULL CONSTRAINT PK_Orders PRIMARY KEY);


INSERT INTO dbo.[Order](OrderId)
  SELECT OrderId                                            
  FROM Sales.[Order]
  WHERE OrderId % 2 = 0;


SELECT digit
FROM dbo.Digits
WHERE digit BETWEEN (SELECT MIN(O.OrderId) FROM dbo.[Order] AS O)
            AND (SELECT MAX(O.OrderId) FROM dbo.[Order] AS O)
  AND digit NOT IN (SELECT O.OrderId FROM dbo.[Order] AS O);


-- CLeanup
DROP TABLE IF EXISTS dbo.[Order]; --removes table


---------------------------------------------------------------------
-- Correlated Subqueries
---------------------------------------------------------------------


-- Orders with maximum order ID for each customer
-- Listing 4-1: Correlated Subquery
USE TSQLV4;


SELECT CustomerId, OrderId, OrderDate, EmployeeId
FROM Sales.[Order] AS O1
WHERE OrderId =
  (SELECT MAX(O2.OrderId)
   FROM Sales.[Order] AS O2
   WHERE O2.CustomerId = O1.CustomerId);


SELECT MAX(O2.OrderId)
FROM Sales.[Order] AS O2
WHERE O2.CustomerId = 85;


-- Percentage of customer total

SELECT O1.OrderId,
       O1.CustomerId,
       SUM(OD.LineAmount) AS val,
       CAST(100.0 * SUM(OD.LineAmount) /
           (SELECT SUM(OD2.LineAmount)
            FROM Sales.[Order] O2
            JOIN Sales.OrderDetail OD2
                 ON O2.OrderId = OD2.OrderId
            WHERE O2.CustomerId = O1.CustomerId)
       AS NUMERIC(5,2)) AS pct
FROM Sales.[Order] O1
JOIN Sales.OrderDetail OD
     ON O1.OrderId = OD.OrderId
GROUP BY O1.OrderId, O1.CustomerId
ORDER BY O1.CustomerId, O1.OrderId;


---------------------------------------------------------------------
-- EXISTS
---------------------------------------------------------------------


-- Customers from Spain who placed orders
SELECT CustomerId, CustomerCompanyName 
FROM Sales.Customer AS C
WHERE CustomerCountry = N'Spain'
  AND EXISTS
    (SELECT * FROM Sales.[Order] AS O
     WHERE O.CustomerId = C.CustomerId);


-- Customers from Spain who didn't place Orders
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer AS C
WHERE CustomerCountry = N'Spain'
  AND NOT EXISTS
    (SELECT * FROM Sales.[Order] AS O
     WHERE O.CustomerId = C.CustomerId);


---------------------------------------------------------------------
-- Beyond the Fundamentals of Subqueries
-- (Optional, Advanced)
---------------------------------------------------------------------


---------------------------------------------------------------------
-- Returning "Previous" or "Next" Value
---------------------------------------------------------------------
SELECT OrderId, orderdate, EmployeeId, CustomerId,
  (SELECT MAX(O2.OrderId)
   FROM Sales.[Order] AS O2
   WHERE O2.OrderId < O1.OrderId) AS prevorderid
FROM Sales.[Order] AS O1;


SELECT OrderId, orderdate, EmployeeId, CustomerId,
  (SELECT MIN(O2.OrderId)
   FROM Sales.[Order] AS O2
   WHERE O2.OrderId > O1.OrderId) AS nextorderid
FROM Sales.[Order] AS O1;


---------------------------------------------------------------------
-- Running Aggregates
---------------------------------------------------------------------


SELECT YEAR(OrderDate) AS orderyear,
       COUNT(*) AS qty
FROM Sales.[Order]
GROUP BY YEAR(OrderDate);


SELECT orderyear, qty,
       (SELECT SUM(O2.qty)
        FROM (
              SELECT YEAR(OrderDate) AS orderyear,
                     COUNT(*) AS qty
              FROM Sales.[Order]
              GROUP BY YEAR(OrderDate)
             ) AS O2
        WHERE O2.orderyear <= O1.orderyear) AS runqty
FROM (
      SELECT YEAR(OrderDate) AS orderyear,
             COUNT(*) AS qty
      FROM Sales.[Order]
      GROUP BY YEAR(OrderDate)
     ) AS O1
ORDER BY orderyear;


---------------------------------------------------------------------
-- Misbehaving Subqueries
---------------------------------------------------------------------


---------------------------------------------------------------------
-- NULL Trouble
---------------------------------------------------------------------


-- Customers who didn't place orders


-- Using NOT IN
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId NOT IN(SELECT O.CustomerId
                    FROM Sales.[Order] AS O);


-- Add a row to the Orders table with a NULL custid
INSERT INTO Sales.[Order]
  (OrderId, CustomerId, EmployeeId, OrderDate, RequiredDate, ShipToDate, ShipperId,
   Freight, ShipToName, ShipToAddress, ShipToCity, ShipToRegion,
   ShipToPostalCode, ShipToCountry)
  VALUES(9999, NULL, 1, '20160212', '20160212',
         '20160212', 1, 123.00, N'abc', N'abc', N'abc',
         N'abc', N'abc', N'abc');



-- Following returns an empty set
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId NOT IN(SELECT O.CustomerId
                    FROM Sales.[Order] AS O);


-- Exclude NULLs explicitly
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId NOT IN(SELECT O.CustomerId 
                    FROM Sales.[Order] AS O
                    WHERE O.CustomerId IS NOT NULL);


-- Using NOT EXISTS
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer AS C
WHERE NOT EXISTS
  (SELECT * 
   FROM Sales.[Order] AS O
   WHERE O.CustomerId = C.CustomerId);


-- Cleanup
DELETE FROM Sales.[Order] WHERE CustomerId IS NULL;
GO


---------------------------------------------------------------------
-- Substitution Error in a Subquery Column Name
---------------------------------------------------------------------


-- Create and populate table Sales.MyShippers
DROP TABLE IF EXISTS Sales.MyShippers;


CREATE TABLE Sales.MyShippers
(
  ShipperId  INT          NOT NULL,
  ShipperCompanyName NVARCHAR(40) NOT NULL,
  PhoneNumber       NVARCHAR(24) NOT NULL,
  CONSTRAINT PK_MyShippers PRIMARY KEY(ShipperId)
);


INSERT INTO Sales.MyShippers(ShipperId, ShipperCompanyName, PhoneNumber)
  VALUES(1, N'Shipper GVSUA', N'(503) 555-0137'),
	      (2, N'Shipper ETYNR', N'(425) 555-0136'),
				(3, N'Shipper ZHISN', N'(415) 555-0138');
GO


-- Shippers who shipped orders to customer 43


-- Bug
SELECT ShipperId, ShipperCompanyName
FROM Sales.Shipper
WHERE ShipperId IN
  (SELECT ShipperId
   FROM Sales.[Order]
   WHERE CustomerId = 43);
GO


-- The safe way using aliases, bug identified
SELECT ShipperId, ShipperCompanyName
FROM Sales.Shipper
WHERE ShipperId IN
  (SELECT O.ShipperId
   FROM Sales.[Order] AS O
   WHERE O.CustomerId = 43);
GO


-- Bug corrected
SELECT ShipperId, ShipperCompanyName
FROM Sales.Shipper
WHERE ShipperId IN
  (SELECT O.ShipperId
   FROM Sales.[Order] AS O
   WHERE O.CustomerId = 43);


-- Cleanup
DROP TABLE IF EXISTS Sales.MyShippers;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CHAPTER 5--
---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 05 - Table Expressions
-- ï¿½ Itzik Ben-Gan 
---------------------------------------------------------------------
/*
 Proposition 6: Joins orders and orderdetails to calculate total sales per order
Solution 6:By combining both orders table and orderdetails table and grouping the results we can add up product values and calculate total revenue for each order

Proposition 7: Using an INNER JOIN between customers and orders to return only customers who placed orders
Solution 7: We can join customers with orders and return only the records that have matching values so we can see which customers made a purchase helping us see who is an active customer.

Proposition 8: Use a LEFT JOIN to find customers who did not palce any orders
Solution 8: We connect customers to orders using LEFT JOIN and see which have missing order records. if no match then that customer is inactive.

Proposition 9: Group orders by year and use aggregate functions to count total orders per year
Solution 9: We can group orders by the year from the order date and count how much orders happened each year to analyze business growth

Proposition 10: Join customer data with aggregated order totals
Solution 10: by combining cusomter orders and sorting the results we can identify who generated the most revenue seeing our most prized customer.
 */


---------------------------------------------------------------------
-- Derived Tables
---------------------------------------------------------------------



SELECT *
FROM (SELECT CustomerId, CustomerCompanyName --filter customers based on country 
      FROM Sales.Customer
      WHERE CustomerCountry = N'USA') AS USACusts;


---------------------------------------------------------------------
-- Assigning Column Aliases
---------------------------------------------------------------------


-- Following fails
/*
SELECT
  YEAR(orderdate) AS orderyear,
  COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY orderyear;
*/
GO


-- Listing 5-1 Query with a Derived Table using Inline Aliasing Form
SELECT orderyear, COUNT(DISTINCT CustomerId) AS numcusts
FROM (SELECT YEAR(OrderDate) AS orderyear, CustomerId
      FROM Sales.[Order]) AS D                                 -- Unique customers placed in a year
GROUP BY orderyear;


SELECT YEAR(OrderDate) AS orderyear, COUNT(DISTINCT CustomerId) AS numcusts
FROM Sales.[Order]
GROUP BY YEAR(OrderDate);                                       -- Unique customers placed in a year but groups orders by year counts the # of customers


-- External column aliasing
SELECT orderyear, COUNT(DISTINCT CustomerId) AS numcusts
FROM (SELECT YEAR(orderdate), CustomerId                 -- Same but by grouping data by extracted year
      FROM Sales.[Order]) AS D(orderyear, CustomerId)
GROUP BY orderyear;
GO


---------------------------------------------------------------------
-- Using Arguments
---------------------------------------------------------------------


-- Yearly Count of Customers handled by Employee 3
DECLARE @EmployeeId AS INT = 3;


SELECT orderyear, COUNT(DISTINCT CustomerId) AS numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, CustomerId      --unique customers served by specific employee. 
      FROM Sales.[Order]
      WHERE EmployeeId = @EmployeeId) AS D
GROUP BY orderyear;
GO


---------------------------------------------------------------------
-- Nesting
---------------------------------------------------------------------


-- Listing 5-2 Query with Nested Derived Tables
SELECT orderyear, numcusts
FROM (SELECT orderyear, COUNT(DISTINCT CustomerId) AS numcusts
      FROM (SELECT YEAR(OrderDate) AS orderyear, CustomerId -- # of customers that pass a threshold
            FROM Sales.[Order]) AS D1
      GROUP BY orderyear) AS D2
WHERE numcusts > 70;

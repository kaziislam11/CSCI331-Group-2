USE Northwinds2024Student;
GO

-- 1
-- Explain the difference between the UNION ALL and UNION operators
-- UNION removes duplicate rows (requires extra processing), while 
-- UNION ALL keeps all rows (faster/no extra processing).

-- Answer:
--UNION combines the results of two queries and removes duplicate rows, which requires extra processing.
--UNION ALL combines the results of two queries and keeps all rows, including duplicates, so it is faster because no duplicate checking is done.

-- 2
-- Write a query that generates a virtual auxiliary table of 10 numbers
-- in the range 1 through 10
-- Tables involved: no table

SELECT 1 AS n
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
UNION ALL SELECT 5
UNION ALL SELECT 6
UNION ALL SELECT 7
UNION ALL SELECT 8
UNION ALL SELECT 9
UNION ALL SELECT 10;

-- 3
-- Write a query that returns customer and employee pairs 
-- that had order activity in January 2016 but not in February 2016
-- Tables involved: TSQLV4 database, Orders table

SELECT O.CustomerId, O.EmployeeId
FROM Sales.[Order] AS O
WHERE O.OrderDate >= '20160101'
  AND O.OrderDate <  '20160201'

EXCEPT

SELECT O.CustomerId, O.EmployeeId
FROM Sales.[Order] AS O
WHERE O.OrderDate >= '20160201'
  AND O.OrderDate <  '20160301'
ORDER BY CustomerId, EmployeeId;




-- 4
-- Write a query that returns customer and employee pairs 
-- that had order activity in both January 2016 and February 2016
-- Tables involved: TSQLV4 database, Orders table

SELECT O.CustomerId, O.EmployeeId
FROM Sales.[Order] AS O
WHERE O.OrderDate >= '20160101'
  AND O.OrderDate <  '20160201'

INTERSECT

SELECT O.CustomerId, O.EmployeeId
FROM Sales.[Order] AS O
WHERE O.OrderDate >= '20160201'
  AND O.OrderDate <  '20160301'
ORDER BY CustomerId, EmployeeId;


-- 5
-- Write a query that returns customer and employee pairs 
-- that had order activity in both January 2016 and February 2016
-- but not in 2015
-- Tables involved: TSQLV4 database, Orders table

SELECT O.CustomerId, O.EmployeeId
FROM Sales.[Order] AS O
WHERE O.OrderDate >= '20160101'
  AND O.OrderDate <  '20160201'

INTERSECT

SELECT O.CustomerId, O.EmployeeId
FROM Sales.[Order] AS O
WHERE O.OrderDate >= '20160201'
  AND O.OrderDate <  '20160301'

EXCEPT

SELECT O.CustomerId, O.EmployeeId
FROM Sales.[Order] AS O
WHERE O.OrderDate >= '20150101'
  AND O.OrderDate <  '20160101'
ORDER BY CustomerId, EmployeeId;


--Proposition 1: 

SELECT CustomerCountry AS Country
FROM Sales.Customer
EXCEPT
SELECT SupplierCountry AS Country
FROM Production.Supplier
ORDER BY Country;


--Proposition 2: 

SELECT CustomerCompanyName AS CompanyName
FROM Sales.Customer
UNION
SELECT SupplierCompanyName AS CompanyName
FROM Production.Supplier
ORDER BY CompanyName;


--Proposition 3

SELECT CustomerCity AS City
FROM Sales.Customer
INTERSECT
SELECT EmployeeCity AS City
FROM HumanResources.Employee
ORDER BY City;


--Proposition 4

SELECT ProductId FROM Production.Product
EXCEPT
SELECT ProductId FROM Sales.OrderDetail;


--Proposition 5

SELECT CustomerCountry AS Country, 'Customer' AS Relationship FROM Sales.Customer
UNION
SELECT SupplierCountry, 'Supplier' FROM Production.Supplier
UNION
SELECT EmployeeCountry, 'Employee' FROM HumanResources.Employee
ORDER BY Country;

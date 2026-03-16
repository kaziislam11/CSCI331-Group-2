
-- ========================================
-- Chapter 6: Set Operators
-- ========================================

-- ========================================================================
-- 1
-- Explain the difference between the UNION ALL and UNION operators
-- In what cases are they equivalent?
-- When they are equivalent, which one should you use?
-- ========================================================================

-- ANSWER:

-- UNION ALL: Returns all rows from both queries, INCLUDING duplicates
--   - Faster performance 
--   - Use when: You know there are no duplicates OR you want to keep duplicates
--   - Example: Combining logs from different sources where duplicates are meaningful

-- UNION: Returns all rows from both queries, EXCLUDING duplicates
--   - Slower performance 
--   - Use when: You need unique rows only
--   - Example: Getting a distinct list of cities from customers and employees

-- ========================================================================
-- 2
-- Write a query that generates a virtual auxiliary table of 10 numbers
-- in the range 1 through 10
-- Tables involved: no table
-- ========================================================================

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

-- ========================================================================
-- 3
-- Write a query that returns customer and employee pairs 
-- that had order activity in January 2016 but not in February 2016
-- Tables involved: TSQLV4 database, Orders table
-- ========================================================================

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE OrderDate >= '20160101' AND OrderDate < '20160201'
 
EXCEPT
 
SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE OrderDate >= '20160201' AND OrderDate < '20160301'
 
ORDER BY CustomerId, EmployeeId;

-- ========================================================================
-- 4
-- Write a query that returns customer and employee pairs 
-- that had order activity in both January 2016 and February 2016
-- Tables involved: TSQLV4 database, Orders table
-- ========================================================================

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE OrderDate >= '20160101' AND OrderDate < '20160201'
 
INTERSECT
 
SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE OrderDate >= '20160201' AND OrderDate < '20160301'
 
ORDER BY CustomerId, EmployeeId;
GO

-- ========================================================================
-- 5
-- Write a query that returns customer and employee pairs 
-- that had order activity in both January 2016 and February 2016
-- but not in 2015
-- Tables involved: TSQLV4 database, Orders table
-- ========================================================================

(
    SELECT CustomerId, EmployeeId
    FROM Sales.[Order]
    WHERE OrderDate >= '20160101' AND OrderDate < '20160201'
    
    INTERSECT
    
    SELECT CustomerId, EmployeeId
    FROM Sales.[Order]
    WHERE OrderDate >= '20160201' AND OrderDate < '20160301'
)
EXCEPT
SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE OrderDate >= '20150101' AND OrderDate < '20160101'

ORDER BY CustomerId, EmployeeId;

-- ========================================
-- Propositions
-- ========================================

SELECT CustomerCountry AS Country
FROM Sales.Customer
EXCEPT
SELECT SupplierCountry AS Country
FROM Production.Supplier
ORDER BY Country;

--------------------------------------------------------

SELECT EmployeeId
FROM Sales.[Order]
WHERE OrderDate >= '20160101' AND OrderDate < '20170101'
INTERSECT
SELECT EmployeeId
FROM HumanResources.Employee
WHERE EmployeeCountry = 'USA'
ORDER BY EmployeeId;

--------------------------------------------------------

SELECT CustomerCompanyName AS CompanyName
FROM Sales.Customer
UNION
SELECT SupplierCompanyName AS CompanyName
FROM Production.Supplier
ORDER BY CompanyName;

--------------------------------------------------------

SELECT ProductId
FROM Sales.OrderDetail od
INNER JOIN Sales.[Order] o ON od.OrderId = o.OrderId
WHERE o.OrderDate >= '20160101' AND o.OrderDate < '20160201'
EXCEPT
SELECT ProductId
FROM Sales.OrderDetail od
INNER JOIN Sales.[Order] o ON od.OrderId = o.OrderId
WHERE o.OrderDate >= '20160201' AND o.OrderDate < '20160301'
ORDER BY ProductId;

--------------------------------------------------------

SELECT CustomerCity AS City
FROM Sales.Customer
INTERSECT
SELECT EmployeeCity AS City
FROM HumanResources.Employee
ORDER BY City;

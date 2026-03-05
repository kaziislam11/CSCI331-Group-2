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
go

SELECT 
    dbo.GetFiscalQuarter(OrderDate) AS FiscalQuarter, --call function for each order date
    COUNT(OrderID) AS TotalOrders, --orders exsits
    SUM(Freight) AS TotalFreight, 
    MAX(OrderDate) AS LatestDateInQuarter --recent data (for sorting)
FROM Sales.[Order] --order keyword and error prevention
GROUP BY dbo.GetFiscalQuarter(OrderDate) 
ORDER BY MAX(OrderDate) DESC; 

-- Exercise 1
-- Explain why aliased columns cannot be referenced in WHERE.
-- The fix is to wrap the query in a derived table or CTE.
-- ------------------------------------------------------------
-- PROBLEM: When you try to run this query you get the following error.
/*
Msg 207, Level 16, State 1, Line 233
Invalid column name 'endofyear'.
*/
-- Explain what the problem is and suggest a valid solution.

-- SOLUTION using derived table:
SELECT OrderId, OrderDate, CustomerId, EmployeeId, endofyear
FROM (
    SELECT
        OrderId, OrderDate, CustomerId, EmployeeId,
        DATEFROMPARTS(YEAR(OrderDate), 12, 31) AS endofyear
    FROM Sales.[Order]
) AS D
WHERE OrderDate <> endofyear;
GO

-- ------------------------------------------------------------
-- Exercise 2-1
-- Return the maximum order date for each employee.

SELECT
    EmployeeId,
    MAX(OrderDate) AS maxorderdate
FROM Sales.[Order]
GROUP BY EmployeeId;
GO

-- ------------------------------------------------------------
-- Exercise 2-2
-- Wrap exercise 2-1 in a derived table and join it back
-- to Sales.[Order] to return the full order details
-- for each employee's most recent order.

SELECT
    o.EmployeeId,
    o.OrderDate,
    o.OrderId,
    o.CustomerId
FROM Sales.[Order] o
JOIN (
    SELECT EmployeeId, MAX(OrderDate) AS maxorderdate
    FROM Sales.[Order]
    GROUP BY EmployeeId
) AS maxdates
    ON o.EmployeeId  = maxdates.EmployeeId
    AND o.OrderDate  = maxdates.maxorderdate
ORDER BY o.EmployeeId;
GO

-- ------------------------------------------------------------
-- Exercise 3-1
-- Calculate a row number for each order based on
-- OrderDate, OrderId ordering.

SELECT
    OrderId,
    OrderDate,
    CustomerId,
    EmployeeId,
    ROW_NUMBER() OVER (ORDER BY OrderDate, OrderId) AS rownum
FROM Sales.[Order];
GO

-- ------------------------------------------------------------
-- Exercise 3-2
-- Return only rows with row numbers 11 through 20
-- using a CTE to encapsulate exercise 3-1.

WITH OrderedOrders AS (
    SELECT
        OrderId,
        OrderDate,
        CustomerId,
        EmployeeId,
        ROW_NUMBER() OVER (ORDER BY OrderDate, OrderId) AS rownum
    FROM Sales.[Order]
)
SELECT OrderId, OrderDate, CustomerId, EmployeeId, rownum
FROM OrderedOrders
WHERE rownum BETWEEN 11 AND 20;
GO

-- ------------------------------------------------------------
-- Exercise 4
-- Recursive CTE returning the management chain
-- leading to a specific employee.
-- Using EmployeeId = 9 (or adjust to match your data)

WITH MgmtChain AS (
    SELECT EmployeeId, EmployeeManagerId, EmployeeFirstName, EmployeeLastName
    FROM HumanResources.Employee
    WHERE EmployeeId = 9

    UNION ALL

    SELECT e.EmployeeId, e.EmployeeManagerId, e.EmployeeFirstName, e.EmployeeLastName
    FROM HumanResources.Employee e
    JOIN MgmtChain m
        ON e.EmployeeId = m.EmployeeManagerId
)
SELECT EmployeeId, EmployeeManagerId, EmployeeFirstName, EmployeeLastName
FROM MgmtChain;
GO

-- ------------------------------------------------------------
-- Exercise 5-1
-- Create a view that returns total quantity
-- for each employee and year.

CREATE OR ALTER VIEW HumanResources.VEmpOrders AS
SELECT
    o.EmployeeId,
    YEAR(o.OrderDate)    AS orderyear,
    SUM(od.Quantity)     AS qty
FROM Sales.[Order] o
JOIN Sales.OrderDetail od
    ON o.OrderId = od.OrderId
GROUP BY o.EmployeeId, YEAR(o.OrderDate);
GO

SELECT * FROM HumanResources.VEmpOrders
ORDER BY EmployeeId, orderyear;
GO

-- ------------------------------------------------------------
-- Exercise 5-2
-- Query VEmpOrders to return running quantity
-- for each employee and year using a subquery.

SELECT
    v1.EmployeeId,
    v1.orderyear,
    v1.qty,
    (
        SELECT SUM(v2.qty)
        FROM HumanResources.VEmpOrders v2
        WHERE v2.EmployeeId = v1.EmployeeId
        AND v2.orderyear <= v1.orderyear
    ) AS runqty
FROM HumanResources.VEmpOrders v1
ORDER BY v1.EmployeeId, v1.orderyear;
GO

-- ------------------------------------------------------------
-- Exercise 6-1
-- Create an inline table-valued function that returns
-- the top N most expensive products for a given supplier.

CREATE OR ALTER FUNCTION Production.TopProducts
    (@supid AS INT, @n AS INT)
RETURNS TABLE
AS
RETURN
    SELECT TOP (@n)
        ProductId,
        ProductName,
        UnitPrice
    FROM Production.Product
    WHERE SupplierId = @supid
    ORDER BY UnitPrice DESC;
GO

SELECT * FROM Production.TopProducts(5, 2);
GO

-- ------------------------------------------------------------
-- Exercise 6-2
-- Use CROSS APPLY with TopProducts to return
-- the two most expensive products per supplier.

SELECT
    s.SupplierId,
    s.SupplierCompanyName,
    tp.ProductId,
    tp.ProductName,
    tp.UnitPrice
FROM Production.Supplier s
CROSS APPLY Production.TopProducts(s.SupplierId, 2) AS tp
ORDER BY s.SupplierId;
GO

-- Cleanup
DROP VIEW IF EXISTS HumanResources.VEmpOrders;
DROP FUNCTION IF EXISTS Production.TopProducts;
GO



-- Proposition 1
-- Proposition: Use a CTE to find which month of the year
-- had the highest total number of orders placed.
-- ------------------------------------------------------------
WITH OrdersByMonth AS (
    SELECT
        MONTH(OrderDate)   AS OrderMonth,
        COUNT(OrderId)     AS TotalOrders
    FROM Sales.[Order]
    GROUP BY MONTH(OrderDate)
)
SELECT TOP 1
    OrderMonth,
    TotalOrders
FROM OrdersByMonth
ORDER BY TotalOrders DESC;
GO

-- Proposition 2
-- Proposition: Use a derived table to return each employee's
-- total freight handled, ranked from highest to lowest.
-- ------------------------------------------------------------
SELECT
    e.EmployeeId,
    e.EmployeeFirstName,
    e.EmployeeLastName,
    emp_freight.TotalFreight
FROM HumanResources.Employee e
JOIN (
    SELECT EmployeeId, SUM(Freight) AS TotalFreight
    FROM Sales.[Order]
    GROUP BY EmployeeId
) AS emp_freight
    ON e.EmployeeId = emp_freight.EmployeeId
ORDER BY emp_freight.TotalFreight DESC;
GO

-- Proposition 3
-- Proposition: Create a view that shows each product
-- alongside its category name and current unit price.
-- ------------------------------------------------------------
CREATE OR ALTER VIEW Production.vw_ProductWithCategory AS
SELECT
    p.ProductId,
    p.ProductName,
    c.CategoryName,
    p.UnitPrice,
    p.Discontinued
FROM Production.Product p
JOIN Production.Category c
    ON p.CategoryId = c.CategoryId;
GO

SELECT * FROM Production.vw_ProductWithCategory
ORDER BY CategoryName, ProductName;
GO

-- Proposition 4
-- Proposition: Use a CTE to find all customers whose total
-- freight spending is above the overall customer average.
-- ------------------------------------------------------------
WITH CustomerFreight AS (
    SELECT
        CustomerId,
        SUM(Freight) AS TotalFreight
    FROM Sales.[Order]
    GROUP BY CustomerId
),
AvgFreight AS (
    SELECT AVG(TotalFreight) AS AvgCustomerFreight
    FROM CustomerFreight
)
SELECT
    c.CustomerId,
    c.CustomerCompanyName,
    cf.TotalFreight
FROM Sales.Customer c
JOIN CustomerFreight cf
    ON c.CustomerId = cf.CustomerId
JOIN AvgFreight af
    ON cf.TotalFreight > af.AvgCustomerFreight
ORDER BY cf.TotalFreight DESC;
GO

-- Proposition 5
-- Proposition: Use a derived table to return the top 5 most
-- ordered products by total quantity sold.
-- ------------------------------------------------------------
SELECT TOP 5
    p.ProductId,
    p.ProductName,
    product_totals.TotalQuantity
FROM Production.Product p
JOIN (
    SELECT ProductId, SUM(Quantity) AS TotalQuantity
    FROM Sales.OrderDetail
    GROUP BY ProductId
) AS product_totals
    ON p.ProductId = product_totals.ProductId
ORDER BY product_totals.TotalQuantity DESC;
GO


USE Northwinds2024Student;
GO

-- ============================================================
-- CHAPTER 4 - SUBQUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Exercise 1
-- Return all orders placed on the last day of activity
-- in the Order table.
-- ------------------------------------------------------------
SELECT OrderId, OrderDate, CustomerId, EmployeeId
FROM Sales.[Order]
WHERE OrderDate = (
    SELECT MAX(OrderDate)
    FROM Sales.[Order]
);
GO

-- ------------------------------------------------------------
-- Exercise 2
-- Return all orders placed by the customer(s) who placed
-- the highest number of orders.
-- (Handles ties - more than one customer may qualify)
-- ------------------------------------------------------------
SELECT CustomerId, OrderId, OrderDate, EmployeeId
FROM Sales.[Order]
WHERE CustomerId IN (
    SELECT CustomerId
    FROM Sales.[Order]
    GROUP BY CustomerId
    HAVING COUNT(OrderId) = (
        SELECT MAX(OrderCount)
        FROM (
            SELECT COUNT(OrderId) AS OrderCount
            FROM Sales.[Order]
            GROUP BY CustomerId
        ) AS Counts
    )
)
ORDER BY CustomerId, OrderDate;
GO

-- ------------------------------------------------------------
-- Exercise 3
-- Return employees who did not place any orders
-- on or after May 1st, 1998.
-- (Northwinds2024Student data ends in 1998)
-- ------------------------------------------------------------
SELECT
    e.EmployeeId,
    e.EmployeeFirstName,
    e.EmployeeLastName
FROM HumanResources.Employee e
WHERE e.EmployeeId NOT IN (
    SELECT DISTINCT EmployeeId
    FROM Sales.[Order]
    WHERE OrderDate >= '1998-05-01'
    AND EmployeeId IS NOT NULL
);
GO

-- ------------------------------------------------------------
-- Exercise 4
-- Return countries where there are customers but no employees.
-- ------------------------------------------------------------
SELECT DISTINCT CustomerCountry AS Country
FROM Sales.Customer
WHERE CustomerCountry NOT IN (
    SELECT DISTINCT EmployeeCountry
    FROM HumanResources.Employee
    WHERE EmployeeCountry IS NOT NULL
)
ORDER BY Country;
GO

-- ------------------------------------------------------------
-- Exercise 5
-- For each customer, return all orders placed on
-- that customer's last day of activity.
-- ------------------------------------------------------------
SELECT o.CustomerId, o.OrderId, o.OrderDate, o.EmployeeId
FROM Sales.[Order] o
WHERE o.OrderDate = (
    SELECT MAX(OrderDate)
    FROM Sales.[Order]
    WHERE CustomerId = o.CustomerId
)
ORDER BY o.CustomerId;
GO

-- ------------------------------------------------------------
-- Exercise 6
-- Return customers who placed orders in 1997 but not in 1998.
-- (Northwinds2024Student equivalent of 2015/2016)
-- ------------------------------------------------------------
SELECT
    c.CustomerId,
    c.CustomerCompanyName
FROM Sales.Customer c
WHERE c.CustomerId IN (
    SELECT DISTINCT CustomerId
    FROM Sales.[Order]
    WHERE YEAR(OrderDate) = 1997
)
AND c.CustomerId NOT IN (
    SELECT DISTINCT CustomerId
    FROM Sales.[Order]
    WHERE YEAR(OrderDate) = 1998
)
ORDER BY c.CustomerId;
GO

-- ------------------------------------------------------------
-- Exercise 7
-- Return customers who ordered a specific product.
-- Using ProductId = 12 as in the exercise.
-- ------------------------------------------------------------
SELECT DISTINCT
    c.CustomerId,
    c.CustomerCompanyName
FROM Sales.Customer c
WHERE c.CustomerId IN (
    SELECT DISTINCT o.CustomerId
    FROM Sales.[Order] o
    WHERE o.OrderId IN (
        SELECT DISTINCT od.OrderId
        FROM Sales.OrderDetail od
        WHERE od.ProductId = 12
    )
)
ORDER BY c.CustomerId;
GO

-- ------------------------------------------------------------
-- Exercise 8
-- Calculate a running total quantity for each customer
-- by order month using a subquery.
-- ------------------------------------------------------------
SELECT
    o.CustomerId,
    DATEADD(month, DATEDIFF(month, 0, o.OrderDate), 0) AS OrderMonth,
    SUM(od.Quantity) AS qty,
    (
        SELECT SUM(od2.Quantity)
        FROM Sales.[Order] o2
        JOIN Sales.OrderDetail od2 ON o2.OrderId = od2.OrderId
        WHERE o2.CustomerId = o.CustomerId
        AND DATEADD(month, DATEDIFF(month, 0, o2.OrderDate), 0)
            <= DATEADD(month, DATEDIFF(month, 0, o.OrderDate), 0)
    ) AS runqty
FROM Sales.[Order] o
JOIN Sales.OrderDetail od ON o.OrderId = od.OrderId
GROUP BY o.CustomerId, DATEADD(month, DATEDIFF(month, 0, o.OrderDate), 0)
ORDER BY o.CustomerId, OrderMonth;
GO

-- ------------------------------------------------------------
-- Exercise 9
-- Explain the difference between IN and EXISTS.
-- ------------------------------------------------------------
-- IN checks whether a value matches any value in a list
-- returned by a subquery. It evaluates the subquery first,
-- collects all results into a set, then checks membership.
-- IN can behave unexpectedly when NULLs are present in the
-- subquery result - NOT IN with NULLs returns no rows.

-- Example using IN:
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId IN (
    SELECT DISTINCT CustomerId
    FROM Sales.[Order]
);

-- EXISTS checks whether a subquery returns at least one row.
-- It stops as soon as it finds the first match (short-circuit).
-- EXISTS is generally faster on large datasets because it
-- does not need to return the full result set, just confirm
-- a match exists. EXISTS handles NULLs safely.

-- Same result using EXISTS:
SELECT c.CustomerId, c.CustomerCompanyName
FROM Sales.Customer c
WHERE EXISTS (
    SELECT 1
    FROM Sales.[Order] o
    WHERE o.CustomerId = c.CustomerId
);
GO

-- ------------------------------------------------------------
-- Exercise 10
-- For each order, return the number of days since the same
-- customer's previous order.
-- ------------------------------------------------------------
SELECT
    o1.CustomerId,
    o1.OrderDate,
    o1.OrderId,
    DATEDIFF(day,
        (
            SELECT MAX(o2.OrderDate)
            FROM Sales.[Order] o2
            WHERE o2.CustomerId = o1.CustomerId
            AND (
                o2.OrderDate < o1.OrderDate
                OR (o2.OrderDate = o1.OrderDate AND o2.OrderId < o1.OrderId)
            )
        ),
        o1.OrderDate
    ) AS diff
FROM Sales.[Order] o1
ORDER BY o1.CustomerId, o1.OrderDate, o1.OrderId;
GO

-- Query 1
-- Proposition: Find all customers who have placed more orders
-- than the average number of orders per customer.
-- ------------------------------------------------------------
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId IN (
    SELECT CustomerId
    FROM Sales.[Order]
    GROUP BY CustomerId
    HAVING COUNT(OrderId) > (
        SELECT AVG(OrderCount)
        FROM (
            SELECT COUNT(OrderId) AS OrderCount
            FROM Sales.[Order]
            GROUP BY CustomerId
        ) AS AvgOrders
    )
);
GO

-- Query 2
-- Proposition: Find all products whose unit price is higher
-- than the average unit price within their own category.
-- ------------------------------------------------------------
SELECT ProductId, ProductName, CategoryId, UnitPrice
FROM Production.Product p
WHERE UnitPrice > (
    SELECT AVG(UnitPrice)
    FROM Production.Product
    WHERE CategoryId = p.CategoryId
);
GO

-- Query 3
-- Proposition: Find all orders that were shipped to the same
-- country as the customer who placed them.
-- ------------------------------------------------------------
SELECT o.OrderId, o.OrderDate, o.CustomerId, o.ShipToCountry
FROM Sales.[Order] o
WHERE o.ShipToCountry = (
    SELECT c.CustomerCountry
    FROM Sales.Customer c
    WHERE c.CustomerId = o.CustomerId
);
GO

-- Query 4
-- Proposition: Find the shipper that handled the highest
-- total freight cost across all orders.
-- ------------------------------------------------------------
SELECT ShipperId, ShipperCompanyName
FROM Sales.Shipper
WHERE ShipperId = (
    SELECT TOP 1 ShipperId
    FROM Sales.[Order]
    GROUP BY ShipperId
    ORDER BY SUM(Freight) DESC
);
GO

-- Query 5
-- Proposition: Find all customers who have never placed
-- an order.
-- ------------------------------------------------------------
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId NOT IN (
    SELECT CustomerId
    FROM Sales.[Order]
    WHERE CustomerId IS NOT NULL
);
GO

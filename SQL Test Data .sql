-- 6. Store each result in temporary tables

-- Question 6: Store the results of the previous queries into temporary tables.
-- Temporary tables are session-specific and automatically dropped when the session ends.

-- Temporary Table for Question 1 results
DROP TABLE IF EXISTS #CustomersNonStandardPhone; -- Drop the table if it already exists to avoid errors on re-execution
SELECT COUNT(*) AS InvalidPhoneCount
INTO #CustomersNonStandardPhone -- Create and insert results into a temporary table
FROM Person.PersonPhone
WHERE LEN(REPLACE(PhoneNumber, '-', '')) <> 10
  OR REPLACE(PhoneNumber, '-', '') NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]';

-- View the content of the temporary table for Question 1
SELECT * FROM #CustomersNonStandardPhone;


-- Temporary Table for Question 2 results
DROP TABLE IF EXISTS #CustomersLastNameBE;
SELECT COUNT(*) AS NumberOfCustomers
INTO #CustomersLastNameBE
FROM Person.Person
WHERE LastName LIKE 'BE%';

-- View the content of the temporary table for Question 2
SELECT * FROM #CustomersLastNameBE;


-- Temporary Table for Question 3 results
DROP TABLE IF EXISTS #Top3SalesPerCustomerProductCategory;
WITH RankedSales AS (
    SELECT
        soh.CustomerID,
        pc.Name AS ProductCategory,
        p.Name AS ProductName,
        sod.LineTotal,
        soh.SalesOrderID,
        ROW_NUMBER() OVER (PARTITION BY soh.CustomerID, pc.Name, p.Name ORDER BY sod.LineTotal DESC) AS rn
    FROM
        Sales.SalesOrderHeader AS soh
    JOIN
        Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
    JOIN
        Production.Product AS p ON sod.ProductID = p.ProductID
    JOIN
        Production.ProductSubcategory AS ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN
        Production.ProductCategory AS pc ON ps.ProductCategoryID = pc.ProductCategoryID
)
SELECT
    CustomerID,
    ProductCategory,
    ProductName,
    LineTotal,
    SalesOrderID
INTO #Top3SalesPerCustomerProductCategory
FROM
    RankedSales
WHERE
    rn <= 3;

-- View the content of the temporary table for Question 3
SELECT * FROM #Top3SalesPerCustomerProductCategory ORDER BY CustomerID, ProductCategory, ProductName, LineTotal DESC;


-- Temporary Table for Question 4 results
DROP TABLE IF EXISTS #SalesOrderTotalsComparison;
SELECT
    soh.SalesOrderID,
    soh.TotalDue AS SalesOrderHeaderTotalDue,
    SUM(sod.LineTotal) AS SalesOrderDetailLineItemTotal,
    (soh.TotalDue - SUM(sod.LineTotal)) AS Difference
INTO #SalesOrderTotalsComparison
FROM
    Sales.SalesOrderHeader AS soh
JOIN
    Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY
    soh.SalesOrderID, soh.TotalDue;

-- View the content of the temporary table for Question 4
SELECT * FROM #SalesOrderTotalsComparison ORDER BY SalesOrderID;


-- Temporary Table for Question 5 results
DROP TABLE IF EXISTS #OrderDetailsWithLastOrderDate;
WITH CustomerLastOrder AS (
    SELECT
        CustomerID,
        MAX(OrderDate) AS LastOrderDate
    FROM
        Sales.SalesOrderHeader
    GROUP BY
        CustomerID
)
SELECT
    soh.CustomerID,
    soh.SalesOrderID,
    soh.OrderDate AS CurrentOrderDate,
    sod.ProductID,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal,
    clo.LastOrderDate
INTO #OrderDetailsWithLastOrderDate
FROM
    Sales.SalesOrderHeader AS soh
JOIN
    Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN
    CustomerLastOrder AS clo ON soh.CustomerID = clo.CustomerID;

-- View the content of the temporary table for Question 5
SELECT * FROM #OrderDetailsWithLastOrderDate ORDER BY CustomerID, CurrentOrderDate;

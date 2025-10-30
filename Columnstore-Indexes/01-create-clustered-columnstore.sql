-- =============================================
-- Script: 01-create-clustered-columnstore.sql
-- Description: สร้างตารางด้วย Clustered Columnstore Index
-- Database: AdventureWorks2022
-- Server: SQL Server 2014 ขึ้นไป (แนะนำ 2016+)
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- คำอธิบาย: Clustered Columnstore Index เหมาะสำหรับ Fact Tables ขนาดใหญ่
-- =============================================

USE AdventureWorks2022;
GO

-- =============================================
-- ขั้นตอนที่ 1: ลบตารางเก่า (ถ้ามี)
-- =============================================

-- === สร้าง Clustered Columnstore Index ===

GO

IF OBJECT_ID('dbo.FactSales_CCI', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.FactSales_CCI;
    -- ลบตาราง dbo.FactSales_CCI ที่มีอยู่เดิมแล้ว
END
GO

-- =============================================
-- ขั้นตอนที่ 2: สร้างตารางแบบ Clustered Columnstore
-- =============================================

-- ขั้นตอนที่ 1: สร้างตาราง Clustered Columnstore


-- สร้าง Fact Table ด้วย Clustered Columnstore Index
CREATE TABLE dbo.FactSales_CCI (
    SalesOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    SalesPersonID INT NULL,
    OrderDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    ShipDate DATE NULL,
    Quantity SMALLINT NOT NULL,
    UnitPrice MONEY NOT NULL,
    DiscountPct DECIMAL(5,2) NOT NULL DEFAULT 0,
    LineTotal AS (Quantity * UnitPrice * (1 - DiscountPct)),
    TaxAmt MONEY NOT NULL DEFAULT 0,
    Freight MONEY NOT NULL DEFAULT 0,
    TotalDue AS (LineTotal + TaxAmt + Freight),
    TerritoryID INT NULL,
    CurrencyCode NCHAR(3) NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    INDEX CCI_FactSales_CCI CLUSTERED COLUMNSTORE
);
GO

-- สร้างตาราง dbo.FactSales_CCI เสร็จสมบูรณ์

GO

-- =============================================
-- ขั้นตอนที่ 3: Insert ข้อมูลตัวอย่าง
-- =============================================

-- ขั้นตอนที่ 2: Insert ข้อมูลตัวอย่าง


-- สร้างข้อมูลตัวอย่างจำนวนมากเพื่อแสดงประสิทธิภาพของ Columnstore
DECLARE @RowCount INT = 0;
DECLARE @MaxRows INT = 100000;  -- 100K rows for demo

-- กำลังสร้างข้อมูล ' + CAST(@MaxRows AS VARCHAR) + ' rows...
GO

-- Insert ข้อมูลจากตารางเดิม (Fact + Dimension)
INSERT INTO dbo.FactSales_CCI (
    SalesOrderID, ProductID, CustomerID, SalesPersonID,
    OrderDate, DueDate, ShipDate,
    Quantity, UnitPrice, DiscountPct,
    TaxAmt, Freight, TerritoryID,
    CurrencyCode, ModifiedDate
)
SELECT TOP (@MaxRows)
    sod.SalesOrderID,
    sod.ProductID,
    soh.CustomerID,
    soh.SalesPersonID,
    CAST(soh.OrderDate AS DATE) AS OrderDate,
    CAST(soh.DueDate AS DATE) AS DueDate,
    CAST(soh.ShipDate AS DATE) AS ShipDate,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    CAST(sod.UnitPriceDiscount * 100 AS DECIMAL(5,2)) AS DiscountPct,
    sod.LineTotal * 0.08 AS TaxAmt,
    sod.LineTotal * 0.02 AS Freight,
    soh.TerritoryID,
    'USD' AS CurrencyCode,
    soh.ModifiedDate
FROM Sales.SalesOrderDetail sod
INNER JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE soh.OrderDate >= '2011-01-01'
ORDER BY NEWID();
GO

-- Insert ข้อมูลเสร็จสมบูรณ์
GO

-- แสดงจำนวนแถว
SELECT 
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT SalesOrderID) AS UniqueSalesOrders,
    COUNT(DISTINCT ProductID) AS UniqueProducts,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM dbo.FactSales_CCI;
GO

-- =============================================
-- ขั้นตอนที่ 4: ตรวจสอบ Columnstore State
-- =============================================


-- ขั้นตอนที่ 3: ตรวจสอบ Columnstore State


-- ดู Row Groups และ Compression
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    partition_number AS PartitionNum,
    row_group_id AS RowGroupID,
    state_description AS State,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows,
    size_in_bytes / 1024.0 / 1024.0 AS SizeMB,
    CASE 
        WHEN total_rows = 0 THEN 0
        ELSE (deleted_rows * 100.0 / total_rows)
    END AS PercentDeleted,
    CASE 
        WHEN state = 1 THEN 'INVISIBLE'
        WHEN state = 2 THEN 'OPEN'
        WHEN state = 3 THEN 'CLOSED'
        WHEN state = 4 THEN 'COMPRESSED'
        ELSE 'TOMBSTONE'
    END AS StateDetail
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
ORDER BY row_group_id;
GO

-- ดู Compression Info

-- สรุป Compression:
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    SUM(total_rows) AS TotalRows,
    SUM(deleted_rows) AS DeletedRows,
    SUM(size_in_bytes) / 1024.0 / 1024.0 AS TotalSizeMB,
    CASE 
        WHEN SUM(total_rows) > 0 
        THEN SUM(size_in_bytes) * 1.0 / SUM(total_rows)
        ELSE 0
    END AS BytesPerRow
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
GROUP BY object_id;
GO

-- =============================================
-- ขั้นตอนที่ 5: ทดสอบ Query Performance
-- =============================================


-- ขั้นตอนที่ 4: ทดสอบ Query Performance


-- Query 1: Aggregation แบบ Basic
-- Query 1: SUM Sales by Year
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT 
    YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSales,
    AVG(TotalDue) AS AvgOrderValue,
    MIN(TotalDue) AS MinOrderValue,
    MAX(TotalDue) AS MaxOrderValue
FROM dbo.FactSales_CCI
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Query 2: JOIN with Dimension

-- Query 2: Join with Product Dimension
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT 
    p.Name AS ProductName,
    pc.Name AS CategoryName,
    COUNT(*) AS SalesCount,
    SUM(fs.TotalDue) AS TotalSales,
    AVG(fs.UnitPrice) AS AvgUnitPrice
FROM dbo.FactSales_CCI fs
INNER JOIN Production.Product p ON fs.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE fs.OrderDate >= '2012-01-01'
GROUP BY p.Name, pc.Name
HAVING SUM(fs.TotalDue) > 10000
ORDER BY TotalSales DESC;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Query 3: Filter และ Complex Aggregation

-- Query 3: Top Customers by Sales
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT TOP 10
    fs.CustomerID,
    COUNT(DISTINCT fs.SalesOrderID) AS OrderCount,
    SUM(fs.Quantity) AS TotalQuantity,
    SUM(fs.TotalDue) AS TotalSales,
    AVG(fs.DiscountPct) AS AvgDiscount
FROM dbo.FactSales_CCI fs
WHERE fs.OrderDate BETWEEN '2012-01-01' AND '2012-12-31'
GROUP BY fs.CustomerID
ORDER BY TotalSales DESC;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO


-- สำเร็จ! สร้าง Clustered Columnstore Index เสร็จสมบูรณ์

-- สรุป:
-- - ตาราง: dbo.FactSales_CCI
-- - Index Type: Clustered Columnstore
-- - เหมาะสำหรับ: Data Warehousing, Analytics
-- - Compression: สูงมาก
-- - Query Performance: เร็วกว่า Rowstore มาก
GO


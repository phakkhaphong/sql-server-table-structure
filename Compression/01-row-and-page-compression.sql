-- =============================================
-- Script: 01-row-and-page-compression.sql
-- Description: เปรียบเทียบ Row vs Page Compression
-- Database: AdventureWorks2022
-- Server: SQL Server 2008 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Row vs Page Compression ===

GO

-- =============================================
-- ส่วนที่ 1: สร้างตารางตัวอย่าง
-- =============================================

-- === ส่วนที่ 1: สร้างตารางตัวอย่าง ===


-- สร้างตารางสำหรับทดสอบ Compression
IF OBJECT_ID('dbo.TestTable_NoCompression', 'U') IS NOT NULL
    DROP TABLE dbo.TestTable_NoCompression;
GO

IF OBJECT_ID('dbo.TestTable_RowCompressed', 'U') IS NOT NULL
    DROP TABLE dbo.TestTable_RowCompressed;
GO

IF OBJECT_ID('dbo.TestTable_PageCompressed', 'U') IS NOT NULL
    DROP TABLE dbo.TestTable_PageCompressed;
GO

-- สร้างตารางแบบ No Compression
CREATE TABLE dbo.TestTable_NoCompression (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATETIME2 NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity SMALLINT NOT NULL,
    UnitPrice MONEY NOT NULL,
    TotalAmount MONEY NOT NULL,
    Status VARCHAR(10) NOT NULL,
    Notes NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

-- สร้างตารางแบบ Row Compressed
CREATE TABLE dbo.TestTable_RowCompressed (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATETIME2 NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity SMALLINT NOT NULL,
    UnitPrice MONEY NOT NULL,
    TotalAmount MONEY NOT NULL,
    Status VARCHAR(10) NOT NULL,
    Notes NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME()
) WITH (DATA_COMPRESSION = ROW);
GO

-- สร้างตารางแบบ Page Compressed
CREATE TABLE dbo.TestTable_PageCompressed (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATETIME2 NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity SMALLINT NOT NULL,
    UnitPrice MONEY NOT NULL,
    TotalAmount MONEY NOT NULL,
    Status VARCHAR(10) NOT NULL,
    Notes NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME()
) WITH (DATA_COMPRESSION = PAGE);
GO

-- สร้างตาราง 3 แบบเสร็จสมบูรณ์:
--   1. No Compression
--   2. Row Compression
--   3. Page Compression
GO

-- =============================================
-- ส่วนที่ 2: Insert ข้อมูลทดสอบ
-- =============================================


-- === ส่วนที่ 2: Insert ข้อมูลทดสอบ ===


-- Insert ข้อมูลเดียวกันทั้ง 3 ตาราง
-- (ข้อมูลบางส่วนซ้ำกันเพื่อแสดงประสิทธิภาพ Page Compression)
-- กำลัง Insert ข้อมูล 100,000 rows...
GO

WITH SalesData AS (
    SELECT 
        soh.OrderDate,
        soh.CustomerID,
        sod.ProductID,
        sod.OrderQty AS Quantity,
        sod.UnitPrice,
        sod.LineTotal AS TotalAmount,
        CASE soh.Status
            WHEN 1 THEN 'Pending'
            WHEN 2 THEN 'Processing'
            WHEN 3 THEN 'Shipped'
            WHEN 4 THEN 'Delivered'
            ELSE 'Cancelled'
        END AS Status,
        CASE WHEN RAND(CAST(NEWID() AS VARBINARY)) > 0.8 THEN 'Special Order' ELSE NULL END AS Notes
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
)
INSERT INTO dbo.TestTable_NoCompression (OrderDate, CustomerID, ProductID, Quantity, UnitPrice, TotalAmount, Status, Notes)
SELECT TOP 100000 * FROM SalesData;
GO

INSERT INTO dbo.TestTable_RowCompressed (OrderDate, CustomerID, ProductID, Quantity, UnitPrice, TotalAmount, Status, Notes)
SELECT OrderDate, CustomerID, ProductID, Quantity, UnitPrice, TotalAmount, Status, Notes
FROM dbo.TestTable_NoCompression;
GO

INSERT INTO dbo.TestTable_PageCompressed (OrderDate, CustomerID, ProductID, Quantity, UnitPrice, TotalAmount, Status, Notes)
SELECT OrderDate, CustomerID, ProductID, Quantity, UnitPrice, TotalAmount, Status, Notes
FROM dbo.TestTable_NoCompression;
GO

-- Insert ข้อมูลเสร็จสมบูรณ์
GO

-- =============================================
-- ส่วนที่ 3: เปรียบเทียบขนาดตาราง
-- =============================================


-- === ส่วนที่ 3: เปรียบเทียบขนาดตาราง ===


-- ตรวจสอบขนาดตารางแต่ละแบบ
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    SUM(reserved_page_count) * 8.0 / 1024 AS ReservedMB,
    SUM(used_page_count) * 8.0 / 1024 AS UsedMB,
    SUM(row_count) AS RowCount
FROM sys.dm_db_partition_stats
WHERE object_id IN (
    OBJECT_ID('dbo.TestTable_NoCompression'),
    OBJECT_ID('dbo.TestTable_RowCompressed'),
    OBJECT_ID('dbo.TestTable_PageCompressed')
)
GROUP BY object_id
ORDER BY object_id;
GO

-- คำนวณ Ratio การบีบอัด
WITH Sizes AS (
    SELECT 
        OBJECT_NAME(object_id) AS TableName,
        SUM(used_page_count) * 8.0 / 1024 AS UsedMB
    FROM sys.dm_db_partition_stats
    WHERE object_id IN (
        OBJECT_ID('dbo.TestTable_NoCompression'),
        OBJECT_ID('dbo.TestTable_RowCompressed'),
        OBJECT_ID('dbo.TestTable_PageCompressed')
    )
    GROUP BY object_id
)
SELECT 
    n.TableName AS 'No Compression',
    n.UsedMB AS 'Size (MB)',
    r.TableName AS 'Row Compressed',
    r.UsedMB AS 'Size (MB)',
    CAST((1 - r.UsedMB / n.UsedMB) * 100 AS DECIMAL(5,2)) AS 'Row Savings %',
    p.TableName AS 'Page Compressed',
    p.UsedMB AS 'Size (MB)',
    CAST((1 - p.UsedMB / n.UsedMB) * 100 AS DECIMAL(5,2)) AS 'Page Savings %'
FROM Sizes n
CROSS JOIN (SELECT UsedMB FROM Sizes WHERE TableName = 'TestTable_RowCompressed') r
CROSS JOIN (SELECT UsedMB FROM Sizes WHERE TableName = 'TestTable_PageCompressed') p
WHERE n.TableName = 'TestTable_NoCompression';
GO

-- =============================================
-- ส่วนที่ 4: ทดสอบ Query Performance
-- =============================================


-- === ส่วนที่ 4: ทดสอบ Query Performance ===


-- Query 1: SELECT COUNT(*)
-- Query 1: SELECT COUNT(*)
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT COUNT(*) FROM dbo.TestTable_NoCompression;
GO

SELECT COUNT(*) FROM dbo.TestTable_RowCompressed;
GO

SELECT COUNT(*) FROM dbo.TestTable_PageCompressed;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Query 2: Aggregation

-- Query 2: GROUP BY Aggregation
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT 
    YEAR(OrderDate) AS OrderYear,
    Status,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSales
FROM dbo.TestTable_NoCompression
GROUP BY YEAR(OrderDate), Status
ORDER BY OrderYear, Status;
GO

SELECT 
    YEAR(OrderDate) AS OrderYear,
    Status,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSales
FROM dbo.TestTable_PageCompressed
GROUP BY YEAR(OrderDate), Status
ORDER BY OrderYear, Status;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Query 3: Range Scan

-- Query 3: Range Scan with WHERE
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT TOP 1000 *
FROM dbo.TestTable_NoCompression
WHERE OrderDate >= '2013-01-01'
ORDER BY OrderDate DESC;
GO

SELECT TOP 1000 *
FROM dbo.TestTable_PageCompressed
WHERE OrderDate >= '2013-01-01'
ORDER BY OrderDate DESC;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- =============================================
-- ส่วนที่ 5: Index Compression
-- =============================================



-- === ส่วนที่ 5: Nonclustered Index Compression ===


-- สร้าง Index แบบ No Compression
CREATE NONCLUSTERED INDEX IX_NoCompression_OrderDate_CustomerID
ON dbo.TestTable_NoCompression(OrderDate, CustomerID)
INCLUDE (TotalAmount);
GO

-- สร้าง Index แบบ Row Compressed
CREATE NONCLUSTERED INDEX IX_RowCompressed_OrderDate_CustomerID
ON dbo.TestTable_RowCompressed(OrderDate, CustomerID)
INCLUDE (TotalAmount)
WITH (DATA_COMPRESSION = ROW);
GO

-- สร้าง Index แบบ Page Compressed
CREATE NONCLUSTERED INDEX IX_PageCompressed_OrderDate_CustomerID
ON dbo.TestTable_PageCompressed(OrderDate, CustomerID)
INCLUDE (TotalAmount)
WITH (DATA_COMPRESSION = PAGE);
GO

-- สร้าง Indexes เสร็จสมบูรณ์
GO

-- เปรียบเทียบขนาด Indexes

-- เปรียบเทียบขนาด Indexes:
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    p.index_id,
    SUM(p.used_page_count) * 8.0 / 1024 AS UsedMB,
    SUM(p.row_count) AS RowCount
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats p ON i.object_id = p.object_id AND i.index_id = p.index_id
WHERE i.name LIKE '%OrderDate_CustomerID%'
GROUP BY i.object_id, i.name, p.index_id
ORDER BY TableName, IndexName;
GO

-- =============================================
-- สรุป Best Practices
-- =============================================



-- === สรุป Best Practices ===

-- 1. Row Compression:
--    ✅ ใช้ CPU น้อย
--    ✅ เหมาะสำหรับ OLTP
--    ✅ Safe Default Choice
--    ✅ บีบอัดได้ 20-30%

-- 2. Page Compression:
--    ✅ บีบอัดได้สูงกว่า (40-60%)
--    ✅ เหมาะสำหรับ Read-Heavy
--    ✅ ใช้ CPU มากกว่าเล็กน้อย
--    ✅ ดีกับข้อมูลที่ซ้ำกัน

-- 3. ข้อควรพิจารณา:
--    - ทดสอบใน Test Environment ก่อน
--    - Monitor CPU Usage
--    - ใช้ Compression Advisor Tool
--    - Backup ก่อน Apply Compression

-- 4. เมื่อไม่ควรใช้:
--    ❌ CPU Constrained Systems
--    ❌ Tables ที่ Update บ่อยมาก
--    ❌ Tables ขนาดเล็ก (< 100K rows)
GO


-- สำเร็จ! จบการเปรียบเทียบ Row vs Page Compression
GO


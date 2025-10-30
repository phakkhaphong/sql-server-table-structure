-- =============================================
-- Script: 03-operations-and-maintenance.sql
-- Description: การใช้งานและดูแลรักษา Columnstore Indexes
-- Database: AdventureWorks2022
-- Server: SQL Server 2014 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Columnstore Operations & Maintenance ===

GO

-- =============================================
-- ส่วนที่ 1: DML Operations (INSERT/UPDATE/DELETE)
-- =============================================

-- === ส่วนที่ 1: DML Operations ===

GO

-- INSERT: ทดสอบการ Insert ข้อมูล
-- 1.1 การ INSERT ข้อมูลลง Columnstore

IF OBJECT_ID('dbo.FactSales_CCI', 'U') IS NULL
BEGIN
    -- ERROR: ไม่พบตาราง dbo.FactSales_CCI
    -- กรุณารัน 01-create-clustered-columnstore.sql ก่อน
    RETURN;
END
GO

-- Insert ข้อมูลเล็กน้อย (< 102,400 rows = Delta Store)
-- INSERT ข้อมูลจำนวนเล็กน้อย (Delta Store)...

INSERT INTO dbo.FactSales_CCI (
    SalesOrderID, ProductID, CustomerID, SalesPersonID,
    OrderDate, DueDate, ShipDate,
    Quantity, UnitPrice, DiscountPct, TaxAmt, Freight,
    TerritoryID, CurrencyCode
)
VALUES 
    (9999999, 707, 12345, 279, '2024-10-01', '2024-10-08', NULL, 10, 1499.99, 0.1, 120, 30, 1, 'USD'),
    (9999998, 708, 12346, 279, '2024-10-01', '2024-10-08', NULL, 5, 2499.99, 0.15, 100, 25, 1, 'USD');
GO

-- ตรวจสอบ Delta Store
SELECT 
    state_description AS State,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
  AND state_description LIKE '%OPEN%'
ORDER BY row_group_id DESC;
GO


GO

-- INSERT จำนวนมาก (> 102,400 rows = Row Groups)
-- 1.2 การ INSERT ข้อมูลจำนวนมาก (Direct to Row Groups)...

-- สร้างข้อมูลจำนวนมาก
INSERT INTO dbo.FactSales_CCI (
    SalesOrderID, ProductID, CustomerID, SalesPersonID,
    OrderDate, DueDate, ShipDate,
    Quantity, UnitPrice, DiscountPct, TaxAmt, Freight,
    TerritoryID, CurrencyCode
)
SELECT TOP 150000
    8888888 + ROW_NUMBER() OVER (ORDER BY NEWID()),
    p.ProductID,
    ABS(CHECKSUM(NEWID())) % 1000 + 1,
    ABS(CHECKSUM(NEWID())) % 280 + 275,
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 365, '2024-01-01'),
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 365 + 7, '2024-01-01'),
    NULL,
    ABS(CHECKSUM(NEWID())) % 100 + 1,
    100 + (ABS(CHECKSUM(NEWID())) % 900),
    (ABS(CHECKSUM(NEWID())) % 30) / 100.0,
    10,
    5,
    ABS(CHECKSUM(NEWID())) % 10 + 1,
    'USD'
FROM Production.Product p
CROSS JOIN (SELECT TOP 5000 1 AS n FROM sys.objects) x
WHERE p.ProductID IS NOT NULL;
GO

-- INSERT 150,000 rows เสร็จสมบูรณ์
GO

-- ตรวจสอบ Row Groups ใหม่
SELECT 
    state_description AS State,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows,
    size_in_bytes / 1024.0 / 1024.0 AS SizeMB
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
ORDER BY row_group_id DESC;
GO


GO

-- UPDATE: ทดสอบการ Update ข้อมูล
-- 1.3 การ UPDATE ข้อมูล

-- Update เพียงเล็กน้อย
UPDATE dbo.FactSales_CCI
SET DiscountPct = 0.25,
    TaxAmt = TaxAmt * 1.1
WHERE SalesOrderID IN (9999999, 9999998);
GO

-- ตรวจสอบ Impact ต่อ Columnstore
SELECT 
    state_description AS State,
    COUNT(*) AS GroupCount,
    SUM(total_rows) AS TotalRows,
    SUM(deleted_rows) AS DeletedRows
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
GROUP BY state_description;
GO


GO

-- DELETE: ทดสอบการ Delete ข้อมูล
-- 1.4 การ DELETE ข้อมูล

DELETE FROM dbo.FactSales_CCI
WHERE SalesOrderID BETWEEN 8888888 AND 8888889;
GO

-- ตรวจสอบ Deleted Rows
SELECT 
    state_description AS State,
    SUM(total_rows) AS TotalRows,
    SUM(deleted_rows) AS DeletedRows,
    CASE 
        WHEN SUM(total_rows) > 0 
        THEN SUM(deleted_rows) * 100.0 / SUM(total_rows)
        ELSE 0
    END AS PercentDeleted
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
GROUP BY state_description;
GO



GO

-- =============================================
-- ส่วนที่ 2: Index Maintenance
-- =============================================

-- === ส่วนที่ 2: Index Maintenance ===

GO

-- Reorganize Index
-- 2.1 Reorganize Columnstore Index
-- ข้อดี: ใช้งาน App ตลอดเวลา, CPU น้อย, ช้ากว่า Rebuild
GO

ALTER INDEX CCI_FactSales_CCI ON dbo.FactSales_CCI REORGANIZE;
GO

-- Reorganize เสร็จสมบูรณ์
GO

-- ตรวจสอบผลลัพธ์
SELECT 
    state_description AS State,
    COUNT(*) AS GroupCount,
    SUM(total_rows) AS TotalRows,
    SUM(deleted_rows) AS DeletedRows
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
GROUP BY state_description
ORDER BY state_description;
GO


GO

-- Rebuild Index (ถ้าจำเป็น)
-- 2.2 Rebuild Columnstore Index
-- คำเตือน: Downtime สูงกว่า, ใช้ CPU สูง, แต่ทำความสะอาดได้ดีกว่า
-- (ข้ามใน Demo - ใช้เวลาเยอะ)
GO

/*
ALTER INDEX CCI_FactSales_CCI ON dbo.FactSales_CCI REBUILD;
GO
*/

-- Rebuild with Options

-- ตัวอย่างคำสั่ง Rebuild พร้อม Options:

-- -- Rebuild พร้อม MAXDOP
-- ALTER INDEX CCI_FactSales_CCI ON dbo.FactSales_CCI
-- REBUILD WITH (MAXDOP = 4);

-- -- Rebuild แค่ Partition
-- ALTER INDEX CCI_FactSales_CCI ON dbo.FactSales_CCI
-- REBUILD PARTITION = 1;

-- -- Rebuild Online (Enterprise Edition)
-- ALTER INDEX CCI_FactSales_CCI ON dbo.FactSales_CCI
-- REBUILD WITH (ONLINE = ON);
GO

-- =============================================
-- ส่วนที่ 3: ตรวจสอบ Health ของ Columnstore
-- =============================================



-- === ส่วนที่ 3: Columnstore Health Check ===

GO

-- 3.1 Delta Store มีข้อมูลมากเกินไปหรือไม่
-- 3.1 Delta Store Analysis
GO

SELECT 
    state_description AS State,
    COUNT(*) AS GroupCount,
    SUM(total_rows) AS TotalRows,
    CASE 
        WHEN SUM(total_rows) > 0 
        THEN 'Need Rebuild - Delta Store > 100K'
        ELSE 'OK'
    END AS Recommendation
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
  AND state_description LIKE '%OPEN%'
GROUP BY state_description;
GO

-- 3.2 Fragmentation (Deleted Rows)

-- 3.2 Fragmentation Analysis
GO

SELECT 
    state_description AS State,
    COUNT(*) AS GroupCount,
    SUM(total_rows) AS TotalRows,
    SUM(deleted_rows) AS DeletedRows,
    CASE 
        WHEN SUM(total_rows) > 0 
        THEN SUM(deleted_rows) * 100.0 / SUM(total_rows)
        ELSE 0
    END AS PercentFragmented,
    CASE 
        WHEN SUM(deleted_rows) * 100.0 / SUM(total_rows) > 20 
        THEN 'Need Rebuild'
        ELSE 'OK'
    END AS Recommendation
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
GROUP BY state_description;
GO

-- 3.3 Row Groups Analysis

-- 3.3 Row Groups Detail
GO

SELECT 
    row_group_id AS RowGroupID,
    state_description AS State,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows,
    size_in_bytes / 1024.0 / 1024.0 AS SizeMB,
    CASE 
        WHEN total_rows < 100000 THEN 'Small - Consider Merge'
        WHEN total_rows BETWEEN 100000 AND 1048576 THEN 'Good Size'
        ELSE 'Large'
    END AS SizeStatus,
    CASE 
        WHEN deleted_rows * 100.0 / NULLIF(total_rows, 0) > 20 THEN 'High Fragmentation'
        ELSE 'OK'
    END AS FragmentationStatus
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
ORDER BY row_group_id;
GO

-- =============================================
-- Best Practices
-- =============================================



-- === Best Practices สำหรับ Columnstore Maintenance ===

-- 1. Maintenance Schedule:
--    - Reorganize: ทุกวัน (Off-peak)
--    - Rebuild: ทุกสัปดาห์ หรือเมื่อ Fragmentation > 20%

-- 2. เมื่อควรทำ Rebuild:
--    ✅ Delta Store > 100K rows
--    ✅ Deleted Rows > 20%
--    ✅ Compression Ratio ต่ำลง
--    ✅ Query Performance ลดลง

-- 3. Reorganize vs Rebuild:
--    - Reorganize: Online, CPU น้อย, ทำแค่ Delta Store
--    - Rebuild: Offline, CPU มาก, ทำความสะอาดทุกอย่าง

-- 4. Partitioned Tables:
--    - Rebuild ทีละ Partition
--    - ทำแค่ Partitions ที่ Active
--    - ใช้ Partition Switching สำหรับ Archive

-- 5. Monitoring:
--    - Delta Store Size
--    - Fragmentation %
--    - Query Performance
--    - Compression Ratio
GO


-- สำเร็จ! จบการสาธิต Operations & Maintenance
GO


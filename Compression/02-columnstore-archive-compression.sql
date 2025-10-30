-- =============================================
-- Script: 02-columnstore-archive-compression.sql
-- Description: การใช้ Columnstore Archive Compression
-- Database: AdventureWorks2022
-- Server: SQL Server 2014 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Columnstore Archive Compression ===

-- Archive Compression บีบอัดมากที่สุด แต่ Query ช้ากว่า
-- เหมาะสำหรับ: ข้อมูลเก่าที่ไม่ Query บ่อย

GO

-- =============================================
-- ส่วนที่ 1: ตรวจสอบตาราง Columnstore ที่มีอยู่
-- =============================================

-- === ส่วนที่ 1: ตรวจสอบ Columnstore Table ===


IF OBJECT_ID('dbo.FactSales_CCI', 'U') IS NULL
BEGIN
    -- ERROR: ไม่พบตาราง dbo.FactSales_CCI
    -- กรุณารัน 01-create-clustered-columnstore.sql ก่อน
    RETURN;
END
GO

-- ตรวจสอบ Compression State ปัจจุบัน
-- Compression State ปัจจุบัน:
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    SUM(total_rows) AS TotalRows,
    SUM(size_in_bytes) / 1024.0 / 1024.0 AS SizeMB,
    CASE 
        WHEN SUM(total_rows) > 0 
        THEN (SUM(size_in_bytes) * 1.0 / SUM(total_rows)) 
        ELSE 0
    END AS BytesPerRow
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
GROUP BY object_id;
GO

-- ตรวจสอบ Compression Type

-- Compression Type:
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    data_compression_desc AS CompressionType
FROM sys.partitions
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
  AND index_id IN (0,1)
GROUP BY object_id, data_compression_desc;
GO

-- =============================================
-- ส่วนที่ 2: ตรวจสอบ Row Groups
-- =============================================


-- === ส่วนที่ 2: Row Groups Detail ===


SELECT 
    row_group_id AS RowGroupID,
    state_description AS State,
    total_rows AS TotalRows,
    size_in_bytes / 1024.0 AS SizeKB,
    CASE 
        WHEN total_rows > 0 
        THEN (size_in_bytes * 1.0 / total_rows)
        ELSE 0
    END AS BytesPerRow
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
ORDER BY row_group_id;
GO

-- =============================================
-- ส่วนที่ 3: เปลี่ยนเป็น Archive Compression
-- =============================================


-- === ส่วนที่ 3: Apply Archive Compression ===

-- คำเตือน: Archive Compression ทำให้ Query ช้าลง
-- เหมาะสำหรับข้อมูลที่ Query น้อย


-- ตรวจสอบจำนวน Row Groups ก่อน
DECLARE @RowGroupCount INT;
SELECT @RowGroupCount = COUNT(*)
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
  AND state_description = 'COMPRESSED';

-- จำนวน Row Groups ที่จะ Rebuild: 


-- Rebuild with Archive Compression
-- กำลัง Rebuild ด้วย Archive Compression...
-- (อาจใช้เวลานาน - ขึ้นอยู่กับจำนวนข้อมูล)
GO

-- หมายเหตุ: ใน Production อาจต้องทำ Maintenance Window
ALTER INDEX CCI_FactSales_CCI ON dbo.FactSales_CCI
REBUILD PARTITION = ALL
WITH (COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);
GO

-- Rebuild เสร็จสมบูรณ์
GO

-- ตรวจสอบผลลัพธ์หลัง Compression

-- ผลลัพธ์หลัง Archive Compression:
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    SUM(total_rows) AS TotalRows,
    SUM(size_in_bytes) / 1024.0 / 1024.0 AS SizeMB,
    CASE 
        WHEN SUM(total_rows) > 0 
        THEN (SUM(size_in_bytes) * 1.0 / SUM(total_rows)) 
        ELSE 0
    END AS BytesPerRow
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
GROUP BY object_id;
GO

-- ตรวจสอบ Compression Type ใหม่

-- Compression Type (หลัง Archive):
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    data_compression_desc AS CompressionType
FROM sys.partitions
WHERE object_id = OBJECT_ID('dbo.FactSales_CCI')
  AND index_id IN (0,1)
GROUP BY object_id, data_compression_desc;
GO

-- =============================================
-- ส่วนที่ 4: Partitioned Table + Archive Compression
-- =============================================



-- === ส่วนที่ 4: Partition Level Compression ===
-- ประโยชน์: Archive แค่บาง Partitions ที่เก่า


-- ตัวอย่าง: สมมติว่ามี Partitioned Table
-- Archive แค่ Partition เก่าที่ > 2 ปี

-- ตัวอย่างคำสั่ง:

-- -- Archive Partition เก่าเท่านั้น
-- ALTER INDEX CCI_FactSales ON dbo.FactSales
-- REBUILD PARTITION = 1
-- WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);

-- -- Columnstore ปกติสำหรับ Partition ใหม่
-- ALTER INDEX CCI_FactSales ON dbo.FactSales
-- REBUILD PARTITION = 7
-- WITH (DATA_COMPRESSION = COLUMNSTORE);
GO

-- =============================================
-- ส่วนที่ 5: ทดสอบ Query Performance
-- =============================================



-- === ส่วนที่ 5: Query Performance Comparison ===


-- Query 1: Aggregation
-- Query 1: Aggregation (ควรช้ากว่าปกติเล็กน้อย)
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT 
    YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSales
FROM dbo.FactSales_CCI
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- =============================================
-- ส่วนที่ 6: Switching กลับเป็น Columnstore ปกติ
-- =============================================



-- === ส่วนที่ 6: Revert to Normal Columnstore ===
-- ถ้าต้องการ Query เร็วขึ้นสามารถเปลี่ยนกลับได้


-- ตัวอย่างคำสั่ง:

-- ALTER INDEX CCI_FactSales_CCI ON dbo.FactSales_CCI
-- REBUILD PARTITION = ALL
-- WITH (DATA_COMPRESSION = COLUMNSTORE);
GO

-- =============================================
-- Best Practices
-- =============================================



-- === Best Practices สำหรับ Archive Compression ===

-- 1. ใช้เมื่อ:
--    ✅ Historical Data (> 2 years old)
--    ✅ Rarely Queried Data
--    ✅ Archive/Staging Tables
--    ✅ Storage Costs สำคัญ

-- 2. ไม่ใช้เมื่อ:
--    ❌ Frequently Queried Data
--    ❌ Real-time Analytics
--    ❌ Query Performance สำคัญมาก
--    ❌ Small Tables

-- 3. Strategy:
--    - ใช้ Partitioned Tables
--    - Archive แค่ Partition เก่า
--    - Current Data = COLUMNSTORE
--    - Old Data = COLUMNSTORE_ARCHIVE

-- 4. Maintenance:
--    - Rebuild หลัง Archive (ไฟล์เล็กลงมาก)
--    - Monitor Query Performance
--    - มี Plan สำหรับ Rollback

-- 5. Compression Ratios:
--    - COLUMNSTORE: 10:1 (normal)
--    - COLUMNSTORE_ARCHIVE: 50:1 to 100:1
--    - ขึ้นอยู่กับข้อมูล
GO


-- สำเร็จ! จบการสาธิต Archive Compression
GO


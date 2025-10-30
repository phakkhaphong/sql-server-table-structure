-- =============================================
-- Script: 03-compression-management.sql
-- Description: การจัดการ Compression แบบ Dynamic
-- Database: AdventureWorks2022
-- Server: SQL Server 2008 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Compression Management ===

GO

-- =============================================
-- ส่วนที่ 1: แปลงตารางเดิมเป็น Compressed
-- =============================================

-- === ส่วนที่ 1: Convert Existing Tables ===


-- ตัวอย่าง: แปลงตาราง Production.Product เป็น Page Compressed
-- ตัวอย่าง: แปลง Production.Product เป็น Page Compressed


-- ตรวจสอบสถานะปัจจุบัน
SELECT 
    t.name AS TableName,
    p.data_compression_desc AS CurrentCompression,
    p.partition_number AS PartitionNum
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE t.name = 'Product'
  AND SCHEMA_NAME(t.schema_id) = 'Production'
  AND p.index_id IN (0,1);
GO

-- แปลงเป็น Page Compression
-- คำเตือน: ใน Production ต้อง Backup ก่อน

-- คำเตือน: ตัวอย่างนี้จะข้ามการรันจริงเพื่อความปลอดภัย

-- คำสั่งที่ใช้:

-- ALTER TABLE Production.Product
-- REBUILD WITH (DATA_COMPRESSION = PAGE);
GO

-- =============================================
-- ส่วนที่ 2: Compression Advisor
-- =============================================



-- === ส่วนที่ 2: Compression Advisor ===


-- ใช้ sp_estimate_data_compression_savings เพื่อประเมิน
-- ประเมินการบีบอัด: Production.Product


EXEC sp_estimate_data_compression_savings
    @schema_name = 'Production',
    @object_name = 'Product',
    @index_id = NULL,
    @partition_number = NULL,
    @data_compression = 'PAGE';
GO

-- =============================================
-- ส่วนที่ 3: Dynamic Compression by Partition
-- =============================================



-- === ส่วนที่ 3: Partition Level Compression ===


-- ตัวอย่าง: ถ้ามี Partitioned Table
-- ตัวอย่าง: ใช้ Compression ต่างกันในแต่ละ Partition

-- -- Partition เก่า: Archive Compression
-- ALTER INDEX ... ON ...
-- REBUILD PARTITION = 1
-- WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);

-- -- Partition ใหม่: Normal Compression
-- ALTER INDEX ... ON ...
-- REBUILD PARTITION = 7
-- WITH (DATA_COMPRESSION = COLUMNSTORE);
GO

-- =============================================
-- ส่วนที่ 4: Compression Monitoring
-- =============================================



-- === ส่วนที่ 4: Compression Monitoring ===


-- ตรวจสอบตารางที่มี Compression
SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    p.data_compression_desc AS CompressionType,
    p.partition_number AS PartitionNum,
    SUM(p.rows) AS RowCount,
    SUM(a.total_pages) * 8 / 1024.0 AS TotalMB,
    SUM(a.used_pages) * 8 / 1024.0 AS UsedMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
  AND p.data_compression > 0
GROUP BY SCHEMA_NAME(t.schema_id), t.name, i.name, p.data_compression_desc, p.partition_number
ORDER BY SchemaName, TableName, IndexName, PartitionNum;
GO

-- =============================================
-- ส่วนที่ 5: Compression Best Practices
-- =============================================



-- === Best Practices Summary ===

-- 1. เมื่อควรใช้:
--    ✅ Tables ขนาดใหญ่ (> 100K rows)
--    ✅ Read-Heavy Workloads
--    ✅ Storage Costs สำคัญ
--    ✅ CPU มีพอเพียง

-- 2. Compression Selection:
--    - OLTP → Row Compression
--    - Read-Heavy → Page Compression
--    - Analytics → Columnstore
--    - Archive → Columnstore Archive

-- 3. Implementation Steps:
--    1. Backup Database
--    2. Estimate Savings (Compression Advisor)
--    3. Test in Development
--    4. Plan Maintenance Window
--    5. Monitor Performance

-- 4. Monitoring:
--    - Query Performance
--    - CPU Usage
--    - Storage Savings
--    - Index Maintenance Time
GO


-- สำเร็จ! จบการสาธิต Compression Management
GO


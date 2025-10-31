-- =============================================
-- Script: 05-table-structure-types.sql
-- Description: โครงสร้างตารางแบบต่างๆ: HEAP, Rowstore Clustered Index, Columnstore Clustered Index
-- Database: AdventureWorks2022
-- Server: SQL Server 2014 ขึ้นไป (Columnstore)
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- คำอธิบาย: เปรียบเทียบโครงสร้างตาราง 3 แบบ พร้อม Use Cases
-- =============================================

USE AdventureWorks2022;
GO

-- =============================================
-- ส่วนที่ 1: HEAP Table (ไม่มี Clustered Index)
-- =============================================

-- === ส่วนที่ 1: HEAP Table ===

-- คำอธิบาย: 
-- - HEAP = ตารางที่ไม่มี Clustered Index
-- - ข้อมูลเก็บแบบ Unordered (ไม่เรียงลำดับ)
-- - ใช้ IAM (Index Allocation Map) เพื่อหาข้อมูล
-- - ⚠️  ไม่แนะนำสำหรับ Production (ควรมี Clustered Index)

-- Use Cases:
-- ❌ ไม่แนะนำ: ปกติแล้วทุกตารางควรมี Clustered Index
-- ✅ Temporary Tables: อาจใช้ HEAP สำหรับ Temp Table ชั่วคราว
-- ✅ Staging Tables: ใช้เป็น Staging ก่อน Load ข้อมูล

-- ขั้นตอนที่ 1: ลบตารางเก่า (ถ้ามี)
IF OBJECT_ID('dbo.ProductHeap', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.ProductHeap;
END
GO

-- สร้างตารางแบบ HEAP (ไม่มี Clustered Index)
CREATE TABLE dbo.ProductHeap (
    ProductID INT NOT NULL,              -- Primary Key แต่ไม่ได้เป็น Clustered
    ProductCode VARCHAR(20) NOT NULL,
    ProductName NVARCHAR(100) NOT NULL,
    CategoryID INT NULL,
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    CONSTRAINT PK_ProductHeap PRIMARY KEY NONCLUSTERED (ProductID)  -- ⚠️ NONCLUSTERED Primary Key
);
GO

-- ตรวจสอบโครงสร้าง: HEAP
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_primary_key AS IsPrimaryKey,
    CASE 
        WHEN i.type_desc = 'HEAP' THEN 'HEAP Table (No Clustered Index)'
        WHEN i.type_desc = 'CLUSTERED' THEN 'Clustered Index'
        WHEN i.type_desc = 'NONCLUSTERED' THEN 'Nonclustered Index'
        WHEN i.type_desc = 'CLUSTERED COLUMNSTORE' THEN 'Clustered Columnstore'
        ELSE i.type_desc
    END AS Description
FROM sys.tables t
LEFT JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.name = 'ProductHeap'
ORDER BY i.index_id;
GO

-- ⚠️  ข้อเสียของ HEAP:
-- 1. Forwarded Records: UPDATE ทำให้เกิด Forwarded Records → Performance ลดลง
-- 2. No Ordering: ข้อมูลไม่เรียงลำดับ → Scan ช้า
-- 3. Fragmentation: Heap Fragmentation ยากต่อการจัดการ
-- 4. Page Split: UPDATE ที่ทำให้แถวใหญ่ขึ้น → Forwarded Records

-- =============================================
-- ส่วนที่ 2: Rowstore Clustered Index
-- =============================================

-- === ส่วนที่ 2: Rowstore Clustered Index ===

-- คำอธิบาย:
-- - Clustered Index = โครงสร้างหลักที่เรียงลำดับข้อมูลตาม Key
-- - ข้อมูลใน Leaf Level = ข้อมูลจริง (ไม่ต้อง Lookup)
-- - ✅ BEST PRACTICE: ทุกตารางควรมี 1 Clustered Index
-- - ✅ RECOMMENDED: ใช้ Surrogate Key (INT IDENTITY(1,1)) สำหรับ Clustered Primary Key

-- Use Cases:
-- ✅ OLTP Tables: Transaction Tables ที่ต้องการ Single-row Lookup
-- ✅ Tables with Range Queries: Query ที่ใช้ BETWEEN, >, <
-- ✅ Foreign Key Lookups: JOIN ที่ใช้ Primary Key
-- ✅ Default Choice: สำหรับตารางส่วนใหญ่

-- ขั้นตอนที่ 1: ลบตารางเก่า (ถ้ามี)
IF OBJECT_ID('dbo.ProductRowstore', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.ProductRowstore;
END
GO

-- สร้างตารางแบบ Rowstore Clustered Index
CREATE TABLE dbo.ProductRowstore (
    ProductID INT IDENTITY(1,1),              -- ✅ Surrogate Key, Increment = 1 (Sequential)
    ProductCode VARCHAR(20) NOT NULL,
    ProductName NVARCHAR(100) NOT NULL,
    CategoryID INT NULL,
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    CONSTRAINT PK_ProductRowstore PRIMARY KEY CLUSTERED (ProductID)  -- ✅ CLUSTERED Primary Key
);
GO

-- เพิ่ม Nonclustered Index สำหรับ Lookup
CREATE UNIQUE INDEX IX_ProductRowstore_ProductCode 
ON dbo.ProductRowstore(ProductCode);
GO

CREATE INDEX IX_ProductRowstore_CategoryID 
ON dbo.ProductRowstore(CategoryID)
INCLUDE (ProductName, Price);  -- Covering Index
GO

-- ตรวจสอบโครงสร้าง: Rowstore Clustered
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_primary_key AS IsPrimaryKey,
    CASE 
        WHEN i.type_desc = 'HEAP' THEN 'HEAP Table (No Clustered Index)'
        WHEN i.type_desc = 'CLUSTERED' THEN 'Clustered Index'
        WHEN i.type_desc = 'NONCLUSTERED' THEN 'Nonclustered Index'
        WHEN i.type_desc = 'CLUSTERED COLUMNSTORE' THEN 'Clustered Columnstore'
        ELSE i.type_desc
    END AS Description
FROM sys.tables t
LEFT JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.name = 'ProductRowstore'
ORDER BY i.index_id;
GO

-- ✅ ข้อดีของ Rowstore Clustered:
-- 1. Ordered Data: ข้อมูลเรียงตาม Key → Range Queries เร็ว
-- 2. No Lookup: Leaf = Data → Single-row Lookup เร็วมาก
-- 3. Sequential Insert: IDENTITY(1,1) → No Page Split
-- 4. Fragmentation Control: Rebuild/Reorganize ได้ง่าย

-- =============================================
-- ส่วนที่ 3: Columnstore Clustered Index
-- =============================================

-- === ส่วนที่ 3: Columnstore Clustered Index ===

-- คำอธิบาย:
-- - Clustered Columnstore Index = โครงสร้างหลักที่เก็บข้อมูลแบบ Column-based
-- - ข้อมูลบีบอัดสูงมาก (10x มากกว่า Rowstore)
-- - เหมาะสำหรับ Analytics, Aggregation, Scan
-- - ⚠️  ไม่เหมาะสำหรับ Single-row Lookup, Heavy DML

-- Use Cases:
-- ✅ Data Warehousing: Fact Tables ขนาดใหญ่
-- ✅ Analytics/Reporting: Aggregate Queries, GROUP BY
-- ✅ Historical Data: ข้อมูลประวัติที่ Query เยอะ
-- ✅ Read-Heavy Workloads: OLAP, BI Workloads
-- ❌ OLTP: Transaction ที่ต้องการ < 1ms Response Time
-- ❌ Heavy DML: UPDATE/DELETE บ่อยมาก

-- ขั้นตอนที่ 1: ลบตารางเก่า (ถ้ามี)
IF OBJECT_ID('dbo.ProductColumnstore', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.ProductColumnstore;
END
GO

-- สร้างตารางแบบ Clustered Columnstore Index
CREATE TABLE dbo.ProductColumnstore (
    ProductID INT NOT NULL,
    ProductCode VARCHAR(20) NOT NULL,
    ProductName NVARCHAR(100) NOT NULL,
    CategoryID INT NULL,
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    INDEX CCI_ProductColumnstore CLUSTERED COLUMNSTORE  -- ✅ Clustered Columnstore Index
);
GO

-- ⚠️  หมายเหตุ: Columnstore ไม่สามารถมี Clustered Primary Key แบบ Rowstore ได้
-- ทางเลือก:
-- 1. ใช้ UNIQUE NONCLUSTERED INDEX สำหรับ Primary Key Constraint
-- 2. หรือใช้ UNIQUE Constraint ที่ไม่ใช่ Clustered

-- เพิ่ม Unique Constraint (Nonclustered) สำหรับ Primary Key
ALTER TABLE dbo.ProductColumnstore
ADD CONSTRAINT PK_ProductColumnstore PRIMARY KEY NONCLUSTERED (ProductID);
GO

ALTER TABLE dbo.ProductColumnstore
ADD CONSTRAINT UQ_ProductColumnstore_ProductCode UNIQUE NONCLUSTERED (ProductCode);
GO

-- ตรวจสอบโครงสร้าง: Columnstore Clustered
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_primary_key AS IsPrimaryKey,
    CASE 
        WHEN i.type_desc = 'HEAP' THEN 'HEAP Table (No Clustered Index)'
        WHEN i.type_desc = 'CLUSTERED' THEN 'Clustered Index'
        WHEN i.type_desc = 'NONCLUSTERED' THEN 'Nonclustered Index'
        WHEN i.type_desc = 'CLUSTERED COLUMNSTORE' THEN 'Clustered Columnstore'
        ELSE i.type_desc
    END AS Description
FROM sys.tables t
LEFT JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.name = 'ProductColumnstore'
ORDER BY i.index_id;
GO

-- ตรวจสอบ Columnstore Row Groups
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    row_group_id AS RowGroupID,
    state_description AS State,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows,
    size_in_bytes / 1024.0 / 1024.0 AS SizeMB
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('dbo.ProductColumnstore')
ORDER BY row_group_id;
GO

-- ✅ ข้อดีของ Columnstore Clustered:
-- 1. High Compression: บีบอัดได้มากกว่า Rowstore 10x
-- 2. Fast Scan: Scan ข้อมูลเร็วมาก (Column-based)
-- 3. Aggregation: GROUP BY, SUM, AVG เร็วมาก (Batch Mode)
-- 4. Analytics: เหมาะสำหรับ Analytics Queries

-- ⚠️  ข้อเสียของ Columnstore Clustered:
-- 1. Single-row Lookup: ช้ากว่า Rowstore Clustered
-- 2. DML Performance: UPDATE/DELETE ใช้ Resources มาก
-- 3. Minimum Data: ต้องการข้อมูลจำนวนมาก (> 1M rows) เพื่อประสิทธิภาพสูงสุด
-- 4. Batch Mode: ต้องมี Batch > 900 rows เพื่อ Batch Mode

-- =============================================
-- ส่วนที่ 4: เปรียบเทียบโครงสร้าง
-- =============================================

-- === ส่วนที่ 4: เปรียบเทียบโครงสร้าง ===

-- เปรียบเทียบโครงสร้างตารางทั้ง 3 แบบ
SELECT 
    'HEAP' AS StructureType,
    '❌ ไม่แนะนำ' AS Recommendation,
    'Staging, Temporary' AS UseCases,
    'No Ordering, Forwarded Records' AS Characteristics
UNION ALL
SELECT 
    'Rowstore Clustered',
    '✅ แนะนำ (Default)',
    'OLTP, Transaction Tables',
    'Ordered, Fast Lookup, Sequential Insert'
UNION ALL
SELECT 
    'Columnstore Clustered',
    '✅ แนะนำ (Analytics)',
    'Data Warehouse, Analytics, Reporting',
    'High Compression, Fast Scan, Batch Mode';

-- =============================================
-- ส่วนที่ 5: Best Practices Summary
-- =============================================

-- === Best Practices Summary ===

-- 1. HEAP Table:
--    - ❌ ไม่แนะนำสำหรับ Production
--    - ⚠️  ปกติแล้วทุกตารางควรมี Clustered Index
--    - ✅ อาจใช้สำหรับ Temporary/Staging Tables

-- 2. Rowstore Clustered Index:
--    - ✅ BEST PRACTICE: Default Choice สำหรับตารางส่วนใหญ่
--    - ✅ ใช้ Surrogate Key (INT IDENTITY(1,1)) สำหรับ Clustered Primary Key
--    - ✅ เหมาะสำหรับ: OLTP, Single-row Lookup, Range Queries
--    - ✅ Sequential Insert → No Page Split

-- 3. Columnstore Clustered Index:
--    - ✅ BEST PRACTICE: สำหรับ Data Warehouse, Analytics
--    - ✅ เหมาะสำหรับ: Fact Tables ขนาดใหญ่, Aggregate Queries
--    - ⚠️  ไม่เหมาะสำหรับ: OLTP, Heavy DML, Single-row Lookup
--    - ⚠️  ต้องการข้อมูลจำนวนมาก (> 1M rows) เพื่อประสิทธิภาพสูงสุด

-- 4. การเลือกโครงสร้าง:
--    - OLTP Workload → Rowstore Clustered Index
--    - Analytics/Reporting → Columnstore Clustered Index
--    - Hybrid (OLTP + Analytics) → Rowstore + Nonclustered Columnstore Index
--    - Staging/Temporary → HEAP (ชั่วคราว)

GO

-- =============================================
-- ส่วนที่ 6: ตัวอย่างการ Query
-- =============================================

-- === ส่วนที่ 6: ตัวอย่างการ Query ===

-- ⚠️  หมายเหตุ: ตารางตัวอย่างนี้ยังไม่มีข้อมูล
-- ใน Production ให้ใส่ข้อมูลก่อน Query

-- Query 1: Single-row Lookup (เหมาะกับ Rowstore Clustered)
-- SELECT * FROM dbo.ProductRowstore WHERE ProductID = 123;
-- → Fast: ใช้ Clustered Index Seek

-- Query 2: Range Query (เหมาะกับ Rowstore Clustered)
-- SELECT * FROM dbo.ProductRowstore WHERE ProductID BETWEEN 100 AND 200;
-- → Fast: ใช้ Clustered Index Range Scan

-- Query 3: Aggregate Query (เหมาะกับ Columnstore Clustered)
-- SELECT CategoryID, SUM(Price), AVG(Price), COUNT(*) 
-- FROM dbo.ProductColumnstore 
-- GROUP BY CategoryID;
-- → Very Fast: ใช้ Batch Mode Execution

-- Query 4: Scan Query (เหมาะกับ Columnstore Clustered)
-- SELECT COUNT(*) FROM dbo.ProductColumnstore WHERE CategoryID = 5;
-- → Very Fast: Column-based Scan

GO

-- =============================================
-- สรุป
-- =============================================

-- ✅ สำเร็จ! สร้างโครงสร้างตารางทั้ง 3 แบบเสร็จสมบูรณ์
-- 
-- ตารางที่สร้าง:
-- 1. dbo.ProductHeap - HEAP Table (ไม่มี Clustered Index)
-- 2. dbo.ProductRowstore - Rowstore Clustered Index
-- 3. dbo.ProductColumnstore - Clustered Columnstore Index
--
-- การใช้งาน:
-- - HEAP: ❌ ไม่แนะนำ (ยกเว้น Staging/Temporary)
-- - Rowstore Clustered: ✅ Default Choice สำหรับ OLTP
-- - Columnstore Clustered: ✅ สำหรับ Analytics/Data Warehouse
--
GO


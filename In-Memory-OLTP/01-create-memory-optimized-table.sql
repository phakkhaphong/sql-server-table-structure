-- =============================================
-- Script: 01-create-memory-optimized-table.sql
-- Description: สร้าง Memory-Optimized Table และ Indexes
-- Database: AdventureWorks2022
-- Server: SQL Server 2014 ขึ้นไป (Enterprise/Developer)
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- หมายเหตุ: In-Memory OLTP ต้องการ Enterprise Edition หรือ
--          Standard Edition 2016 SP1+ (Limited)
-- =============================================

USE AdventureWorks2022;
GO

-- =============================================
-- ขั้นตอนที่ 1: ตรวจสอบ In-Memory OLTP
-- =============================================

-- === ตรวจสอบ In-Memory OLTP Configuration ===


-- ตรวจสอบว่า In-Memory OLTP เปิดใช้งานหรือไม่
SELECT 
    name AS FeatureName,
    value AS FeatureStatus,
    value_in_use AS IsEnabled
FROM sys.configurations
WHERE name LIKE '%in-memory%' OR name = 'contained database authentication';
GO

-- ตรวจสอบ Memory-Optimized Filegroup
SELECT 
    name AS FilegroupName,
    type_desc AS FilegroupType,
    is_default AS IsDefault,
    is_read_only AS IsReadOnly
FROM sys.filegroups
WHERE type = 'FX';  -- MEMORY_OPTIMIZED_DATA
GO

-- =============================================
-- ขั้นตอนที่ 2: สร้าง In-Memory Filegroup
-- =============================================


-- === ขั้นตอนที่ 2: สร้าง In-Memory Filegroup ===


-- ตรวจสอบว่ามี In-Memory Filegroup อยู่แล้วหรือไม่
IF NOT EXISTS (
    SELECT 1 FROM sys.filegroups 
    WHERE type = 'FX' AND name = 'InMemory_Data'
)
BEGIN
    -- เพิ่ม Filegroup สำหรับ In-Memory OLTP
    ALTER DATABASE AdventureWorks2022 
    ADD FILEGROUP InMemory_Data 
    CONTAINS MEMORY_OPTIMIZED_DATA;
    
    -- สร้าง In-Memory Filegroup: InMemory_Data
    
    -- เพิ่ม Container/Folder สำหรับ In-Memory Data
    ALTER DATABASE AdventureWorks2022 
    ADD FILE (
        NAME = 'InMemory_Data_File',
        FILENAME = 'C:\Data\AdventureWorks2022_InMemory.ndf'
    )
    TO FILEGROUP InMemory_Data;
    
    -- เพิ่ม In-Memory File Container
END
ELSE
BEGIN
    -- In-Memory Filegroup มีอยู่แล้ว
END
GO

-- =============================================
-- ขั้นตอนที่ 3: ลบตารางเก่า (ถ้ามี)
-- =============================================


-- === ขั้นตอนที่ 3: ลบตารางเก่า ===


IF OBJECT_ID('dbo.ShoppingCart_Memory', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.ShoppingCart_Memory;
    -- ลบตาราง dbo.ShoppingCart_Memory ที่มีอยู่เดิม
END
GO

-- =============================================
-- ขั้นตอนที่ 4: สร้าง Memory-Optimized Table
-- =============================================


-- === ขั้นตอนที่ 4: สร้าง Memory-Optimized Table ===


-- สร้าง Memory-Optimized Table
-- ตัวอย่าง: Shopping Cart Table สำหรับ High-Frequency Access
CREATE TABLE dbo.ShoppingCart_Memory
(
    ShoppingCartID BIGINT IDENTITY(1,1) NOT NULL,
    SessionID NVARCHAR(36) NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice MONEY NOT NULL,
    TotalAmount AS (Quantity * UnitPrice),
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    -- Primary Key with Hash Index
    CONSTRAINT PK_ShoppingCart_Memory 
        PRIMARY KEY NONCLUSTERED HASH (ShoppingCartID) 
        WITH (BUCKET_COUNT = 1000000),
    
    -- Hash Index สำหรับ Session Lookup
    INDEX IX_ShoppingCart_SessionID 
        NONCLUSTERED HASH (SessionID) 
        WITH (BUCKET_COUNT = 100000),
    
    -- Range Index สำหรับ ProductID
    INDEX IX_ShoppingCart_ProductID 
        NONCLUSTERED (ProductID),
    
    -- Range Index สำหรับ CreatedDate
    INDEX IX_ShoppingCart_CreatedDate 
        NONCLUSTERED (CreatedDate)
)
WITH (
    MEMORY_OPTIMIZED = ON,           -- เปิดใช้ Memory-Optimized
    DURABILITY = SCHEMA_AND_DATA     -- Full Durability
);
GO

-- สร้าง Memory-Optimized Table เสร็จสมบูรณ์

-- คุณสมบัติ:
--   - Hash Indexes: ShoppingCartID, SessionID
--   - Range Indexes: ProductID, CreatedDate
--   - Durability: SCHEMA_AND_DATA
GO

-- =============================================
-- ขั้นตอนที่ 5: Insert ข้อมูลทดสอบ
-- =============================================


-- === ขั้นตอนที่ 5: Insert ข้อมูลทดสอบ ===


-- Insert ข้อมูลตัวอย่าง
DECLARE @i INT = 1;
DECLARE @SessionID NVARCHAR(36) = NEWID();

WHILE @i <= 1000
BEGIN
    INSERT INTO dbo.ShoppingCart_Memory (
        SessionID, ProductID, Quantity, UnitPrice, CreatedDate
    )
    VALUES (
        @SessionID,
        ABS(CHECKSUM(NEWID())) % 100 + 1,  -- ProductID: 1-100
        ABS(CHECKSUM(NEWID())) % 10 + 1,   -- Quantity: 1-10
        10.00 + (ABS(CHECKSUM(NEWID())) % 990),  -- UnitPrice
        DATEADD(SECOND, @i, SYSDATETIME())
    );
    
    SET @i = @i + 1;
END
GO

-- Insert 1,000 rows เสร็จสมบูรณ์
GO

-- =============================================
-- ขั้นตอนที่ 6: ทดสอบ Query Performance
-- =============================================


-- === ขั้นตอนที่ 6: ทดสอบ Query Performance ===


-- Query 1: Hash Index Point Lookup (เร็วที่สุด)
-- Query 1: Hash Index Point Lookup
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

DECLARE @TestCartID BIGINT = 500;
SELECT * 
FROM dbo.ShoppingCart_Memory
WHERE ShoppingCartID = @TestCartID;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Query 2: Hash Index Lookup by SessionID

-- Query 2: Hash Index Lookup by SessionID
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT TOP 10 *
FROM dbo.ShoppingCart_Memory
WHERE SessionID = (SELECT TOP 1 SessionID FROM dbo.ShoppingCart_Memory);
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Query 3: Range Index Scan

-- Query 3: Range Index Scan
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT 
    ProductID,
    SUM(Quantity) AS TotalQuantity,
    SUM(TotalAmount) AS TotalSales
FROM dbo.ShoppingCart_Memory
WHERE ProductID BETWEEN 1 AND 50
GROUP BY ProductID
ORDER BY TotalSales DESC;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- =============================================
-- ขั้นตอนที่ 7: ตรวจสอบ Memory Usage
-- =============================================


-- === ขั้นตอนที่ 7: ตรวจสอบ Memory Usage ===


-- ตรวจสอบ Memory-Optimized Tables
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    memory_allocated_for_indexes_kb / 1024.0 AS IndexMemoryMB,
    memory_allocated_for_table_kb / 1024.0 AS TableMemoryMB,
    memory_used_by_indexes_kb / 1024.0 AS IndexMemoryUsedMB,
    memory_used_by_table_kb / 1024.0 AS TableMemoryUsedMB
FROM sys.dm_db_xtp_table_memory_stats
WHERE OBJECT_ID = OBJECT_ID('dbo.ShoppingCart_Memory');
GO

-- ตรวจสอบ Indexes
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS IndexName,
    type_desc AS IndexType,
    total_bucket_count AS BucketCount,
    empty_bucket_count AS EmptyBuckets,
    avg_chain_length AS AvgChainLength,
    max_chain_length AS MaxChainLength
FROM sys.dm_db_xtp_hash_index_stats
WHERE OBJECT_ID = OBJECT_ID('dbo.ShoppingCart_Memory');
GO

-- =============================================
-- Best Practices Summary
-- =============================================



-- === Best Practices Summary ===

-- 1. Index Selection:
--    - Hash Indexes: Point Lookups (WHERE Key = value)
--    - Range Indexes: Range Queries, Sorting
--    - Bucket Count: 1-2x Expected Row Count

-- 2. Durability Options:
--    - SCHEMA_AND_DATA: Production (Recommended)
--    - SCHEMA_ONLY: Staging/Temp Tables

-- 3. Memory Management:
--    - Monitor Memory Usage
--    - Set max_server_memory appropriately
--    - Plan for Growth

-- 4. Use Cases:
--    ✅ Session Data
--    ✅ Shopping Carts
--    ✅ Real-time Gaming
--    ✅ High-Frequency Lookups
--    ❌ Large Data Warehouses
GO


-- สำเร็จ! สร้าง Memory-Optimized Table เสร็จสมบูรณ์
GO


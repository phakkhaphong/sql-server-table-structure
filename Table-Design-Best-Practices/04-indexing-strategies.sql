-- =============================================
-- Script: 04-indexing-strategies.sql
-- Description: Indexing Strategies
-- Database: AdventureWorks2022
-- Server: SQL Server
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Indexing Strategies ===

GO

-- =============================================
-- ส่วนที่ 1: Clustered Index
-- =============================================

-- === ส่วนที่ 1: Clustered Index ===

-- Best Practices:
-- ✅ ทุกตารางควรมี 1 Clustered Index
-- ✅ นิยมใช้ Primary Key เป็น Clustered (Default)
-- ⚠️  ระวัง Page Split! เลือก Column ที่: Narrow, Unique, **Sequential**
-- ✅ RECOMMENDED: ใช้ Surrogate Key (INT IDENTITY(1,1)) สำหรับ Clustered Primary Key
--    เหตุผลสำคัญ:
--    - IDENTITY(1,1) = เพิ่มขึ้นทางบวกเรื่อยๆ (Sequential)
--    - Insert ข้อมูลอยู่ท้ายตารางเสมอ → ไม่เกิด Page Split
--    - Performance ดีมาก


-- ✅ BEST PRACTICE: Surrogate Key เป็น Clustered Primary Key
CREATE TABLE dbo.ProductExample (
    ProductID INT IDENTITY(1,1),               -- ✅ Increment = 1 (เพิ่มขึ้นทางบวก)
    ProductCode VARCHAR(20) UNIQUE,           -- Business Key เป็น Unique แทน
    ProductName NVARCHAR(100),
    CategoryID INT,
    Price DECIMAL(10,2),
    CONSTRAINT PK_Product PRIMARY KEY CLUSTERED (ProductID)  -- Sequential Insert = No Page Split
);
GO

-- ⚠️ EXAMPLE: ถ้าใช้ Business Key เป็น Clustered Primary Key (NOT RECOMMENDED)
-- CREATE TABLE dbo.ProductExample_Bad (
--     ProductCode VARCHAR(20) PRIMARY KEY CLUSTERED,  -- Business Key
--     ProductName NVARCHAR(100),
--     ...
-- );
-- ผลกระทบ: Insert ProductCode ไม่เรียงตามตัวอักษร → Page Split → Performance ลดลง
-- ทางแก้: ใช้ Surrogate Key และทำ ProductCode เป็น UNIQUE INDEX แทน
GO

-- =============================================
-- ส่วนที่ 2: Nonclustered Index
-- =============================================


-- === ส่วนที่ 2: Nonclustered Index ===

-- Best Practices:
-- ✅ สร้างสำหรับ Query Patterns
-- ✅ ใช้ Selective Columns มาก่อน


-- Index สำหรับ Filtering
CREATE INDEX IX_Product_CategoryID ON dbo.ProductExample(CategoryID);
GO

-- Index สำหรับ Lookup
CREATE INDEX IX_Product_ProductCode ON dbo.ProductExample(ProductCode);
GO

-- =============================================
-- ส่วนที่ 3: Covering Index
-- =============================================


-- === ส่วนที่ 3: Covering Index ===

-- Best Practices:
-- ✅ ใช้ INCLUDE สำหรับ Covering
-- ✅ Cover ทุก Columns ที่ Query ต้องใช้


-- Covering Index
CREATE INDEX IX_Product_CategoryID_Covering 
ON dbo.ProductExample(CategoryID)
INCLUDE (ProductName, Price);  -- Cover columns in SELECT
GO

-- =============================================
-- ส่วนที่ 4: Composite Index
-- =============================================


-- === ส่วนที่ 4: Composite Index ===

-- Best Practices:
-- ✅ Order: Most selective first
-- ✅ Left-most prefix matters


CREATE TABLE dbo.SalesExample (
    SalesOrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATETIME2 NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT,
    TotalAmount MONEY
);
GO

-- Composite Index
CREATE INDEX IX_Sales_Date_Customer 
ON dbo.SalesExample(OrderDate, CustomerID)
INCLUDE (ProductID, TotalAmount);  -- Composite + Covering
GO

-- =============================================
-- Best Practices Summary
-- =============================================



-- === Best Practices Summary ===

-- 1. Clustered Index:
--    - 1 per table
--    - ✅ Usually on Primary Key (Default)
--    - Choose wisely: Narrow, Unique, **Sequential**
--    - ✅ BEST: Surrogate Key (INT IDENTITY(1,1))
--      * ต้องเพิ่มขึ้นทางบวก (Increment > 0)
--      * Sequential Insert → No Page Split
--      * Better Performance
--    - ❌ AVOID: Negative Increment
--      * IDENTITY(1,-1) → ลดค่า → Insert หน้าแรก → Page Split
--    - ⚠️  AVOID: Non-Sequential Business Keys
--      * Random Insert → Page Split → Slow Performance
--      * Example: Email, Name, UUID (ไม่เรียงลำดับ)

-- 2. Nonclustered Index:
--    - สร้างตาม Query Patterns
--    - Most selective first
--    - Monitor การใช้งาน

-- 3. Covering Index:
--    - ใช้ INCLUDE clause
--    - Avoid Key Lookups
--    - Balance Storage vs Performance

-- 4. Monitoring:
--    - sys.dm_db_index_usage_stats
--    - Missing Index DMVs
--    - Fragmentation Analysis
GO


-- สำเร็จ! จบ Indexing Strategies
GO


-- =============================================
-- Script: 01-create-indexed-view.sql
-- Description: สร้าง Indexed View พื้นฐาน
-- Database: AdventureWorks2022
-- Server: SQL Server 2000 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === สร้าง Indexed View ===

GO

-- =============================================
-- ขั้นตอนที่ 1: Setup SET Options
-- =============================================

-- === ขั้นตอนที่ 1: Setup SET Options ===


-- SET Options ที่จำเป็นสำหรับ Indexed Views
SET ANSI_NULLS ON;
GO
SET ANSI_PADDING ON;
GO
SET ANSI_WARNINGS ON;
GO
SET ARITHABORT ON;
GO
SET CONCAT_NULL_YIELDS_NULL ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- SET Options configured successfully
GO

-- =============================================
-- ขั้นตอนที่ 2: ลบ View เก่า (ถ้ามี)
-- =============================================


-- === ขั้นตอนที่ 2: ลบ View เก่า ===


IF OBJECT_ID('dbo.vwSalesSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vwSalesSummary;
GO

-- View deleted (if existed)
GO

-- =============================================
-- ขั้นตอนที่ 3: สร้าง View พร้อม SCHEMABINDING
-- =============================================


-- === ขั้นตอนที่ 3: สร้าง View ===


-- สร้าง View พื้นฐาน
CREATE VIEW dbo.vwSalesSummary
WITH SCHEMABINDING
AS
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.CustomerID,
    soh.SalesPersonID,
    soh.TerritoryID,
    p.ProductID,
    pc.Name AS ProductCategory,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalLineAmount,
    COUNT_BIG(*) AS SalesCount  -- COUNT_BIG required for indexed views
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.CustomerID,
    soh.SalesPersonID,
    soh.TerritoryID,
    p.ProductID,
    pc.Name;
GO

-- View created: dbo.vwSalesSummary
GO

-- =============================================
-- ขั้นตอนที่ 4: เพิ่ม Clustered Index
-- =============================================


-- === ขั้นตอนที่ 4: เพิ่ม Clustered Index ===


-- สร้าง Clustered Index บน View
CREATE UNIQUE CLUSTERED INDEX IXC_vwSalesSummary
ON dbo.vwSalesSummary(SalesOrderID, ProductID);
GO

-- Clustered Index created successfully
GO

-- =============================================
-- ขั้นตอนที่ 5: ทดสอบ View
-- =============================================


-- === ขั้นตอนที่ 5: ทดสอบ View ===


-- Query View
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT TOP 10
    OrderDate,
    ProductCategory,
    SUM(TotalQuantity) AS TotalQty,
    SUM(TotalLineAmount) AS TotalAmount
FROM dbo.vwSalesSummary
WHERE OrderDate >= '2012-01-01'
GROUP BY OrderDate, ProductCategory
ORDER BY TotalAmount DESC;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- =============================================
-- ขั้นตอนที่ 6: ตรวจสอบ Indexed View State
-- =============================================


-- === ขั้นตอนที่ 6: ตรวจสอบ View State ===


-- ตรวจสอบว่า View มี Index
SELECT 
    OBJECT_NAME(object_id) AS ViewName,
    name AS IndexName,
    type_desc AS IndexType,
    is_unique AS IsUnique,
    is_primary_key AS IsPrimaryKey
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.vwSalesSummary');
GO

-- ตรวจสอบ Space Usage
SELECT 
    OBJECT_NAME(object_id) AS ViewName,
    SUM(page_count) AS Pages,
    SUM(page_count) * 8.0 / 1024 AS SizeMB
FROM sys.dm_db_index_physical_stats(
    DB_ID(),
    OBJECT_ID('dbo.vwSalesSummary'),
    NULL,
    NULL,
    'LIMITED'
)
WHERE index_id IN (0,1)
GROUP BY object_id;
GO

-- =============================================
-- Best Practices Summary
-- =============================================



-- === Best Practices ===

-- 1. Requirements:
--    ✅ WITH SCHEMABINDING
--    ✅ SET Options ต้องถูกต้อง
--    ✅ ใช้ COUNT_BIG() แทน COUNT()
--    ✅ ใช้ Clustered Index

-- 2. Performance:
--    - Query อาจได้ประโยชน์หรือไม่ก็ได้
--    - ขึ้นอยู่กับ Query Rewrite
--    - Monitor Execution Plans

-- 3. Maintenance:
--    - Index จะถูก Maintain อัตโนมัติ
--    - DML อาจช้าลง
--    - Rebuild Index เมื่อจำเป็น
GO


-- สำเร็จ! สร้าง Indexed View เสร็จสมบูรณ์
GO


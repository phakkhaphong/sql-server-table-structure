-- =============================================
-- Script: 02-aggregate-indexed-view.sql
-- Description: สร้าง Indexed View สำหรับ Aggregation
-- Database: AdventureWorks2022
-- Server: SQL Server 2000 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Aggregate Indexed View ===

GO

-- =============================================
-- Setup SET Options
-- =============================================

SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =============================================
-- ขั้นตอนที่ 1: สร้าง Aggregated View
-- =============================================

-- === ขั้นตอนที่ 1: สร้าง Aggregated View ===


IF OBJECT_ID('dbo.vwMonthlySales', 'V') IS NOT NULL
    DROP VIEW dbo.vwMonthlySales;
GO

CREATE VIEW dbo.vwMonthlySales
WITH SCHEMABINDING
AS
SELECT 
    YEAR(soh.OrderDate) AS OrderYear,
    MONTH(soh.OrderDate) AS OrderMonth,
    soh.TerritoryID,
    pc.Name AS ProductCategory,
    COUNT_BIG(*) AS SalesCount,  -- ใช้ COUNT_BIG จำเป็น
    SUM(CAST(sod.OrderQty AS BIGINT)) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalSales,
    AVG(sod.LineTotal) AS AvgLineTotal
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE soh.OrderDate IS NOT NULL
GROUP BY 
    YEAR(soh.OrderDate),
    MONTH(soh.OrderDate),
    soh.TerritoryID,
    pc.Name;
GO

-- View created: dbo.vwMonthlySales
GO

-- =============================================
-- ขั้นตอนที่ 2: เพิ่ม Clustered Index
-- =============================================


-- === ขั้นตอนที่ 2: เพิ่ม Clustered Index ===


CREATE UNIQUE CLUSTERED INDEX IXC_vwMonthlySales
ON dbo.vwMonthlySales(OrderYear, OrderMonth, TerritoryID, ProductCategory);
GO

-- Clustered Index created
GO

-- =============================================
-- ขั้นตอนที่ 3: ทดสอบ View
-- =============================================


-- === ขั้นตอนที่ 3: ทดสอบ Aggregation ===


SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

-- Query 1: Summarize by Year
SELECT 
    OrderYear,
    SUM(TotalSales) AS TotalSales,
    SUM(TotalQuantity) AS TotalQuantity,
    SUM(SalesCount) AS TotalCount
FROM dbo.vwMonthlySales
GROUP BY OrderYear
ORDER BY OrderYear;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Query 2: Monthly Sales by Category

-- Query 2: Monthly Sales by Category
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT 
    ProductCategory,
    OrderYear,
    OrderMonth,
    TotalSales,
    TotalQuantity
FROM dbo.vwMonthlySales
WHERE OrderYear = 2013
ORDER BY ProductCategory, OrderMonth;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- =============================================
-- ขั้นตอนที่ 4: ตรวจสอบ Space Usage
-- =============================================


-- === ขั้นตอนที่ 4: ตรวจสอบ Space ===


SELECT 
    OBJECT_NAME(object_id) AS ViewName,
    SUM(page_count) AS Pages,
    SUM(page_count) * 8.0 / 1024 AS SizeMB,
    SUM(record_count) AS RecordCount
FROM sys.dm_db_index_physical_stats(
    DB_ID(),
    OBJECT_ID('dbo.vwMonthlySales'),
    NULL,
    NULL,
    'LIMITED'
)
WHERE index_id IN (0,1)
GROUP BY object_id;
GO


-- สำเร็จ! สร้าง Aggregate Indexed View เสร็จสมบูรณ์
GO


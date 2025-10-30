-- =============================================
-- Script: 02-create-nonclustered-columnstore.sql
-- Description: สร้าง Nonclustered Columnstore Index สำหรับ Rowstore Table
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- คำอธิบาย: NCCI เหมาะสำหรับ Hybrid OLTP + Analytics
-- =============================================

USE AdventureWorks2022;
GO

-- === สร้าง Nonclustered Columnstore Index ===
-- เหมาะสำหรับ: OLTP + Analytics Hybrid Workloads

GO

-- =============================================
-- ขั้นตอนที่ 1: ตรวจสอบตารางเดิม
-- =============================================

-- ขั้นตอนที่ 1: ตรวจสอบตาราง Sales.SalesOrderHeader


-- ตรวจสอบว่าเป็น Rowstore Table
SELECT 
    t.name AS TableName,
    i.type_desc AS IndexType,
    i.name AS IndexName
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.name = 'SalesOrderHeader'
  AND SCHEMA_NAME(t.schema_id) = 'Sales'
  AND i.type > 0  -- Exclude Heap
ORDER BY i.type, i.name;
GO

-- ดูจำนวนแถว
SELECT COUNT(*) AS TotalRows
FROM Sales.SalesOrderHeader;
GO

-- =============================================
-- ขั้นตอนที่ 2: สร้าง Nonclustered Columnstore Index
-- =============================================


-- ขั้นตอนที่ 2: สร้าง Nonclustered Columnstore Index


-- สร้าง NCCI สำหรับตาราง Rowstore
-- NCCI เหมาะสำหรับ Analytics Queries โดยไม่กระทบ OLTP
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesOrderHeader_Analytics
ON Sales.SalesOrderHeader (
    SalesOrderID,
    OrderDate,
    DueDate,
    ShipDate,
    CustomerID,
    SalesPersonID,
    TerritoryID,
    SubTotal,
    TaxAmt,
    Freight,
    TotalDue,
    Status
)
INCLUDE (OnlineOrderFlag, SalesOrderNumber);
GO

-- สร้าง NCCI เสร็จสมบูรณ์: NCCI_SalesOrderHeader_Analytics

GO

-- =============================================
-- ขั้นตอนที่ 3: ตรวจสอบ Index State
-- =============================================

-- ขั้นตอนที่ 3: ตรวจสอบ NCCI State


-- ตรวจสอบ Index สร้างแล้ว
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS IndexName,
    type_desc AS IndexType,
    is_disabled AS IsDisabled,
    is_primary_key AS IsPrimaryKey
FROM sys.indexes
WHERE object_id = OBJECT_ID('Sales.SalesOrderHeader')
  AND type_desc LIKE '%COLUMNSTORE%';
GO

-- ตรวจสอบ Row Groups
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    partition_number AS PartitionNum,
    row_group_id AS RowGroupID,
    state_description AS State,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows,
    size_in_bytes / 1024.0 AS SizeKB
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('Sales.SalesOrderHeader')
  AND index_id > 1  -- Nonclustered
ORDER BY row_group_id;
GO

-- =============================================
-- ขั้นตอนที่ 4: ทดสอบ Query Performance
-- =============================================


-- ขั้นตอนที่ 4: ทดสอบ Query Performance


-- Query 1: Aggregation แบบ Simple
-- Query 1: Sales by Year
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT 
    YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSales,
    AVG(TotalDue) AS AvgOrderValue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Query 2: JOIN with Customer

-- Query 2: Top Customers
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT TOP 10
    soh.CustomerID,
    c.AccountNumber,
    COUNT(*) AS OrderCount,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
WHERE soh.OrderDate >= '2012-01-01'
GROUP BY soh.CustomerID, c.AccountNumber
ORDER BY TotalSales DESC;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Query 3: Complex Analysis

-- Query 3: Territory Analysis
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT 
    t.Name AS TerritoryName,
    t.CountryRegionCode,
    COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
    COUNT(DISTINCT soh.CustomerID) AS CustomerCount,
    SUM(soh.SubTotal) AS TotalSubTotal,
    SUM(soh.TaxAmt) AS TotalTax,
    SUM(soh.Freight) AS TotalFreight,
    SUM(soh.TotalDue) AS TotalSales,
    AVG(soh.TotalDue) AS AvgOrderValue
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory t ON soh.TerritoryID = t.TerritoryID
WHERE soh.OrderDate >= '2012-01-01'
GROUP BY t.Name, t.CountryRegionCode
ORDER BY TotalSales DESC;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- =============================================
-- ขั้นตอนที่ 5: เปรียบเทียบกับ B-tree Index
-- =============================================


-- ขั้นตอนที่ 5: เปรียบเทียบ Index Usage


-- ดู Execution Plan และ Index Usage
-- Query ที่เหมาะกับ NCCI
SET STATISTICS XML ON;
GO

SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2012-01-01'
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;
GO

SET STATISTICS XML OFF;
GO

-- =============================================
-- ขั้นตอนที่ 6: รายละเอียด Index Information
-- =============================================


-- ขั้นตอนที่ 6: รายละเอียด Columnstore Index


-- ดูรายละเอียด Columnstore Index
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_disabled AS IsDisabled,
    ius.user_seeks AS UserSeeks,
    ius.user_scans AS UserScans,
    ius.user_lookups AS UserLookups,
    ius.user_updates AS UserUpdates,
    ius.last_user_seek AS LastSeek,
    ius.last_user_scan AS LastScan
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius 
    ON i.object_id = ius.object_id 
    AND i.index_id = ius.index_id
    AND ius.database_id = DB_ID()
WHERE i.object_id = OBJECT_ID('Sales.SalesOrderHeader')
  AND i.type_desc LIKE '%COLUMNSTORE%';
GO

-- Memory Usage
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    SUM(reserved_page_count) * 8 / 1024.0 AS ReservedMB,
    SUM(used_page_count) * 8 / 1024.0 AS UsedMB
FROM sys.dm_db_partition_stats
WHERE object_id = OBJECT_ID('Sales.SalesOrderHeader')
  AND index_id > 1
GROUP BY object_id, index_id;
GO

-- =============================================
-- Best Practices และ Tips
-- =============================================



-- === Best Practices สำหรับ Nonclustered Columnstore Index ===

-- 1. เหมาะสำหรับ:
--    ✅ OLTP + Analytics Hybrid
--    ✅ Reporting Queries
--    ✅ Ad-hoc Analysis
--    ✅ Aggregations และ GROUP BY

-- 2. ไม่เหมาะสำหรับ:
--    ❌ Single-row Lookups
--    ❌ OLTP เท่านั้น (ไม่ต้อง Analytics)
--    ❌ Small Tables (< 1M rows)

-- 3. การดูแลรักษา:
--    - Reorganize NCCI เป็นประจำ
--    - Monitor Delta Store
--    - Rebuild เมื่อ Delta Store ใหญ่เกินไป

-- 4. Performance Considerations:
--    - NCCI ไม่กระทบ DML เท่า CCI
--    - Query Optimizer เลือกใช้ Index อัตโนมัติ
--    - ใช้ Batch Mode Execution
GO


-- สำเร็จ! สร้าง Nonclustered Columnstore Index เสร็จสมบูรณ์
GO


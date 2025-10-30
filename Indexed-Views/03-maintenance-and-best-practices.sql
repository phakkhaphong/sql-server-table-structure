-- =============================================
-- Script: 03-maintenance-and-best-practices.sql
-- Description: การดูแลรักษาและ Best Practices
-- Database: AdventureWorks2022
-- Server: SQL Server 2000 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Indexed View Maintenance & Best Practices ===

GO

-- =============================================
-- ส่วนที่ 1: ตรวจสอบ View และ Indexes
-- =============================================

-- === ส่วนที่ 1: ตรวจสอบ Indexed Views ===


SELECT 
    SCHEMA_NAME(v.schema_id) AS SchemaName,
    v.name AS ViewName,
    v.type_desc AS ViewType,
    v.is_indexable AS IsIndexable,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.views v
LEFT JOIN sys.indexes i ON v.object_id = i.object_id
WHERE v.is_indexable = 1
ORDER BY SchemaName, ViewName;
GO

-- =============================================
-- ส่วนที่ 2: การ Rebuild Index
-- =============================================


-- === ส่วนที่ 2: การ Rebuild Index ===


-- Rebuild Index on Indexed View
-- ตัวอย่าง: Rebuild Index
GO

-- ALTER INDEX ALL ON dbo.vwMonthlySales REBUILD;

-- คำสั่ง:
-- ALTER INDEX ALL ON dbo.vwMonthlySales REBUILD;
GO

-- =============================================
-- ส่วนที่ 3: ตรวจสอบ Fragmentation
-- =============================================


-- === ส่วนที่ 3: ตรวจสอบ Fragmentation ===


SELECT 
    OBJECT_NAME(object_id) AS ViewName,
    index_id,
    avg_fragmentation_in_percent AS FragmentationPercent,
    page_count AS PageCount,
    CASE 
        WHEN avg_fragmentation_in_percent > 30 THEN 'REBUILD'
        WHEN avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
        ELSE 'OK'
    END AS Recommendation
FROM sys.dm_db_index_physical_stats(
    DB_ID(),
    NULL,
    NULL,
    NULL,
    'LIMITED'
)
WHERE object_id IN (
    OBJECT_ID('dbo.vwMonthlySales'),
    OBJECT_ID('dbo.vwSalesSummary')
)
AND page_count > 10;
GO

-- =============================================
-- ส่วนที่ 4: Best Practices
-- =============================================



-- === Best Practices Summary ===

-- 1. Requirements:
--    ✅ SCHEMABINDING
--    ✅ SET Options ถูกต้อง
--    ✅ COUNT_BIG() สำหรับ Aggregate
--    ✅ Deterministic Functions Only

-- 2. Performance:
--    - Query Rewrite ขึ้นอยู่กับ Query Optimizer
--    - Enterprise Edition: Auto Rewrite
--    - Standard Edition: Manual Reference
--    - Monitor Execution Plans

-- 3. Maintenance:
--    - Rebuild Index เป็นประจำ
--    - Monitor Fragmentation
--    - DML อาจช้าลง

-- 4. เมื่อเลือกใช้:
--    ✅ Complex Joins ที่ทำบ่อย
--    ✅ Aggregation ที่ทำบ่อย
--    ✅ Read-Heavy Workloads
--    ❌ OLTP (DML มาก)
--    ❌ Queries ไม่ได้ Reference View
GO


-- สำเร็จ! จบการสาธิต Maintenance
GO


-- =============================================
-- Script: 04-manage-partitions.sql
-- Description: การจัดการ Partitions (เพิ่ม/ลบ/รวม)
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- Prerequisite: ต้องรัน 01 และ 02 ก่อน
-- =============================================

USE AdventureWorks2022;
GO

-- ตรวจสอบสถานะ Partition
SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    COUNT(*) AS RowCount,
    MIN(OrderDate) AS MinDate,
    MAX(OrderDate) AS MaxDate
FROM dbo.SalesOrderHeaderPartitioned
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate)
ORDER BY PartitionNumber;
GO

-- =============================================
-- การเพิ่ม Partition ใหม่
-- =============================================

-- === การเพิ่ม Partition ใหม่ ===

GO

-- ตรวจสอบ Range Right/Left
SELECT 
    pf.name AS PartitionFunction,
    pf.boundary_value_on_right AS IsRightBound
FROM sys.partition_functions pf
WHERE pf.name = 'PF_SalesOrderByYear';
GO

-- ขั้นตอนที่ 1: เพิ่ม Filegroup สำหรับปี 2026
GO

IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'SalesFG2026')
BEGIN
    ALTER DATABASE AdventureWorks2022 ADD FILEGROUP SalesFG2026;
    -- สร้าง Filegroup: SalesFG2026
END
GO


-- ขั้นตอนที่ 2: เพิ่ม Boundary Value
GO

ALTER PARTITION SCHEME PS_SalesOrderByYear
NEXT USED SalesFG2026;
GO

ALTER PARTITION FUNCTION PF_SalesOrderByYear()
SPLIT RANGE ('2026-01-01');
GO

-- เพิ่ม Partition ปี 2026 เสร็จสมบูรณ์
GO

-- ตรวจสอบ Partitions ใหม่
SELECT 
    p.partition_number AS PartitionNumber,
    p.rows AS RowCount,
    prv.value AS BoundaryValue
FROM sys.partition_functions pf
JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id
JOIN sys.partitions p ON pf.function_id = OBJECTPROPERTYEX(p.object_id, 'PARTITION FUNCTION ID')
WHERE pf.name = 'PF_SalesOrderByYear'
  AND OBJECT_NAME(p.object_id) = 'SalesOrderHeaderPartitioned'
  AND p.index_id IN (0,1)
ORDER BY prv.boundary_id;
GO

-- =============================================
-- การรวม Partitions (Merge)
-- =============================================



-- === การรวม Partitions ===

GO

-- ขั้นตอนที่ 1: รวม Partitions เก่าเข้าด้วยกัน
-- ตัวอย่าง: รวม Partition 2020 และ 2021 เข้าด้วยกัน
GO

-- ตรวจสอบข้อมูลก่อน Merge
SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    COUNT(*) AS RowCount
FROM dbo.SalesOrderHeaderPartitioned
WHERE OrderDate < '2022-01-01'
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate)
ORDER BY PartitionNumber;
GO

-- Merge Partitions: ลบ boundary '2021-01-01'

-- กำลัง Merge: ลบ boundary 2021-01-01
GO

ALTER PARTITION FUNCTION PF_SalesOrderByYear()
MERGE RANGE ('2021-01-01');
GO

-- Merge เสร็จสมบูรณ์
GO

-- ตรวจสอบผลลัพธ์
SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    COUNT(*) AS RowCount
FROM dbo.SalesOrderHeaderPartitioned
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate)
ORDER BY PartitionNumber;
GO

-- =============================================
-- การจัดการ Sliding Window Pattern
-- =============================================



-- === Sliding Window Pattern สำหรับ Time-Series Data ===

-- แนวคิด:
-- [Archive] ← [Old] ← [Current] → [Future]

GO

-- ตัวอย่างการทำ Sliding Window
-- ขั้นตอนที่ 1: เพิ่ม Partition สำหรับ Future
GO

-- เพิ่ม Filegroup
IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'SalesFG2027')
BEGIN
    ALTER DATABASE AdventureWorks2022 ADD FILEGROUP SalesFG2027;
    -- สร้าง Filegroup: SalesFG2027
END
GO

-- เพิ่ม Boundary
ALTER PARTITION SCHEME PS_SalesOrderByYear
NEXT USED SalesFG2027;
GO

ALTER PARTITION FUNCTION PF_SalesOrderByYear()
SPLIT RANGE ('2027-01-01');
GO

-- เพิ่ม Partition 2027 เสร็จสมบูรณ์
GO


-- ขั้นตอนที่ 2: Archive ข้อมูลเก่า (Simulation)
-- (ใน Production จะใช้ SWITCH เพื่อย้ายข้อมูลไปตาราง Archive)
GO

-- สร้างตาราง Archive
IF OBJECT_ID('dbo.SalesOrderHeaderArchive', 'U') IS NOT NULL
    DROP TABLE dbo.SalesOrderHeaderArchive;
GO

-- Copy structure
SELECT TOP 0 * INTO dbo.SalesOrderHeaderArchive
FROM dbo.SalesOrderHeaderPartitioned;
GO

-- สร้างตาราง Archive แล้ว
-- (ใน Production จะใช้ ALTER TABLE ... SWITCH)
GO


-- ขั้นตอนที่ 3: ลบ Partition เก่าสุด
-- (Simulation - ใน Production จะ Merge หลัง Archive)
GO

-- ตรวจสอบ Boundary เดิม
SELECT 
    prv.boundary_id,
    prv.value AS BoundaryValue
FROM sys.partition_functions pf
JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id
WHERE pf.name = 'PF_SalesOrderByYear'
ORDER BY prv.boundary_id;
GO


-- === หมายเหตุสำคัญ ===

-- Sliding Window Pattern ที่ถูกต้อง:
--   1. SWITCH Partition เก่าออกไป Archive
--   2. Merge Partition ที่ว่างออก
--   3. Split Partition เพื่อเพิ่ม Future
--   4. ทำเป็นประจำ (Monthly/Quarterly)

-- ใน Production:
--   - ทดสอบใน Test Environment ก่อน
--   - ใช้ Maintenance Window
--   - Monitor Disk Space
--   - Backup ก่อน Merge/Split
GO

-- =============================================
-- แสดงรายละเอียด Partitions ทั้งหมด
-- =============================================



-- === สรุป Partitions ทั้งหมด ===
GO

SELECT 
    p.partition_number AS PartitionNum,
    prv.value AS BoundaryValue,
    CASE 
        WHEN p.partition_number = 1 THEN '< ' + CONVERT(VARCHAR, prv.value, 120)
        WHEN prv.value IS NULL THEN '>= ' + CONVERT(VARCHAR, (
            SELECT TOP 1 prv2.value 
            FROM sys.partition_range_values prv2 
            WHERE prv2.function_id = pf.function_id 
              AND prv2.boundary_id < p.partition_number - 1
            ORDER BY prv2.boundary_id DESC
        ), 120)
        ELSE '>= ' + CONVERT(VARCHAR, prv.value, 120)
    END AS ValueRange,
    p.rows AS RowCount
FROM sys.partition_functions pf
JOIN sys.partitions p ON pf.function_id = OBJECTPROPERTYEX(p.object_id, 'PARTITION FUNCTION ID')
LEFT JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id 
    AND p.partition_number = prv.boundary_id + 1
WHERE pf.name = 'PF_SalesOrderByYear'
  AND OBJECT_NAME(p.object_id) = 'SalesOrderHeaderPartitioned'
  AND p.index_id IN (0,1)
ORDER BY p.partition_number;
GO


-- สำเร็จ! จบการสาธิตการจัดการ Partitions
GO


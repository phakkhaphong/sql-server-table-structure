-- =============================================
-- Script: 01-create-partition-function-and-scheme.sql
-- Description: สร้าง Partition Function และ Partition Scheme สำหรับ Date-Based Partitioning
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- คำอธิบาย: สร้าง Partition Function และ Scheme สำหรับแบ่งข้อมูลตามปี
-- =============================================

USE AdventureWorks2022;
GO

-- =============================================
-- ขั้นตอนที่ 1: สร้าง Filegroups เพิ่มเติม
-- =============================================

-- ขั้นตอนที่ 1: ตรวจสอบและสร้าง Filegroups

-- ตรวจสอบ Filegroups ที่มีอยู่
SELECT 
    name AS FilegroupName,
    CASE WHEN is_default = 1 THEN 'Default' ELSE '' END AS IsDefault
FROM sys.filegroups
ORDER BY is_default DESC;
GO

-- ถ้าไม่มี Filegroups เพิ่มเติม ให้สร้าง
-- (ใน Production ควรสร้าง Physical Files แยกกันด้วย)

IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'SalesFG2020')
BEGIN
    ALTER DATABASE AdventureWorks2022 ADD FILEGROUP SalesFG2020;
    -- สร้าง Filegroup: SalesFG2020
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'SalesFG2021')
BEGIN
    ALTER DATABASE AdventureWorks2022 ADD FILEGROUP SalesFG2021;
    -- สร้าง Filegroup: SalesFG2021
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'SalesFG2022')
BEGIN
    ALTER DATABASE AdventureWorks2022 ADD FILEGROUP SalesFG2022;
    -- สร้าง Filegroup: SalesFG2022
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'SalesFG2023')
BEGIN
    ALTER DATABASE AdventureWorks2022 ADD FILEGROUP SalesFG2023;
    -- สร้าง Filegroup: SalesFG2023
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'SalesFG2024')
BEGIN
    ALTER DATABASE AdventureWorks2022 ADD FILEGROUP SalesFG2024;
    -- สร้าง Filegroup: SalesFG2024
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'SalesFG2025')
BEGIN
    ALTER DATABASE AdventureWorks2022 ADD FILEGROUP SalesFG2025;
    -- สร้าง Filegroup: SalesFG2025
END
GO


GO

-- =============================================
-- ขั้นตอนที่ 2: ลบ Partition Function และ Scheme เก่า (ถ้ามี)
-- =============================================

-- ขั้นตอนที่ 2: ตรวจสอบและลบ Partition Objects เก่า

-- ลบ Partition Scheme ก่อน (ถ้ามี)
IF EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = 'PS_SalesOrderByYear')
BEGIN
    DROP PARTITION SCHEME PS_SalesOrderByYear;
    -- ลบ Partition Scheme เก่า: PS_SalesOrderByYear
END
GO

-- ลบ Partition Function ก่อน (ถ้ามี)
IF EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = 'PF_SalesOrderByYear')
BEGIN
    DROP PARTITION FUNCTION PF_SalesOrderByYear;
    -- ลบ Partition Function เก่า: PF_SalesOrderByYear
END
GO


GO

-- =============================================
-- ขั้นตอนที่ 3: สร้าง Partition Function
-- =============================================

-- ขั้นตอนที่ 3: สร้าง Partition Function

-- Partition Function แบ่งตามปี
-- ใช้ RANGE RIGHT เพื่อให้ค่า boundary อยู่ใน Partition ถัดไป
-- เช่น 2020-01-01 จะไปอยู่ Partition ที่ >= 2020-01-01
CREATE PARTITION FUNCTION PF_SalesOrderByYear(DATETIME2)
AS RANGE RIGHT FOR VALUES (
    '2020-01-01',
    '2021-01-01',
    '2022-01-01',
    '2023-01-01',
    '2024-01-01',
    '2025-01-01'
);
GO

-- สร้าง Partition Function: PF_SalesOrderByYear
-- Boundaries: 2020, 2021, 2022, 2023, 2024, 2025
GO

-- ตรวจสอบ Partition Function
SELECT 
    pf.name AS PartitionFunction,
    pf.fanout AS PartitionCount,
    pf.boundary_value_on_right AS IsRightBound
FROM sys.partition_functions pf
WHERE pf.name = 'PF_SalesOrderByYear';
GO


GO

-- =============================================
-- ขั้นตอนที่ 4: สร้าง Partition Scheme
-- =============================================

-- ขั้นตอนที่ 4: สร้าง Partition Scheme

-- Partition Scheme จับคู่ Partitions กับ Filegroups
CREATE PARTITION SCHEME PS_SalesOrderByYear
AS PARTITION PF_SalesOrderByYear
TO (
    SalesFG2020,    -- Partition 1: < 2020-01-01
    SalesFG2021,    -- Partition 2: >= 2020-01-01 AND < 2021-01-01
    SalesFG2022,    -- Partition 3: >= 2021-01-01 AND < 2022-01-01
    SalesFG2023,    -- Partition 4: >= 2022-01-01 AND < 2023-01-01
    SalesFG2024,    -- Partition 5: >= 2023-01-01 AND < 2024-01-01
    SalesFG2025,    -- Partition 6: >= 2024-01-01 AND < 2025-01-01
    [PRIMARY]       -- Partition 7: >= 2025-01-01 (Future)
);
GO

-- สร้าง Partition Scheme: PS_SalesOrderByYear
GO

-- ตรวจสอบ Partition Scheme
SELECT 
    ps.name AS PartitionScheme,
    ps.type_desc AS TypeDescription,
    ps.function_id AS FunctionID
FROM sys.partition_schemes ps
WHERE ps.name = 'PS_SalesOrderByYear';
GO


GO

-- =============================================
-- ขั้นตอนที่ 5: ทดสอบ Partition Function
-- =============================================

-- ขั้นตอนที่ 5: ทดสอบ Partition Function

-- ทดสอบว่า values ต่างๆ ไปอยู่ Partition ไหน
SELECT 
    $PARTITION.PF_SalesOrderByYear('2019-12-31') AS PartitionNumber,
    '2019-12-31' AS TestDate,
    'Partition 1 (< 2020)' AS ExpectedPartition;
GO

SELECT 
    $PARTITION.PF_SalesOrderByYear('2020-06-15') AS PartitionNumber,
    '2020-06-15' AS TestDate,
    'Partition 2 (2020)' AS ExpectedPartition;
GO

SELECT 
    $PARTITION.PF_SalesOrderByYear('2022-08-20') AS PartitionNumber,
    '2022-08-20' AS TestDate,
    'Partition 4 (2022)' AS ExpectedPartition;
GO

SELECT 
    $PARTITION.PF_SalesOrderByYear('2025-06-15') AS PartitionNumber,
    '2025-06-15' AS TestDate,
    'Partition 7 (>= 2025)' AS ExpectedPartition;
GO


-- สำเร็จ! สร้าง Partition Function และ Scheme เสร็จสมบูรณ์

-- สรุป:
-- - Partition Function: PF_SalesOrderByYear (แบ่งตามปี)
-- - Partition Scheme: PS_SalesOrderByYear (จับคู่กับ Filegroups)
-- - จำนวน Partitions: 7
GO


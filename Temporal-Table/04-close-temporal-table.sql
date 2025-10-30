-- =============================================
-- Script: 04-close-temporal-table.sql
-- Description: ปิดใช้งาน Temporal Table และลบ Temporal Features
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- คำเตือน: Script นี้จะปิดการใช้งาน Temporal Table
-- ข้อมูลใน History Table จะไม่สูญหาย แต่จะไม่มีการติดตามประวัติเพิ่มเติม
-- =============================================

USE AdventureWorks2022;
GO

-- ตรวจสอบว่าตารางเป็น Temporal Table หรือไม่
IF NOT EXISTS (
    SELECT 1 
    FROM sys.tables 
    WHERE name = 'CustomerHistory' 
      AND SCHEMA_NAME(schema_id) = 'dbo'
      AND temporal_type_desc = 'SYSTEM_VERSIONED_TEMPORAL_TABLE'
)
BEGIN
    -- ตาราง dbo.CustomerHistory ไม่ใช่ Temporal Table
    RETURN;
END
GO

-- เริ่มกระบวนการปิดใช้งาน Temporal Table
GO

-- ขั้นตอนที่ 1: ปิด SYSTEM_VERSIONING
-- ขั้นตอนที่ 1: ปิด SYSTEM_VERSIONING

ALTER TABLE dbo.CustomerHistory
SET (SYSTEM_VERSIONING = OFF);
GO

-- ปิด System Versioning เสร็จสมบูรณ์
-- History Table ยังคงอยู่และมีข้อมูลครบถ้วน
GO

-- ขั้นตอนที่ 2: ลบ PERIOD FOR SYSTEM_TIME
-- ขั้นตอนที่ 2: ลบ PERIOD FOR SYSTEM_TIME

ALTER TABLE dbo.CustomerHistory
DROP PERIOD FOR SYSTEM_TIME;
GO

-- ลบ PERIOD เสร็จสมบูรณ์
GO

-- ขั้นตอนที่ 3: ลบคอลัมน์ ValidFrom และ ValidTo
-- (ถ้าต้องการลบออกจากตาราง)
-- ขั้นตอนที่ 3: ลบคอลัมน์ ValidFrom และ ValidTo

-- ตรวจสอบว่าคอลัมน์มีอยู่หรือไม่
IF EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.CustomerHistory')
      AND name IN ('ValidFrom', 'ValidTo')
)
BEGIN
    ALTER TABLE dbo.CustomerHistory
    DROP COLUMN ValidFrom, ValidTo;
    
    -- ลบคอลัมน์ ValidFrom และ ValidTo เสร็จสมบูรณ์
END
ELSE
BEGIN
    -- ไม่พบคอลัมน์ ValidFrom หรือ ValidTo
END
GO

-- ขั้นตอนที่ 4: (ไม่บังคับ) ลบ History Table
-- ถ้าต้องการลบ History Table ที่สร้างไว้ ให้ uncomment บรรทัดด้านล่าง
/*
-- ขั้นตอนที่ 4: ลบ History Table

IF OBJECT_ID('dbo.CustomerHistoryArchive', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.CustomerHistoryArchive;
    -- ลบ History Table เสร็จสมบูรณ์
END
*/
GO

-- ตรวจสอบสถานะหลังปิดใช้งาน

-- สรุปผลการปิดใช้งาน Temporal Table:
-- =

SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    temporal_type_desc AS TemporalType
FROM sys.tables
WHERE name = 'CustomerHistory'
  AND SCHEMA_NAME(schema_id) = 'dbo';
GO


-- สำเร็จ! Temporal Table ถูกปิดใช้งานแล้ว
GO

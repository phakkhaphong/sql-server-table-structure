-- =============================================
-- Script: 02-alter-table-to-temporal-table.sql
-- Description: แปลงตารางเดิมที่มีข้อมูลอยู่แล้วเป็น Temporal Table
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- คำเตือน: Script นี้จะแปลงตาราง Person.Person เป็น Temporal Table
-- กรุณาทำการ Backup ฐานข้อมูลก่อนรัน Script นี้
-- =============================================

USE AdventureWorks2022;
GO

-- ตรวจสอบว่าตารางมีอยู่แล้วหรือไม่
IF OBJECT_ID('Person.Person', 'U') IS NULL
BEGIN
    -- ERROR: ไม่พบตาราง Person.Person
    -- กรุณาใช้ AdventureWorks2022 Database
    RETURN;
END
GO

-- ตรวจสอบว่าตารางเป็น Temporal Table อยู่แล้วหรือไม่
IF EXISTS (
    SELECT 1 
    FROM sys.tables 
    WHERE name = 'Person' 
      AND SCHEMA_NAME(schema_id) = 'Person'
      AND temporal_type_desc = 'SYSTEM_VERSIONED_TEMPORAL_TABLE'
)
BEGIN
    -- ตาราง Person.Person เป็น Temporal Table อยู่แล้ว
    RETURN;
END
GO

-- เริ่มกระบวนการแปลงตาราง Person.Person เป็น Temporal Table
GO

-- ขั้นตอนที่ 1: เพิ่มคอลัมน์ ValidFrom และ ValidTo
-- ใช้ HIDDEN เพื่อซ่อนคอลัมน์จาก SELECT * แต่ยังใช้งานได้
-- ขั้นตอนที่ 1: เพิ่มคอลัมน์ ValidFrom และ ValidTo

ALTER TABLE Person.Person
ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN NOT NULL
        CONSTRAINT DF_Person_ValidFrom DEFAULT SYSUTCDATETIME(),
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL
        CONSTRAINT DF_Person_ValidTo DEFAULT CONVERT(DATETIME2, '9999-12-31 23:59:59.9999999');
GO

-- เพิ่มคอลัมน์เสร็จสมบูรณ์
GO

-- ขั้นตอนที่ 2: กำหนด PERIOD FOR SYSTEM_TIME
-- ขั้นตอนที่ 2: กำหนด PERIOD FOR SYSTEM_TIME

ALTER TABLE Person.Person
ADD PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
GO

-- กำหนด PERIOD เสร็จสมบูรณ์
GO

-- ขั้นตอนที่ 3: เปิดใช้งาน SYSTEM_VERSIONING
-- ขั้นตอนที่ 3: เปิดใช้งาน SYSTEM_VERSIONING
-- History Table จะถูกสร้างอัตโนมัติ

ALTER TABLE Person.Person
SET (SYSTEM_VERSIONING = ON (
    HISTORY_TABLE = Person.PersonHistory,
    DATA_CONSISTENCY_CHECK = ON  -- ตรวจสอบความถูกต้องของข้อมูล
));
GO

-- เปิดใช้งาน System Versioning เสร็จสมบูรณ์
GO

-- สร้าง Index สำหรับ History Table เพื่อเพิ่มประสิทธิภาพ
IF OBJECT_ID('Person.PersonHistory', 'U') IS NOT NULL
BEGIN
    -- กำลังสร้าง Index สำหรับ History Table...
    
    -- Index สำหรับการ Query ตามช่วงเวลา
    IF NOT EXISTS (SELECT 1 FROM sys.indexes 
                   WHERE name = 'IX_PersonHistory_ValidFrom_ValidTo' 
                   AND object_id = OBJECT_ID('Person.PersonHistory'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_PersonHistory_ValidFrom_ValidTo
            ON Person.PersonHistory(ValidFrom, ValidTo)
            INCLUDE (BusinessEntityID, FirstName, LastName);
        -- สร้าง Index IX_PersonHistory_ValidFrom_ValidTo เสร็จสมบูรณ์
    END
    
    -- Index สำหรับการ Query ตาม BusinessEntityID
    IF NOT EXISTS (SELECT 1 FROM sys.indexes 
                   WHERE name = 'IX_PersonHistory_BusinessEntityID' 
                   AND object_id = OBJECT_ID('Person.PersonHistory'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_PersonHistory_BusinessEntityID
            ON Person.PersonHistory(BusinessEntityID, ValidFrom, ValidTo);
        -- สร้าง Index IX_PersonHistory_BusinessEntityID เสร็จสมบูรณ์
    END
END
GO

-- ตรวจสอบสถานะ Temporal Table

-- สรุปผลการแปลงตาราง:
-- =

SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    temporal_type_desc AS TemporalType,
    OBJECT_NAME(history_table_id) AS HistoryTableName
FROM sys.tables
WHERE name IN ('Person', 'PersonHistory')
  AND SCHEMA_NAME(schema_id) IN ('Person', 'Person')
ORDER BY name;
GO

-- ตรวจสอบจำนวนแถว

-- จำนวนแถวในตาราง:
SELECT 
    'Current Table' AS TableType,
    COUNT(*) AS RowCount
FROM Person.Person
UNION ALL
SELECT 
    'History Table' AS TableType,
    COUNT(*) AS RowCount
FROM Person.PersonHistory;
GO


-- สำเร็จ! ตาราง Person.Person ถูกแปลงเป็น Temporal Table แล้ว
-- กรุณา Backup ฐานข้อมูลหลังจากงานนี้เสร็จสิ้น
GO

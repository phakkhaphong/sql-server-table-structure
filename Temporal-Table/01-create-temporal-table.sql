-- =============================================
-- Script: 01-create-temporal-table.sql
-- Description: สร้าง Temporal Table ใหม่ตั้งแต่ต้น
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- ตรวจสอบว่าตารางมีอยู่แล้วหรือไม่
IF OBJECT_ID('dbo.CustomerHistory', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.CustomerHistory;
    -- ลบตาราง dbo.CustomerHistory ที่มีอยู่เดิมแล้ว
END
GO

-- สร้าง Temporal Table
-- Temporal Table ต้องมี:
-- 1. Primary Key หรือ Unique Index
-- 2. คอลัมน์ ValidFrom และ ValidTo (DATETIME2)
-- 3. PERIOD FOR SYSTEM_TIME
-- 4. SYSTEM_VERSIONING = ON

CREATE TABLE dbo.CustomerHistory (
    CustomerID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(25) NULL,
    CustomerSince DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    -- คอลัมน์สำหรับ Temporal Table
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START 
        CONSTRAINT DF_CustomerHistory_ValidFrom DEFAULT SYSUTCDATETIME() NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END 
        CONSTRAINT DF_CustomerHistory_ValidTo DEFAULT CONVERT(DATETIME2, '9999-12-31 23:59:59.9999999') NOT NULL,
    
    -- กำหนด PERIOD FOR SYSTEM_TIME
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (
    -- เปิดใช้งาน System Versioning
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.CustomerHistoryArchive)
);
GO

-- สร้าง Index สำหรับการ Query
CREATE NONCLUSTERED INDEX IX_CustomerHistory_Email 
    ON dbo.CustomerHistory(Email)
    INCLUDE (FirstName, LastName);
GO

-- สร้าง Index สำหรับ History Table
CREATE NONCLUSTERED INDEX IX_CustomerHistoryArchive_ValidFrom_ValidTo 
    ON dbo.CustomerHistoryArchive(ValidFrom, ValidTo);
GO

-- สร้าง Temporal Table dbo.CustomerHistory เสร็จสมบูรณ์แล้ว
-- History Table ถูกสร้างอัตโนมัติ: dbo.CustomerHistoryArchive
GO

-- ตรวจสอบว่า Temporal Table ถูกสร้างถูกต้อง
SELECT
     t1.name AS TableName
,    t1.temporal_type_desc AS TemporalType
,    t2.name AS HistoryTableName
FROM sys.tables t1
LEFT JOIN sys.tables t2 ON t1.history_table_id = t2.object_id
WHERE t1.name = 'CustomerHistory'
  AND SCHEMA_NAME(t1.schema_id) = 'dbo'
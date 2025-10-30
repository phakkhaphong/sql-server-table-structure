-- =============================================
-- Script: 05-partition-switching.sql
-- Description: การใช้ Partition Switching สำหรับ Fast Data Loading และ Archival
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- Prerequisite: ต้องรัน 01 และ 02 ก่อน
-- =============================================

USE AdventureWorks2022;
GO

-- === Partition Switching ===

-- Partition Switching เป็นการย้ายข้อมูลระหว่างตารางได้ภายในไม่กี่มิลลิวินาที
-- เหมาะสำหรับ:
--   1. Fast Data Loading
--   2. Data Archival
--   3. Staging Tables

GO

-- =============================================
-- Use Case 1: Fast Data Loading
-- =============================================


-- === Use Case 1: Fast Data Loading ===

GO

-- สร้าง Staging Table สำหรับ Loading ข้อมูลใหม่
IF OBJECT_ID('dbo.SalesOrderHeader_StagingLoad', 'U') IS NOT NULL
    DROP TABLE dbo.SalesOrderHeader_StagingLoad;
GO

CREATE TABLE dbo.SalesOrderHeader_StagingLoad (
    SalesOrderID INT NOT NULL,
    RevisionNumber TINYINT NOT NULL,
    OrderDate DATETIME2 NOT NULL,
    DueDate DATETIME2 NOT NULL,
    ShipDate DATETIME2 NULL,
    Status TINYINT NOT NULL,
    OnlineOrderFlag BIT NOT NULL,
    SalesOrderNumber NVARCHAR(25) NOT NULL,
    PurchaseOrderNumber NVARCHAR(25) NULL,
    AccountNumber NVARCHAR(15) NULL,
    CustomerID INT NOT NULL,
    SalesPersonID INT NULL,
    TerritoryID INT NULL,
    BillToAddressID INT NOT NULL,
    ShipToAddressID INT NOT NULL,
    ShipMethodID INT NOT NULL,
    CreditCardID INT NULL,
    CreditCardApprovalCode VARCHAR(15) NULL,
    CurrencyRateID INT NULL,
    SubTotal MONEY NOT NULL,
    TaxAmt MONEY NOT NULL,
    Freight MONEY NOT NULL,
    TotalDue AS (SubTotal + TaxAmt + Freight),
    Comment NVARCHAR(128) NULL,
    RowGuid UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    CONSTRAINT PK_SalesOrderHeader_StagingLoad PRIMARY KEY CLUSTERED (
        SalesOrderID,
        OrderDate
    ),
    
    CONSTRAINT CK_StagingLoad_OrderDate CHECK (
        OrderDate >= '2026-01-01' AND OrderDate < '2027-01-01'
    )
)
ON PS_SalesOrderByYear(OrderDate);
GO

-- สร้าง Staging Table: dbo.SalesOrderHeader_StagingLoad
-- Constraint: ข้อมูลต้องอยู่ในช่วง 2026
GO

-- Insert ข้อมูลลง Staging Table

-- Loading ข้อมูลลง Staging Table...
GO

-- สร้างข้อมูลตัวอย่างสำหรับปี 2026
DECLARE @BaseDate DATETIME2 = '2026-01-01';
DECLARE @i INT = 1;
DECLARE @MaxRows INT = 10;

WHILE @i <= @MaxRows
BEGIN
    INSERT INTO dbo.SalesOrderHeader_StagingLoad (
        SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate,
        Status, OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber,
        AccountNumber, CustomerID, SalesPersonID, TerritoryID,
        BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID,
        CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight,
        Comment, RowGuid, ModifiedDate
    )
    VALUES (
        99999 + @i,  -- SalesOrderID
        1,           -- RevisionNumber
        DATEADD(DAY, @i % 365, @BaseDate),  -- OrderDate
        DATEADD(DAY, 7 + @i % 365, @BaseDate),  -- DueDate
        NULL,        -- ShipDate
        1,           -- Status
        1,           -- OnlineOrderFlag
        'SO-' + CAST(99999 + @i AS VARCHAR),  -- SalesOrderNumber
        NULL,        -- PurchaseOrderNumber
        NULL,        -- AccountNumber
        ABS(CHECKSUM(NEWID())) % 1000 + 1,  -- CustomerID
        NULL,        -- SalesPersonID
        ABS(CHECKSUM(NEWID())) % 10 + 1,  -- TerritoryID
        1,           -- BillToAddressID
        1,           -- ShipToAddressID
        1,           -- ShipMethodID
        NULL,        -- CreditCardID
        NULL,        -- CreditCardApprovalCode
        NULL,        -- CurrencyRateID
        100.00 + (ABS(CHECKSUM(NEWID())) % 9000),  -- SubTotal
        10.00,       -- TaxAmt
        5.00,        -- Freight
        NULL,        -- Comment
        NEWID(),     -- RowGuid
        GETDATE()    -- ModifiedDate
    );
    
    SET @i = @i + 1;
END
GO

-- Insert เสร็จ: ' + CAST((SELECT COUNT(*) FROM dbo.SalesOrderHeader_StagingLoad) AS VARCHAR) + ' rows
GO

-- ตรวจสอบ Partition
SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    COUNT(*) AS RowCount
FROM dbo.SalesOrderHeader_StagingLoad
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate);
GO

-- Switching ข้อมูลจาก Staging ไป Main Table

-- Switching ข้อมูลจาก Staging → Main Table
-- (Instant - ไม่กี่มิลลิวินาที)
GO

-- ตรวจสอบข้อมูลก่อน Switch
-- ข้อมูลใน Main Table ก่อน Switch:
SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    COUNT(*) AS RowCount
FROM dbo.SalesOrderHeaderPartitioned
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate)
ORDER BY PartitionNumber;
GO

-- ทำการ Switch
ALTER TABLE dbo.SalesOrderHeader_StagingLoad
SWITCH PARTITION 7 TO dbo.SalesOrderHeaderPartitioned PARTITION 7;
GO

-- Switch เสร็จสมบูรณ์!
GO

-- ตรวจสอบผลลัพธ์

-- ข้อมูลใน Main Table หลัง Switch:
SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    COUNT(*) AS RowCount
FROM dbo.SalesOrderHeaderPartitioned
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate)
ORDER BY PartitionNumber;
GO

-- =============================================
-- Use Case 2: Data Archival
-- =============================================



-- === Use Case 2: Data Archival ===

GO

-- สร้างตาราง Archive
IF OBJECT_ID('dbo.SalesOrderHeaderArchive', 'U') IS NOT NULL
    DROP TABLE dbo.SalesOrderHeaderArchive;
GO

CREATE TABLE dbo.SalesOrderHeaderArchive (
    SalesOrderID INT NOT NULL,
    RevisionNumber TINYINT NOT NULL,
    OrderDate DATETIME2 NOT NULL,
    DueDate DATETIME2 NOT NULL,
    ShipDate DATETIME2 NULL,
    Status TINYINT NOT NULL,
    OnlineOrderFlag BIT NOT NULL,
    SalesOrderNumber NVARCHAR(25) NOT NULL,
    PurchaseOrderNumber NVARCHAR(25) NULL,
    AccountNumber NVARCHAR(15) NULL,
    CustomerID INT NOT NULL,
    SalesPersonID INT NULL,
    TerritoryID INT NULL,
    BillToAddressID INT NOT NULL,
    ShipToAddressID INT NOT NULL,
    ShipMethodID INT NOT NULL,
    CreditCardID INT NULL,
    CreditCardApprovalCode VARCHAR(15) NULL,
    CurrencyRateID INT NULL,
    SubTotal MONEY NOT NULL,
    TaxAmt MONEY NOT NULL,
    Freight MONEY NOT NULL,
    TotalDue AS (SubTotal + TaxAmt + Freight),
    Comment NVARCHAR(128) NULL,
    RowGuid UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    CONSTRAINT PK_SalesOrderHeaderArchive PRIMARY KEY CLUSTERED (
        SalesOrderID,
        OrderDate
    )
)
ON SalesFG2020;  -- Archive ไปยัง Filegroup เดิม
GO

-- สร้าง Archive Table: dbo.SalesOrderHeaderArchive
GO

-- Switching ข้อมูลจาก Main → Archive

-- Switching ข้อมูลเก่าไป Archive
GO

-- ตรวจสอบข้อมูลก่อน Switch
-- จำนวนข้อมูลที่จะ Archive (Partition 1):
SELECT COUNT(*) AS RowCount
FROM dbo.SalesOrderHeaderPartitioned
WHERE $PARTITION.PF_SalesOrderByYear(OrderDate) = 1;
GO

-- Switch Partition 1 (ข้อมูลเก่า) ไป Archive
-- ALTER TABLE dbo.SalesOrderHeaderPartitioned
-- SWITCH PARTITION 1 TO dbo.SalesOrderHeaderArchive PARTITION 1;

-- หมายเหตุ: ต้องโครงสร้างและ Constraint เหมือนกันทุกอย่าง

-- หมายเหตุ: Switch จะทำงานได้เมื่อ:
--   1. Table Structures เหมือนกันทุกอย่าง
--   2. Indexes เหมือนกัน
--   3. Constraints (PK, FK, Check) ตรงกัน
--   4. Data Range อยู่ใน Partition ที่ถูกต้อง
GO

-- =============================================
-- Best Practices
-- =============================================



-- === Best Practices สำหรับ Partition Switching ===

-- 1. การเตรียมตารางสำหรับ Switch:
--    - โครงสร้างเหมือนกัน 100%
--    - Indexes ตรงกัน
--    - Constraints ตรงกัน
--    - Data Type ตรงกัน

-- 2. Check Constraints สำคัญมาก:
--    - กำหนด Range ให้ชัดเจน
--    - ป้องกันข้อมูลผิด Partition

-- 3. Performance:
--    - Switch = Instant (Metadata Only)
--    - ไม่มีการ Move Data จริง
--    - ใช้ได้แม้ตารางมีหลายล้านแถว

-- 4. Maintenance Window:
--    - ทดสอบใน Test Environment
--    - Monitor Transaction Log
--    - Backup หลัง Switch

-- 5. Common Patterns:
--    - ETL: Staging → Main
--    - Archival: Main → Archive
--    - Purging: Old → Empty
GO


-- สำเร็จ! จบการสาธิต Partition Switching
GO


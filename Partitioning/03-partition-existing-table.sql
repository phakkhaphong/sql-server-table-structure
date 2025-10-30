-- =============================================
-- Script: 03-partition-existing-table.sql
-- Description: แปลงตารางเดิมที่มีข้อมูลอยู่แล้วเป็น Partitioned Table
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- คำเตือน: Script นี้จะแปลงตาราง Production
-- กรุณา Backup ฐานข้อมูลก่อนรัน Script นี้
-- =============================================

USE AdventureWorks2022;
GO

-- ตรวจสอบว่า Partition Scheme ถูกสร้างแล้วหรือไม่
IF NOT EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = 'PS_SalesOrderByYear')
BEGIN
    -- ERROR: ไม่พบ Partition Scheme PS_SalesOrderByYear
    -- กรุณารัน 01-create-partition-function-and-scheme.sql ก่อน
    RETURN;
END
GO

-- =============================================
-- วิธีที่ 1: ใช้ Partition Switching (แนะนำ)
-- =============================================

-- === วิธีที่ 1: การแปลงโดยใช้ Partition Switching ===
-- วิธีนี้ใช้ตาราง Staging แบบชั่วคราว

GO

-- ขั้นตอนที่ 1: สร้างตาราง Staging เหมือนโครงสร้างเดิมทุกอย่าง
-- ขั้นตอนที่ 1: สร้าง Staging Table (Partitioned)

IF OBJECT_ID('dbo.SalesOrderHeader_Staging', 'U') IS NOT NULL
    DROP TABLE dbo.SalesOrderHeader_Staging;
GO

CREATE TABLE dbo.SalesOrderHeader_Staging (
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
    
    CONSTRAINT PK_SalesOrderHeader_Staging PRIMARY KEY CLUSTERED (
        SalesOrderID,
        OrderDate
    )
)
ON PS_SalesOrderByYear(OrderDate);
GO

-- สร้าง Staging Table เสร็จสมบูรณ์
GO

-- ขั้นตอนที่ 2: Copy ข้อมูลเข้า Staging Table
-- หมายเหตุ: ใน Production อาจใช้ SSIS หรือ Bulk Insert

-- ขั้นตอนที่ 2: Copy ข้อมูลเข้า Staging Table

-- ใช้วิธี Insert แทน Switching สำหรับตารางเดิมที่ไม่ Partitioned
-- ใน Production จริง อาจใช้ BCP, SSIS หรือ SQLBulkCopy

-- จำลองข้อมูลสำหรับ Demo
INSERT INTO dbo.SalesOrderHeader_Staging (
    SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate,
    Status, OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber,
    AccountNumber, CustomerID, SalesPersonID, TerritoryID,
    BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID,
    CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight,
    Comment, RowGuid, ModifiedDate
)
SELECT TOP 100
    SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate,
    Status, OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber,
    AccountNumber, CustomerID, SalesPersonID, TerritoryID,
    BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID,
    CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight,
    Comment, RowGuid, ModifiedDate
FROM Sales.SalesOrderHeader
WHERE OrderDate IS NOT NULL;
GO

-- ตรวจสอบข้อมูลใน Staging Table
SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    COUNT(*) AS RowCount,
    MIN(OrderDate) AS MinDate,
    MAX(OrderDate) AS MaxDate
FROM dbo.SalesOrderHeader_Staging
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate)
ORDER BY PartitionNumber;
GO

-- Copy ข้อมูลเสร็จสมบูรณ์

-- หมายเหตุ: ใน Production จริง:
-- 1. ถ้า Source Table อยู่ใน Partition ที่ตรงกัน: ใช้ SWITCH
-- 2. ถ้า Source Table ไม่ Partitioned: ใช้ BCP/SSIS/BulkInsert
-- 3. ทำทีละ Partition เพื่อลด Downtime
GO

-- =============================================
-- วิธีที่ 2: แปลงตารางเดิมโดยตรง (สำหรับตารางเล็ก)
-- =============================================



-- === วิธีที่ 2: การแปลงตารางเดิมโดยตรง ===
-- วิธีนี้ใช้ได้เมื่อตารางไม่ใหญ่มาก

GO

-- สร้างตารางตัวอย่างใหม่
IF OBJECT_ID('dbo.SalesOrderHeader_Original', 'U') IS NOT NULL
    DROP TABLE dbo.SalesOrderHeader_Original;
GO

-- Copy โครงสร้างและข้อมูลจากตารางเดิม
SELECT TOP 100
    SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate,
    Status, OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber,
    AccountNumber, CustomerID, SalesPersonID, TerritoryID,
    BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID,
    CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight,
    Comment, RowGuid, ModifiedDate
INTO dbo.SalesOrderHeader_Original
FROM Sales.SalesOrderHeader;
GO

-- สร้าง Primary Key
ALTER TABLE dbo.SalesOrderHeader_Original
ADD CONSTRAINT PK_SalesOrderHeader_Original 
    PRIMARY KEY CLUSTERED (SalesOrderID);
GO

-- สร้างตาราง dbo.SalesOrderHeader_Original ประกอบ: 
      CAST((SELECT COUNT(*) FROM dbo.SalesOrderHeader_Original) AS VARCHAR) + ' rows';
GO

-- ตอนนี้จะแปลงตารางนี้เป็น Partitioned

-- ขั้นตอนการแปลง:
-- 1. ลบ Primary Key แบบเดิม
-- 2. สร้าง Partitioned Primary Key ใหม่
-- 3. Rebuild Indexes
GO

-- ขั้นตอนที่ 1: ลบ Indexes เก่า

-- ลบ Primary Key แบบเดิม...

-- Drop Foreign Keys first (ถ้ามี)
-- ตัวอย่างใน AdventureWorks อาจมี FK หลายตัว
-- (ข้ามขั้นตอนนี้ใน Demo - ควรทำใน Production)
GO

-- ขั้นตอนที่ 2: สร้าง Primary Key แบบ Partitioned

-- สร้าง Primary Key แบบ Partitioned...

ALTER TABLE dbo.SalesOrderHeader_Original
DROP CONSTRAINT PK_SalesOrderHeader_Original;
GO

-- สร้าง Clustered Index ใหม่บน Partition Scheme
CREATE CLUSTERED INDEX PK_SalesOrderHeader_Original
    ON dbo.SalesOrderHeader_Original(SalesOrderID, OrderDate)
    ON PS_SalesOrderByYear(OrderDate);
GO

-- Add as Primary Key (ต้องสร้าง Constraint แยก)
ALTER TABLE dbo.SalesOrderHeader_Original
ADD CONSTRAINT PK_SalesOrderHeader_Original_PK
    PRIMARY KEY NONCLUSTERED (SalesOrderID);
GO

-- สร้าง Primary Key แบบ Partitioned เสร็จสมบูรณ์
GO

-- ตรวจสอบผลลัพธ์

-- ตรวจสอบผลลัพธ์:

SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    COUNT(*) AS RowCount,
    MIN(OrderDate) AS MinDate,
    MAX(OrderDate) AS MaxDate
FROM dbo.SalesOrderHeader_Original
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate)
ORDER BY PartitionNumber;
GO

-- =============================================
-- สรุป Best Practices
-- =============================================



-- === สรุป Best Practices สำหรับ Partitioning Existing Tables ===

-- วิธีที่ 1: Staging + Switching (แนะนำสำหรับตารางใหญ่)
--   ✅ Pros: Downtime น้อย, ออนไลน์, สามารถ Rollback ได้
--   ❌ Cons: ใช้ Storage 2 เท่าชั่วคราว

-- วิธีที่ 2: ALTER TABLE (เหมาะสำหรับตารางเล็ก)
--   ✅ Pros: ง่าย, ไม่ต้องใช้ Staging
--   ❌ Cons: Downtime, ใช้ Resources มาก

-- ขั้นตอนการทำใน Production:
--   1. Backup Database
--   2. ทดสอบใน Test Environment ก่อน
--   3. ทำ Maintenance Window
--   4. Monitor Resources (CPU, Memory, I/O)
--   5. Rebuild Statistics และ Update Indexes
GO


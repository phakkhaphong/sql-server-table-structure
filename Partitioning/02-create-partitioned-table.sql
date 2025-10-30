-- =============================================
-- Script: 02-create-partitioned-table.sql
-- Description: สร้างตารางใหม่แบบ Partitioned
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- Prerequisite: ต้องรัน 01-create-partition-function-and-scheme.sql ก่อน
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
-- ขั้นตอนที่ 1: ลบตารางเก่า (ถ้ามี)
-- =============================================

-- ขั้นตอนที่ 1: ลบตารางเก่า (ถ้ามี)

IF OBJECT_ID('dbo.SalesOrderHeaderPartitioned', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.SalesOrderHeaderPartitioned;
    -- ลบตาราง dbo.SalesOrderHeaderPartitioned ที่มีอยู่เดิมแล้ว
END
GO


GO

-- =============================================
-- ขั้นตอนที่ 2: สร้างตาราง Partitioned
-- =============================================

-- ขั้นตอนที่ 2: สร้างตารางแบบ Partitioned


-- สร้างตารางแบบ Partitioned
-- ใช้ OrderDate เป็น Partition Key
CREATE TABLE dbo.SalesOrderHeaderPartitioned (
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
    
    CONSTRAINT PK_SalesOrderHeaderPartitioned PRIMARY KEY CLUSTERED (
        SalesOrderID,
        OrderDate  -- ต้องรวม Partition Key ใน Clustered Index
    )
)
ON PS_SalesOrderByYear(OrderDate);  -- ใช้ Partition Scheme ที่สร้างไว้
GO

-- สร้างตาราง dbo.SalesOrderHeaderPartitioned เสร็จสมบูรณ์
GO

-- =============================================
-- ขั้นตอนที่ 3: สร้าง Index เพิ่มเติม
-- =============================================


-- ขั้นตอนที่ 3: สร้าง Index เพิ่มเติม

-- Nonclustered Index (จะ Partition อัตโนมัติตาม Table)
CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderPartitioned_CustomerID
    ON dbo.SalesOrderHeaderPartitioned(CustomerID)
    INCLUDE (OrderDate, TotalDue);
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderPartitioned_SalesPersonID
    ON dbo.SalesOrderHeaderPartitioned(SalesPersonID)
    INCLUDE (OrderDate, TotalDue);
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderPartitioned_OrderDate
    ON dbo.SalesOrderHeaderPartitioned(OrderDate)
    INCLUDE (SalesOrderID, CustomerID, TotalDue);
GO

-- สร้าง Index เสร็จสมบูรณ์
GO

-- =============================================
-- ขั้นตอนที่ 4: Insert ข้อมูลตัวอย่าง
-- =============================================


-- ขั้นตอนที่ 4: Insert ข้อมูลตัวอย่าง

-- Insert ข้อมูลจากตารางเดิมเพื่อทดสอบ
-- (ระวัง: AdventureWorks2022 อาจมีข้อมูลจำนวนมาก)

INSERT INTO dbo.SalesOrderHeaderPartitioned (
    SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate,
    Status, OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber,
    AccountNumber, CustomerID, SalesPersonID, TerritoryID,
    BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID,
    CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight,
    Comment, RowGuid, ModifiedDate
)
SELECT TOP 1000
    SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate,
    Status, OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber,
    AccountNumber, CustomerID, SalesPersonID, TerritoryID,
    BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID,
    CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight,
    Comment, RowGuid, ModifiedDate
FROM Sales.SalesOrderHeader
ORDER BY SalesOrderID;
GO

-- Insert ข้อมูลเสร็จสมบูรณ์: 1000 rows
GO

-- =============================================
-- ขั้นตอนที่ 5: ตรวจสอบ Partitions
-- =============================================


-- ขั้นตอนที่ 5: ตรวจสอบข้อมูลในแต่ละ Partition
GO

SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    MIN(OrderDate) AS MinDate,
    MAX(OrderDate) AS MaxDate,
    COUNT(*) AS RowCount
FROM dbo.SalesOrderHeaderPartitioned
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate)
ORDER BY PartitionNumber;
GO


GO

-- =============================================
-- ขั้นตอนที่ 6: ทดสอบ Query Performance
-- =============================================

-- ขั้นตอนที่ 6: ทดสอบ Query Performance


-- Query ที่ใช้ Partition Elimination
-- Query 1: Query ที่ครอบคลุมหลาย Partitions (ควรใช้ ALL Partitions)
SET STATISTICS IO ON;
GO

SELECT 
    $PARTITION.PF_SalesOrderByYear(OrderDate) AS PartitionNumber,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSales
FROM dbo.SalesOrderHeaderPartitioned
WHERE OrderDate BETWEEN '2020-01-01' AND '2023-12-31'
GROUP BY $PARTITION.PF_SalesOrderByYear(OrderDate)
ORDER BY PartitionNumber;
GO

SET STATISTICS IO OFF;
GO


-- Query 2: Query ที่ครอบคลุม Partition เดียว (ควรใช้ Partition Elimination)
SET STATISTICS IO ON;
GO

SELECT 
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSales
FROM dbo.SalesOrderHeaderPartitioned
WHERE OrderDate >= '2022-01-01' 
  AND OrderDate < '2023-01-01';
GO

SET STATISTICS IO OFF;
GO


GO

-- =============================================
-- ขั้นตอนที่ 7: แสดงรายละเอียด Partition Info
-- =============================================

-- ขั้นตอนที่ 7: แสดงรายละเอียด Partition Info


-- ดู Partition Information
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    p.partition_number AS PartitionNumber,
    CASE 
        WHEN rg.CONVERTED IS NULL THEN fg.name
        ELSE fg.name + ' (COMPRESSED)'
    END AS FilegroupName,
    p.rows AS RowCount,
    CONVERT(DECIMAL(18,2), p.in_row_reserved_page_count * 8.0 / 1024) AS ReservedMB,
    CONVERT(DECIMAL(18,2), p.in_row_used_page_count * 8.0 / 1024) AS UsedMB,
    prv_left.value AS LeftBoundary,
    prv_right.value AS RightBoundary
FROM sys.partitions p
LEFT JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
LEFT JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
LEFT JOIN sys.filegroups fg ON COALESCE(ps.data_space_id, i.data_space_id) = fg.data_space_id
LEFT JOIN sys.partition_range_values prv_left ON ps.function_id = prv_left.function_id AND p.partition_number = prv_left.boundary_id
LEFT JOIN sys.partition_range_values prv_right ON ps.function_id = prv_right.function_id AND p.partition_number = prv_right.boundary_id + 1
LEFT JOIN sys.partitions p2 ON p.object_id = p2.object_id AND p.partition_number = p2.partition_number AND p2.index_id IN (0,1)
LEFT JOIN (
    SELECT DISTINCT p.object_id, p.partition_number, 1 AS CONVERTED
    FROM sys.partitions p
    INNER JOIN sys.partition_schemes ps ON EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = p.object_id AND index_id = p.index_id AND data_space_id = ps.data_space_id)
    WHERE p.data_compression > 0
) rg ON p.object_id = rg.object_id AND p.partition_number = rg.partition_number
WHERE OBJECT_NAME(p.object_id) = 'SalesOrderHeaderPartitioned'
  AND p.index_id IN (0,1)
ORDER BY p.partition_number;
GO


-- สำเร็จ! สร้าง Partitioned Table เสร็จสมบูรณ์

-- สรุป:
-- - ตาราง: dbo.SalesOrderHeaderPartitioned
-- - Partition Key: OrderDate
-- - Partition Scheme: PS_SalesOrderByYear
-- - จำนวน Partitions: 7
-- - ข้อมูล: 1,000 rows
GO


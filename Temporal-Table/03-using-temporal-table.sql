-- =============================================
-- Script: 03-using-temporal-table.sql
-- Description: ตัวอย่างการใช้งาน Temporal Table อย่างหลากหลาย
-- Database: AdventureWorks2022
-- Server: SQL Server 2016 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- =============================================
-- ส่วนที่ 1: การทำงานพื้นฐาน (INSERT, UPDATE, DELETE)
-- =============================================

-- === ส่วนที่ 1: การทำงานพื้นฐาน ===
GO

-- INSERT: เพิ่มข้อมูลใหม่
-- 1.1 การ INSERT ข้อมูลใหม่

INSERT INTO dbo.CustomerHistory (FirstName, LastName, Email, Phone)
VALUES 
    ('John', 'Smith', 'john.smith@example.com', '555-0100'),
    ('Jane', 'Doe', 'jane.doe@example.com', '555-0101'),
    ('Bob', 'Johnson', 'bob.johnson@example.com', '555-0102');
GO

-- ดูข้อมูลปัจจุบัน
SELECT CustomerID, FirstName, LastName, Email, Phone
FROM dbo.CustomerHistory
ORDER BY CustomerID;
GO


GO

-- UPDATE: แก้ไขข้อมูล
-- 1.2 การ UPDATE ข้อมูล

-- บันทึกเวลาก่อน UPDATE
DECLARE @BeforeUpdate DATETIME2 = SYSUTCDATETIME();
-- เวลาก่อน UPDATE: 

-- รอ 1 วินาที
WAITFOR DELAY '00:00:01';
GO

UPDATE dbo.CustomerHistory
SET Email = 'john.smith@adventure-works.com',
    Phone = '555-0200'
WHERE CustomerID = 1;
GO

-- ดูประวัติการเปลี่ยนแปลงทั้งหมดของ CustomerID = 1
-- ประวัติการเปลี่ยนแปลงทั้งหมด:
SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    Phone,
    ValidFrom,
    ValidTo,
    CASE 
        WHEN ValidTo = '9999-12-31 23:59:59.9999999' THEN 'Current'
        ELSE 'History'
    END AS RecordType
FROM dbo.CustomerHistory FOR SYSTEM_TIME ALL
WHERE CustomerID = 1
ORDER BY ValidFrom;
GO


GO

-- DELETE: ลบข้อมูล
-- 1.3 การ DELETE ข้อมูล

DELETE FROM dbo.CustomerHistory
WHERE CustomerID = 3;
GO

-- ดูข้อมูลทั้งหมดหลัง DELETE
SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    Phone,
    ValidFrom,
    ValidTo
FROM dbo.CustomerHistory FOR SYSTEM_TIME ALL
ORDER BY CustomerID, ValidFrom;
GO


GO

-- =============================================
-- ส่วนที่ 2: การ Query ข้อมูลแบบต่างๆ
-- =============================================

-- === ส่วนที่ 2: การ Query ข้อมูลแบบต่างๆ ===
GO

-- 2.1 AS OF - ดูข้อมูล ณ เวลาที่ระบุ
-- 2.1 AS OF - ดูข้อมูล ณ เวลาที่ระบุ

-- ดูข้อมูลในช่วงเวลาปัจจุบัน
SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    ValidFrom,
    ValidTo
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME AS OF SYSUTCDATETIME()
ORDER BY CustomerID;
GO

-- ดูข้อมูลในอดีต (กลับไปก่อน UPDATE)
-- ต้องหาช่วงเวลาที่เหมาะสมก่อน
DECLARE @PastTime DATETIME2 = DATEADD(SECOND, -5, SYSUTCDATETIME());
-- ข้อมูล ณ เวลา: 

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    ValidFrom,
    ValidTo
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME AS OF @PastTime
ORDER BY CustomerID;
GO


GO

-- 2.2 FROM ... TO - ดูข้อมูลในช่วงเวลา
-- 2.2 FROM ... TO - ดูข้อมูลในช่วงเวลา

DECLARE @StartTime DATETIME2 = DATEADD(MINUTE, -5, SYSUTCDATETIME());
DECLARE @EndTime DATETIME2 = SYSUTCDATETIME();

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    ValidFrom,
    ValidTo
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME FROM @StartTime TO @EndTime
ORDER BY ValidFrom;
GO


GO

-- 2.3 BETWEEN ... AND - ดูข้อมูลในช่วงเวลา (รวมขอบเขต)
-- 2.3 BETWEEN ... AND - ดูข้อมูลในช่วงเวลา (รวมขอบเขต)

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    ValidFrom,
    ValidTo
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME BETWEEN @StartTime AND @EndTime
ORDER BY ValidFrom;
GO


GO

-- 2.4 CONTAINED IN - ดูข้อมูลที่อยู่ในช่วงเวลา
-- 2.4 CONTAINED IN - ดูข้อมูลที่อยู่ในช่วงเวลา

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    ValidFrom,
    ValidTo
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME CONTAINED IN (@StartTime, @EndTime)
ORDER BY ValidFrom;
GO


GO

-- 2.5 ALL - ดูข้อมูลทั้งหมด (ปัจจุบัน + ประวัติ)
-- 2.5 ALL - ดูข้อมูลทั้งหมด

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    ValidFrom,
    ValidTo,
    CASE 
        WHEN ValidTo = '9999-12-31 23:59:59.9999999' THEN 'Current'
        ELSE 'Historical'
    END AS RecordType
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME ALL
ORDER BY CustomerID, ValidFrom;
GO


GO

-- =============================================
-- ส่วนที่ 3: ตัวอย่างการใช้งานจริง
-- =============================================

-- === ส่วนที่ 3: ตัวอย่างการใช้งานจริง ===
GO

-- 3.1 ติดตามการเปลี่ยนแปลงของลูกค้า
-- 3.1 ติดตามการเปลี่ยนแปลงของลูกค้าทั้งหมด

SELECT 
    CustomerID,
    FirstName,
    LastName,
    COUNT(*) AS TotalChanges,
    MIN(ValidFrom) AS FirstRecord,
    MAX(CASE WHEN ValidTo < '9999-12-31' THEN ValidTo END) AS LastChange
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME ALL
GROUP BY CustomerID, FirstName, LastName
ORDER BY TotalChanges DESC;
GO

-- 3.2 ค้นหาว่าใครแก้ไข Email ของลูกค้า
-- 3.2 ข้อมูลที่เปลี่ยนแปลง Email

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    ValidFrom,
    ValidTo
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME ALL
WHERE CustomerID = 1
  AND ValidTo < '9999-12-31'  -- ไม่รวมข้อมูลปัจจุบัน
ORDER BY ValidFrom;
GO

-- 3.3 เปรียบเทียบข้อมูลปัจจุบันและอดีต
-- 3.3 เปรียบเทียบข้อมูลปัจจุบันและอดีต

-- ข้อมูลปัจจุบัน
DECLARE @Now DATETIME2 = SYSUTCDATETIME();
DECLARE @Before DATETIME2 = DATEADD(MINUTE, -2, @Now);

-- ข้อมูลปัจจุบัน
SELECT 
    'Current' AS DataType,
    CustomerID,
    Email,
    Phone
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME AS OF @Now

UNION ALL

-- ข้อมูลในอดีต
SELECT 
    'Historical' AS DataType,
    CustomerID,
    Email,
    Phone
FROM dbo.CustomerHistory 
FOR SYSTEM_TIME AS OF @Before

ORDER BY CustomerID, DataType;
GO


-- === จบการสาธิต Temporal Table ===
-- กรุณาศึกษา Output ของแต่ละคำสั่งเพื่อทำความเข้าใจการทำงาน
GO

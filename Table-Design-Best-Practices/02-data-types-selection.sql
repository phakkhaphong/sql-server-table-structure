-- =============================================
-- Script: 02-data-types-selection.sql
-- Description: การเลือก Data Types ที่เหมาะสม
-- Database: AdventureWorks2022
-- Server: SQL Server
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Data Types Selection ===

GO

-- =============================================
-- ส่วนที่ 1: String Types
-- =============================================

-- === ส่วนที่ 1: String Types ===

-- CHAR vs VARCHAR vs NVARCHAR:
-- CHAR(n):  Fixed length, suitable for short codes
-- VARCHAR(n): Variable length ASCII (use for most cases)
-- NVARCHAR(n): Variable length Unicode (use for international)


-- ตัวอย่าง: ดี
CREATE TABLE dbo.CustomerExample (
    CustomerCode CHAR(10),        -- Fixed format: 'CUST000001'
    FirstName NVARCHAR(50),       -- Unicode names
    LastName NVARCHAR(50),
    Email VARCHAR(255),            -- ASCII email
    PhoneNumber VARCHAR(20),       -- ASCII phone
    Notes NVARCHAR(MAX)            -- Unlimited text
);
GO

-- =============================================
-- ส่วนที่ 2: Numeric Types
-- =============================================


-- === ส่วนที่ 2: Numeric Types ===

-- Best Practices:
-- ✅ INT สำหรับ IDs และ Counters
-- ✅ DECIMAL สำหรับเงินและค่าที่ต้องแม่นยำ
-- ✅ FLOAT สำหรับ Scientific Calculations
-- ✅ SMALLINT, TINYINT เมื่อขนาดสำคัญ


CREATE TABLE dbo.OrderExample (
    OrderID INT IDENTITY(1,1),    -- INT: 2B range
    ItemCount SMALLINT,            -- SMALLINT: 32K range
    StatusCode TINYINT,            -- TINYINT: 0-255
    Price DECIMAL(10,2),           -- DECIMAL: แม่นยำ 10 digits, 2 decimals
    WeightKG FLOAT,                -- FLOAT: Scientific precision
    Subtotal MONEY                 -- MONEY: ดีสำหรับเงิน
);
GO

-- =============================================
-- ส่วนที่ 3: Date/Time Types
-- =============================================


-- === ส่วนที่ 3: Date/Time Types ===

-- Best Practices:
-- ✅ DATE สำหรับวันที่เท่านั้น
-- ✅ TIME สำหรับเวลาเท่านั้น
-- ✅ DATETIME2 แทน DATETIME (Microsoft แนะนำ)
-- ✅ SMALLDATETIME เมื่อไม่ต้องใช้ Sub-second


CREATE TABLE dbo.EventExample (
    EventID INT IDENTITY(1,1),
    EventDate DATE,                -- DATE: date only
    EventTime TIME,                -- TIME: time only
    CreatedDateTime DATETIME2,     -- DATETIME2: recommended
    ModifiedAt SMALLDATETIME,      -- SMALLDATETIME: less precision
    LastAccessed DATETIMEOFFSET    -- DATETIMEOFFSET: with timezone
);
GO

-- =============================================
-- ส่วนที่ 4: Binary Types
-- =============================================


-- === ส่วนที่ 4: Binary & Special Types ===

-- Best Practices:
-- ✅ VARBINARY(MAX) สำหรับ Files และ Images
-- ✅ UNIQUEIDENTIFIER สำหรับ GUIDs
-- ✅ BIT สำหรับ Flags


CREATE TABLE dbo.DocumentExample (
    DocumentID INT IDENTITY(1,1),
    DocumentGUID UNIQUEIDENTIFIER DEFAULT NEWID(),
    IsActive BIT,                  -- BIT: boolean
    FileContent VARBINARY(MAX),    -- VARBINARY(MAX): files
    FileHash VARBINARY(16),        -- VARBINARY(16): MD5
    IsDeleted BIT DEFAULT 0
);
GO

-- =============================================
-- Best Practices Summary
-- =============================================



-- === Best Practices Summary ===

-- 1. Storage Optimization:
--    - เลือกขนาดที่เหมาะสม (ไม่ใหญ่เกินไป)
--    - ใช้ VARCHAR แทน NVARCHAR เมื่อไม่ต้องใช้ Unicode
--    - ใช้ SMALLINT, TINYINT เมื่อ appropriate

-- 2. Precision vs Storage:
--    - DECIMAL: แม่นยำ แต่ใช้ Storage มาก
--    - FLOAT: เร็ว แต่ไม่แม่นยำ
--    - MONEY: เหมาะสำหรับเงิน

-- 3. Date/Time:
--    - ใช้ DATE/TIME แยกกันเมื่อไม่มีต้องเก็บทั้งสอง
--    - DATETIME2 > DATETIME (always)
--    - DATETIMEOFFSET สำหรับ Timezone-aware

-- 4. Performance:
--    - Fixed-length columns: faster (CHAR, BINARY)
--    - Variable-length: flexible (VARCHAR, VARBINARY)
--    - Choose based on usage patterns
GO


-- สำเร็จ! จบ Data Types Selection
GO


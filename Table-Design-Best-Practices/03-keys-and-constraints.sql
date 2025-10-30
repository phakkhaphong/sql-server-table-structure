-- =============================================
-- Script: 03-keys-and-constraints.sql
-- Description: Keys และ Constraints Best Practices
-- Database: AdventureWorks2022
-- Server: SQL Server
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Keys and Constraints ===

GO

-- =============================================
-- ส่วนที่ 1: Primary Keys
-- =============================================

-- === ส่วนที่ 1: Primary Keys ===

-- Best Practices:
-- ✅ ทุกตารางควรมี Primary Key
-- ✅ Primary Key ควรเป็น Clustered Index (Default Behavior)
-- ⚠️  ระวัง! Primary Key ที่เป็น Clustered Index จะเรียงข้อมูลตามลำดับของ Key
-- ✅ แนะนำ: ใช้ Surrogate Key (INT IDENTITY) แทน Business Key
--    เหตุผล: ป้องกัน Page Split เมื่อ Insert ข้อมูลใหม่


-- ⚠️ NOT RECOMMENDED: Natural Key as Clustered Primary Key
-- ในกรณีนี้ ประเทศ ISO code เรียงลำดับแล้ว แต่ถ้าเป็น Business Key อื่นๆ
-- อาจทำให้เกิด Page Split เมื่อ Insert ข้อมูลกลางลำดับ
CREATE TABLE dbo.Country (
    CountryCode CHAR(2) PRIMARY KEY,  -- Natural Key: ISO code
    CountryName NVARCHAR(100) NOT NULL,
    Region NVARCHAR(50)
);
GO

-- ✅ RECOMMENDED: Surrogate Key as Clustered Primary Key
-- INT IDENTITY(1,1) = เพิ่มขึ้นเรื่อยๆ ทางบวก (Sequential)
-- ทำให้ Insert ข้อมูลอยู่ท้ายตารางเสมอ
-- ไม่เกิด Page Split = ประสิทธิภาพดี
CREATE TABLE dbo.Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,  -- Surrogate Key (Clustered, Sequential)
    Email NVARCHAR(255) NOT NULL UNIQUE,        -- Business Key แยกเป็น Unique Constraint
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL
);
GO

-- ⚠️  ระวัง! IDENTITY ที่ไม่เรียงลำดับจะทำให้เกิด Page Split
-- ❌ ไม่แนะนำ: IDENTITY(1,-1) หรือ IDENTITY(1000,-10)
--    เหตุผล: ลดค่าเรื่อยๆ ทำให้ Insert กลับไปหน้าแรก → Page Split

-- =============================================
-- ส่วนที่ 2: Foreign Keys
-- =============================================


-- === ส่วนที่ 2: Foreign Keys ===

-- Best Practices:
-- ✅ ใช้เพื่อ Referential Integrity
-- ✅ Cascade Options: ON DELETE/UPDATE


CREATE TABLE dbo.Order (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL,
    TotalAmount MONEY,
    CONSTRAINT FK_Order_Customer 
        FOREIGN KEY (CustomerID) 
        REFERENCES dbo.Customer(CustomerID)
        ON DELETE NO ACTION        -- ไม่ให้ลบถ้ามี Order
        ON UPDATE CASCADE          -- Update CustomerID ได้
);
GO

-- =============================================
-- ส่วนที่ 3: Check Constraints
-- =============================================


-- === ส่วนที่ 3: Check Constraints ===

-- Best Practices:
-- ✅ ใช้สำหรับ Validate Data
-- ✅ Domain-specific Rules


CREATE TABLE dbo.Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL,
    DiscountPercent DECIMAL(5,2),
    CONSTRAINT CK_Product_Price 
        CHECK (Price > 0),
    CONSTRAINT CK_Product_Stock 
        CHECK (StockQuantity >= 0),
    CONSTRAINT CK_Product_Discount 
        CHECK (DiscountPercent >= 0 AND DiscountPercent <= 100)
);
GO

-- =============================================
-- ส่วนที่ 4: Default Values
-- =============================================


-- === ส่วนที่ 4: Default Values ===

-- Best Practices:
-- ✅ ใช้สำหรับ Default States
-- ✅ Timestamps และ Flags


CREATE TABLE dbo.EventLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EventType VARCHAR(50) NOT NULL,
    EventMessage NVARCHAR(MAX),
    Severity INT DEFAULT 0,        -- Default severity
    IsProcessed BIT DEFAULT 0,     -- Default flag
    CreatedAt DATETIME2 DEFAULT SYSDATETIME()  -- Auto timestamp
);
GO

-- =============================================
-- Best Practices Summary
-- =============================================



-- === Best Practices Summary ===

-- 1. Primary Keys:
--    - ✅ Surrogate Key: INT IDENTITY(1,1) (RECOMMENDED)
--      * ✅ ต้องเพิ่มขึ้นทางบวก (Increment > 0)
--      * Clustered Index เรียงตามลำดับ ID
--      * Insert ข้อมูลท้ายตาราง = ไม่เกิด Page Split
--      * Performance ดีกว่า Business Key
--    - ❌ Avoid: IDENTITY(1,-1) หรือ Negative Increment
--      * ลดค่า → Insert หน้าแรก → Page Split
--    - ⚠️ Natural Key: ใช้เมื่อเห็นสมควร
--      * ถ้าใช้เป็น Clustered Primary Key อาจเกิด Page Split
--      * ควรแยกเป็น Unique Constraint แทน
--    - Avoid Composite Keys ถ้าเป็นไปได้ (Page Split Risk)

-- 2. Foreign Keys:
--    - ON DELETE NO ACTION: Default, Safe
--    - ON DELETE CASCADE: Use carefully
--    - ON UPDATE CASCADE: Usually OK

-- 3. Constraints:
--    - CHECK: ใช้สำหรับ Business Rules
--    - UNIQUE: ใช้สำหรับ Alternate Keys
--    - NOT NULL: ใช้เมื่อต้องการ enforce

-- 4. Default Values:
--    - ใช้สำหรับ Common Values
--    - Functions: SYSDATETIME(), NEWID()
--    - Constants: 0, empty strings, status codes
GO


-- สำเร็จ! จบ Keys and Constraints
GO


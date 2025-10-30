-- =============================================
-- Script: 01-naming-conventions.sql
-- Description: Naming Conventions Best Practices
-- Database: AdventureWorks2022
-- Server: SQL Server
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================

USE AdventureWorks2022;
GO

-- === Naming Conventions ===

GO

-- =============================================
-- ส่วนที่ 1: Table Naming
-- =============================================

-- === ส่วนที่ 1: Table Naming ===

-- Best Practices:
-- ✅ ใช้ Singular หรือ Plural สม่ำเสมอ
-- ✅ ชื่อสื่อความหมาย ไม่ต้องย่อมาก
-- ✅ หลีกเลี่ยง Reserved Words
-- ✅ ใช้ Schema เพื่อจัดกลุ่ม


-- ตัวอย่าง: ดี
CREATE TABLE dbo.Customer (
    CustomerID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(255)
);
GO

-- ตัวอย่าง: ไม่ดี
-- CREATE TABLE dbo.Cust ( ... );  -- ย่อมากเกินไป
-- CREATE TABLE dbo.User ( ... );  -- Reserved Word
GO

-- =============================================
-- ส่วนที่ 2: Column Naming
-- =============================================


-- === ส่วนที่ 2: Column Naming ===

-- Best Practices:
-- ✅ PascalCase หรือ camelCase สม่ำเสมอ
-- ✅ Descriptive Names
-- ✅ Prefix จัดประเภท: Is/Has/Total/Count


-- ตัวอย่าง: ดี
CREATE TABLE dbo.Product (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    IsActive BIT,
    HasVariants BIT,
    TotalSales MONEY,
    UnitCount INT,
    CreatedDate DATETIME2,
    ModifiedDate DATETIME2
);
GO

-- =============================================
-- ส่วนที่ 3: Index Naming
-- =============================================


-- === ส่วนที่ 3: Index Naming ===

-- Best Practices:
-- ✅ Prefix: PK_, FK_, IX_, UQ_
-- ✅ Include Columns ในชื่อ


-- ตัวอย่าง: ดี
CREATE INDEX IX_Product_ProductName ON dbo.Product(ProductName);
CREATE UNIQUE INDEX UQ_Product_ProductCode ON dbo.Product(ProductCode);
GO

-- =============================================
-- ส่วนที่ 4: Schema Organization
-- =============================================


-- === ส่วนที่ 4: Schema Organization ===

-- Best Practices:
-- ✅ แยกตาม Domain/Module
-- ✅ ใช้ Schema สำหรับ Security


-- ตัวอย่าง
-- CREATE SCHEMA Sales;
-- CREATE SCHEMA Production;
-- CREATE SCHEMA HumanResources;
GO

-- สำเร็จ! จบ Naming Conventions
GO


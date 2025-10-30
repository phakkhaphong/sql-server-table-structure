-- =============================================
-- Script: 02-natively-compiled-procedures.sql
-- Description: Natively Compiled Stored Procedures
-- Database: AdventureWorks2022
-- Server: SQL Server 2014 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- Prerequisite: ต้องรัน 01-create-memory-optimized-table.sql ก่อน
-- =============================================

USE AdventureWorks2022;
GO

-- =============================================
-- ส่วนที่ 1: ตรวจสอบตาราง In-Memory
-- =============================================

-- === Natively Compiled Stored Procedures ===


IF OBJECT_ID('dbo.ShoppingCart_Memory', 'U') IS NULL
BEGIN
    -- ERROR: ไม่พบตาราง dbo.ShoppingCart_Memory
    -- กรุณารัน 01-create-memory-optimized-table.sql ก่อน
    RETURN;
END
GO

-- =============================================
-- ส่วนที่ 2: สร้าง Natively Compiled Procedure
-- =============================================


-- === ส่วนที่ 2: สร้าง Natively Compiled Procedure ===


IF OBJECT_ID('dbo.usp_GetShoppingCartItems', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetShoppingCartItems;
GO

-- สร้าง Natively Compiled Stored Procedure
-- Syntax พิเศษ: ต้องระบุ SCHEMABINDING
CREATE PROCEDURE dbo.usp_GetShoppingCartItems
    @SessionID NVARCHAR(36)
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'us_english'
)
    SELECT 
        ShoppingCartID,
        ProductID,
        Quantity,
        UnitPrice,
        TotalAmount,
        CreatedDate
    FROM dbo.ShoppingCart_Memory
    WHERE SessionID = @SessionID
    ORDER BY CreatedDate;
END;
GO

-- สร้าง Natively Compiled Procedure เสร็จสมบูรณ์
GO

-- =============================================
-- ส่วนที่ 3: สร้าง Procedure สำหรับ Insert
-- =============================================


-- === ส่วนที่ 3: Insert Procedure ===


IF OBJECT_ID('dbo.usp_AddToShoppingCart', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_AddToShoppingCart;
GO

CREATE PROCEDURE dbo.usp_AddToShoppingCart
    @SessionID NVARCHAR(36),
    @ProductID INT,
    @Quantity INT,
    @UnitPrice MONEY
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'us_english'
)
    INSERT INTO dbo.ShoppingCart_Memory (
        SessionID, ProductID, Quantity, UnitPrice, CreatedDate
    )
    VALUES (
        @SessionID, @ProductID, @Quantity, @UnitPrice, SYSDATETIME()
    );
    
    -- Return New ShoppingCartID
    SELECT SCOPE_IDENTITY() AS ShoppingCartID;
END;
GO

-- สร้าง Insert Procedure เสร็จสมบูรณ์
GO

-- =============================================
-- ส่วนที่ 4: สร้าง Procedure สำหรับ Update
-- =============================================


-- === ส่วนที่ 4: Update Procedure ===


IF OBJECT_ID('dbo.usp_UpdateShoppingCartItem', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_UpdateShoppingCartItem;
GO

CREATE PROCEDURE dbo.usp_UpdateShoppingCartItem
    @ShoppingCartID BIGINT,
    @Quantity INT
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'us_english'
)
    UPDATE dbo.ShoppingCart_Memory
    SET Quantity = @Quantity
    WHERE ShoppingCartID = @ShoppingCartID;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

-- สร้าง Update Procedure เสร็จสมบูรณ์
GO

-- =============================================
-- ส่วนที่ 5: ทดสอบ Natively Compiled Procedures
-- =============================================


-- === ส่วนที่ 5: ทดสอบ Procedures ===


-- Test 1: Get Items
-- Test 1: Get Shopping Cart Items
DECLARE @SessionID NVARCHAR(36) = (SELECT TOP 1 SessionID FROM dbo.ShoppingCart_Memory);

EXEC dbo.usp_GetShoppingCartItems @SessionID;
GO

-- Test 2: Add Item

-- Test 2: Add Item to Cart
DECLARE @SessionID NVARCHAR(36) = (SELECT TOP 1 SessionID FROM dbo.ShoppingCart_Memory);

EXEC dbo.usp_AddToShoppingCart 
    @SessionID = @SessionID,
    @ProductID = 999,
    @Quantity = 5,
    @UnitPrice = 99.99;
GO

-- Test 3: Update Item

-- Test 3: Update Item Quantity

EXEC dbo.usp_UpdateShoppingCartItem 
    @ShoppingCartID = 1000,
    @Quantity = 10;
GO

-- =============================================
-- ส่วนที่ 6: เปรียบเทียบ Performance
-- =============================================


-- === ส่วนที่ 6: Performance Comparison ===


-- Regular Procedure (แบบธรรมดา)
IF OBJECT_ID('dbo.usp_GetShoppingCartItems_Regular', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetShoppingCartItems_Regular;
GO

CREATE PROCEDURE dbo.usp_GetShoppingCartItems_Regular
    @SessionID NVARCHAR(36)
AS
BEGIN
    SELECT 
        ShoppingCartID,
        ProductID,
        Quantity,
        UnitPrice,
        TotalAmount,
        CreatedDate
    FROM dbo.ShoppingCart_Memory
    WHERE SessionID = @SessionID
    ORDER BY CreatedDate;
END;
GO

-- Benchmark: Native vs Regular

-- Benchmark: Native vs Regular Procedure


DECLARE @SessionID NVARCHAR(36) = (SELECT TOP 1 SessionID FROM dbo.ShoppingCart_Memory);
DECLARE @StartTime DATETIME2;

-- Native Compiled
SET @StartTime = SYSDATETIME();
EXEC dbo.usp_GetShoppingCartItems @SessionID;
-- Native Compiled: ' + CAST(DATEDIFF(MICROSECOND, @StartTime, SYSDATETIME()) AS VARCHAR) + ' microseconds

-- Regular
SET @StartTime = SYSDATETIME();
EXEC dbo.usp_GetShoppingCartItems_Regular @SessionID;
-- Regular: ' + CAST(DATEDIFF(MICROSECOND, @StartTime, SYSDATETIME()) AS VARCHAR) + ' microseconds
GO

-- =============================================
-- ส่วนที่ 7: ตรวจสอบ Compiled Procedures
-- =============================================


-- === ส่วนที่ 7: ตรวจสอบ Compiled Procedures ===


-- ดู Natively Compiled Procedures
SELECT 
    OBJECT_NAME(object_id) AS ProcedureName,
    uses_native_compilation AS UsesNativeCompilation,
    create_date AS CreateDate,
    modify_date AS ModifyDate
FROM sys.sql_modules
WHERE OBJECT_NAME(object_id) LIKE 'usp_%'
  AND uses_native_compilation = 1;
GO

-- =============================================
-- Best Practices
-- =============================================



-- === Best Practices สำหรับ Natively Compiled Procedures ===

-- 1. เหมาะสำหรับ:
--    ✅ Hot Path Queries (ใช้บ่อยมาก)
--    ✅ Simple Operations
--    ✅ Short Transactions
--    ✅ Point Lookups

-- 2. ข้อจำกัด:
--    ❌ ไม่รองรับ Subqueries บางประเภท
--    ❌ Outer Joins จำกัด
--    ❌ UNION ALL เท่านั้น
--    ❌ No CASE Expressions (บางกรณี)

-- 3. Isolation Levels:
--    - SNAPSHOT: แนะนำ (Default)
--    - REPEATABLE READ: Higher Isolation
--    - SERIALIZABLE: Highest Isolation

-- 4. Schema Binding:
--    - ต้องระบุ SCHEMABINDING
--    - เปลี่ยนแปลง Schema ให้ระวัง
--    - อาจต้อง Recreate Procedure
GO


-- สำเร็จ! จบการสาธิต Natively Compiled Procedures
GO


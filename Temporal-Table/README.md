# Temporal Tables

คู่มือการสอนเกี่ยวกับ Temporal Tables ใน SQL Server

## 📖 บทนำ

Temporal Tables (System-Versioned Temporal Tables) เป็นฟีเจอร์ที่ช่วยให้ SQL Server สามารถติดตามประวัติการเปลี่ยนแปลงของข้อมูลอัตโนมัติ โดยไม่ต้องเขียนโค้ดเพิ่มเติม Temporal Tables จะเก็บข้อมูลใน 2 ตาราง:
- **Current Table**: เก็บข้อมูลปัจจุบัน
- **History Table**: เก็บประวัติการเปลี่ยนแปลงทั้งหมด

## ✨ คุณสมบัติหลัก

- 🔍 **อัตโนมัติ**: ไม่ต้องเขียน Trigger หรือ Stored Procedure เพิ่มเติม
- 📊 **Query ที่ยืดหยุ่น**: Query ข้อมูลในอดีตได้หลายรูปแบบ
- ⏰ **แม่นยำ**: บันทึกเวลาเป็น UTC แม่นยำสูง
- 🔒 **ปลอดภัย**: ไม่สามารถแก้ไขข้อมูลใน History Table ได้โดยตรง

## 📋 ความต้องการของระบบ

- SQL Server 2016 หรือใหม่กว่า
- AdventureWorks2022 Database
- ตัวอย่างจะใช้ตาราง `Person.Person`

## 🗂️ เนื้อหาประกอบด้วย

### 01-create-temporal-table.sql
สร้าง Temporal Table ใหม่ตั้งแต่ต้น
- คอลัมน์ `ValidFrom` และ `ValidTo` สำหรับเก็บช่วงเวลา
- `PERIOD FOR SYSTEM_TIME` สำหรับกำหนดช่วงเวลา
- `SYSTEM_VERSIONING` สำหรับเปิดใช้งาน Temporal

### 02-alter-table-to-temporal-table.sql
แปลงตารางเดิมที่มีข้อมูลอยู่แล้วเป็น Temporal Table
- เพิ่มคอลัมน์ ValidFrom/ValidTo ให้ตารางเดิม
- กำหนดค่า Default ที่เหมาะสม
- เปิดใช้งาน SYSTEM_VERSIONING

### 03-using-temporal-table.sql
ตัวอย่างการใช้งาน Temporal Table
- การ INSERT, UPDATE, DELETE
- การ Query ข้อมูลในอดีตด้วย `FOR SYSTEM_TIME`
- รูปแบบ Query ที่ใช้บ่อย

### 04-close-temporal-table.sql
ขั้นตอนการปิดใช้งาน Temporal Table
- ปิด SYSTEM_VERSIONING
- ลบ PERIOD FOR SYSTEM_TIME
- ลบคอลัมน์ ValidFrom และ ValidTo

## 🎯 รูปแบบการ Query ข้อมูล

### 1. AS OF - ข้อมูล ณ เวลาที่ระบุ
```sql
SELECT * FROM dbo.CustomerHistory
FOR SYSTEM_TIME AS OF '2025-10-01T12:00:00'
WHERE CustomerID = 1;
```

### 2. FROM ... TO - ข้อมูลในช่วงเวลา
```sql
SELECT * FROM dbo.CustomerHistory
FOR SYSTEM_TIME FROM '2025-01-01' TO '2025-12-31'
WHERE CustomerID = 1;
```

### 3. BETWEEN ... AND - ข้อมูลในช่วงเวลา (รวมขอบเขต)
```sql
SELECT * FROM dbo.CustomerHistory
FOR SYSTEM_TIME BETWEEN '2025-01-01' AND '2025-12-31'
WHERE CustomerID = 1;
```

### 4. CONTAINED IN - ข้อมูลที่อยู่ในช่วงเวลา
```sql
SELECT * FROM dbo.CustomerHistory
FOR SYSTEM_TIME CONTAINED IN ('2025-01-01', '2025-12-31')
WHERE CustomerID = 1;
```

### 5. ALL - ข้อมูลทั้งหมด (ปัจจุบัน + ประวัติ)
```sql
SELECT * FROM dbo.CustomerHistory
FOR SYSTEM_TIME ALL
WHERE CustomerID = 1;
```

## ⚠️ ข้อควรระวัง

1. **Primary Key**: ต้องมี Primary Key หรือ Unique Index
2. **NULL Values**: คอลัมน์ ValidFrom และ ValidTo ไม่สามารถเป็น NULL ได้
3. **Schema Binding**: ต้องใช้อัลกอริทึมแบบ SCHEMABINDING
4. **Foreign Keys**: สามารถใช้งานร่วมกับ Foreign Keys ได้ปกติ
5. **History Table**: ไม่สามารถแก้ไขข้อมูลใน History Table ได้โดยตรง

## 🔧 Best Practices

### 1. การตั้งชื่อ
- ใช้ชื่อที่สื่อความหมาย เช่น `CustomerHistory`
- History Table ควรต่อท้ายด้วย `History` หรือ `Archive`

### 2. Indexing
- สร้าง Index บน History Table สำหรับการ Query ประวัติ
- Index บนคอลัมน์ ValidFrom และ ValidTo ช่วยเพิ่มประสิทธิภาพ

### 3. Data Cleanup
- วางแผนการลบข้อมูลประวัติที่ไม่จำเป็นออก
- ใช้ Stretch Database สำหรับเก็บข้อมูลประวัติใน Azure

### 4. Performance
- History Table มักจะใหญ่ขึ้นเรื่อยๆ ควรวางแผนจัดการ
- ใช้ Compression เพื่อลดขนาดข้อมูล

## 📊 ตัวอย่างการใช้งานจริง

### Use Case: ติดตามการเปลี่ยนแปลงข้อมูลลูกค้า
```sql
-- สร้าง Temporal Table
CREATE TABLE dbo.CustomerHistory (
    CustomerID INT NOT NULL PRIMARY KEY,
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    Email NVARCHAR(255),
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.CustomerHistoryArchive));

-- แก้ไขข้อมูล
UPDATE dbo.CustomerHistory
SET Email = 'new.email@example.com'
WHERE CustomerID = 1;

-- ดูประวัติการเปลี่ยนแปลง
SELECT CustomerID, FirstName, LastName, Email, ValidFrom, ValidTo
FROM dbo.CustomerHistory
FOR SYSTEM_TIME ALL
WHERE CustomerID = 1
ORDER BY ValidFrom;
```

## 🔗 ลิงก์อ้างอิง

- [Microsoft Documentation: Temporal Tables](https://docs.microsoft.com/en-us/sql/relational-databases/tables/temporal-tables)
- [SQL Server 2022 Features](https://docs.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2022)
- [AdventureWorks Sample Database](https://github.com/Microsoft/sql-server-samples/releases)

## 📝 หมายเหตุ

- ตัวอย่างทั้งหมดใช้ AdventureWorks2022 Database
- ทุกโค้ดทดสอบแล้วกับ SQL Server 2016 - 2022
- แนะนำให้รันทีละขั้นตอนและศึกษา Output ของแต่ละคำสั่ง

---
**หมายเหตุ**: ไฟล์ทั้งหมดในโฟลเดอร์นี้สามารถรันได้โดยอิสระจากกัน แต่แนะนำให้ทำตามลำดับเพื่อความเข้าใจที่ดีขึ้น


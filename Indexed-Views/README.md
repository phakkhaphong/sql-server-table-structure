# Indexed Views

คู่มือการสอนเกี่ยวกับ Indexed Views (Materialized Views) ใน SQL Server

## 📖 บทนำ

Indexed Views เป็น Views ที่มี Clustered Index สร้างไว้ ทำให้ผลลัพธ์ถูก Materialize และเก็บไว้ใน disk เหมาะสำหรับ:
- ⚡ **Query Performance**: เร็วกว่า View ปกติมาก
- 📊 **Pre-aggregated Data**: Aggregate ไว้ล่วงหน้า
- 🔗 **Complex Joins**: JOIN ที่ซับซ้อนถูก Pre-compute
- 📈 **Consistency**: ข้อมูลสอดคล้องกันเสมอ

**Trade-off**: ใช้ Storage เพิ่ม และต้อง Sync กับข้อมูลต้นฉบับ

## ✨ คุณสมบัติหลัก

### Requirements
- **Schema Binding**: ต้องใช้ `WITH SCHEMABINDING`
- **Deterministic**: คอลัมน์ทั้งหมดต้อง Deterministic
- **Clustered Index**: ต้องมี Clustered Index ก่อน
- **SET Options**: ต้องใช้ SET Options ที่ถูกต้อง

### Benefits
- Accelerate Queries: Query ที่ใช้ View ทำงานเร็วมาก
- Automatic Maintenance: SQL Server จัดการ Index อัตโนมัติ
- Transparent: ใช้งานเหมือน View ปกติ

## 📋 ความต้องการของระบบ

- SQL Server 2000 หรือใหม่กว่า
- AdventureWorks2022 Database
- เหมาะสำหรับ Read-Heavy Workloads

## 🗂️ เนื้อหาประกอบด้วย

### 01-create-indexed-view.sql
สร้าง Indexed View พื้นฐาน
- สร้าง View พร้อม SCHEMABINDING
- เพิ่ม Clustered Index
- ใช้งานและทดสอบ

### 02-aggregate-indexed-view.sql
Indexed View สำหรับ Aggregation
- Pre-aggregate ข้อมูล
- GROUP BY ใน View
- เพิ่มประสิทธิภาพ Aggregate Queries

### 03-maintenance-and-best-practices.sql
การดูแลรักษาและ Best Practices
- การ Rebuild Index
- SET Options
- Monitoring และ Troubleshooting

## ⚠️ ข้อควรระวัง

1. **SET Options**: ต้องใช้ SET Options ที่ถูกต้อง
2. **Maintenance Cost**: DML บน Base Tables มีค่าใช้จ่ายเพิ่ม
3. **Storage**: ใช้ Storage เพิ่มขึ้น
4. **Complexity**: ต้องออกแบบอย่างระมัดระวัง
5. **Query Rewrite**: Optimizer ไม่ได้ Rewrite ทุก Query

## 🔧 Best Practices

### 1. เหมาะสำหรับ
✅ Static หรือ Read-Heavy Data
✅ Queries ที่ใช้ Aggregate
✅ Complex Joins ที่ทำบ่อย
✅ Reporting Queries

### 2. ไม่เหมาะสำหรับ
❌ OLTP Workloads (DML มาก)
❌ Real-time Data
❌ Tables ที่ Update บ่อย
❌ Queries ที่ไม่สามารถ Query Rewrite

### 3. SET Options
```sql
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
```

### 4. การออกแบบ
- เลือกคอลัมน์ที่ Query บ่อย
- หลีกเลี่ยง Functions ที่ไม่ Deterministic
- ใช้ COUNT_BIG() แทน COUNT()
- จำกัดจำนวน Tables ใน View

## 🔗 ลิงก์อ้างอิง

- [Microsoft Documentation: Indexed Views](https://docs.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views)
- [Indexed View Requirements](https://docs.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views#requirements)
- [Query Optimization and Indexed Views](https://docs.microsoft.com/en-us/sql/relational-databases/views/optimize-queries-with-indexed-views)

## 📝 หมายเหตุ

- Indexed Views ใช้ได้ทุก Edition แต่ Query Rewrite ต้องใช้ Enterprise Edition
- Columnstore Indexes มีประโยชน์กว่าในหลาย Use Cases
- ทดสอบ Query Rewrite กับ Query Plan
- Monitor DML Performance Impact

---
**หมายเหตุ**: Indexed Views ยังคงมีประโยชน์ในสถานการณ์เฉพาะ แม้จะมี Columnstore


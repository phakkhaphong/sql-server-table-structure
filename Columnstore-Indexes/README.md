# Columnstore Indexes

คู่มือการสอนเกี่ยวกับ Columnstore Indexes ใน SQL Server สำหรับ Data Warehousing และ Analytics

## 📖 บทนำ

Columnstore Indexes เป็นเทคโนโลยีที่ออกแบบมาเพื่อเพิ่มประสิทธิภาพการ Query ข้อมูลจำนวนมาก (OLAP) โดยเก็บข้อมูลเป็นแบบ Column-based แทน Row-based ทำให้:
- ⚡ **Query Performance**: เร็วกว่า Rowstore 10-100 เท่า
- 📊 **Compression**: บีบอัดข้อมูลได้มากกว่า 10 เท่า
- 🔍 **Scan Optimization**: Scan ข้อมูลเร็วมาก
- 📈 **Aggregation**: GROUP BY และ Aggregate Functions เร็วมาก

## ✨ คุณสมบัติหลัก

### 1. Clustered Columnstore Index (CCI)
- ใช้เป็น Table Structure หลัก
- ไม่มี Rowstore Heap/Clustered Index แยก
- เหมาะสำหรับ Fact Tables ใน Data Warehouse

### 2. Nonclustered Columnstore Index (NCCI)
- สร้างเป็น Index แยกจากตารางปกติ
- ตารางหลักยังเป็น Rowstore
- เหมาะสำหรับ OLTP + Analytics

## 📋 ความต้องการของระบบ

- SQL Server 2014 หรือใหม่กว่า (แนะนำ 2016+)
- AdventureWorks2022 Database
- สำหรับ Analytics/Reporting Workloads

## 🗂️ เนื้อหาประกอบด้วย

### 01-create-clustered-columnstore.sql
สร้างตารางด้วย Clustered Columnstore Index
- เหมาะสำหรับ Fact Tables ขนาดใหญ่
- Compression สูง, Performance ดี

### 02-create-nonclustered-columnstore.sql
เพิ่ม Nonclustered Columnstore Index ให้ Rowstore Table
- เหมาะสำหรับฮีบริด OLTP + Analytics
- ไม่กระทบ DML มาก

### 03-operations-and-maintenance.sql
การใช้งานและ Maintenance Columnstore
- การ INSERT/UPDATE/DELETE
- การ Rebuild/Rebuild Index
- การตรวจสอบ Row Groups

### 04-columnstore-optimization.sql
เทคนิคการเพิ่มประสิทธิภาพ
- Index Secondary
- Partitioning + Columnstore
- Compression Levels

## 🎯 Use Cases

### เหมาะสำหรับ:
✅ **Data Warehousing**: Fact Tables ใหญ่
✅ **Analytics/Reporting**: Aggregate Queries มาก
✅ **Historical Data**: ข้อมูลประวัติ
✅ **BI Workloads**: OLAP Queries
✅ **Ad-hoc Queries**: Scan และ Filter มาก

### ไม่เหมาะสำหรับ:
❌ **OLTP**: Transaction ต่ำกว่า 1ms
❌ **Heavy DML**: UPDATE/DELETE บ่อย
❌ **Single-row Lookup**: เข้าถึงแถวเดียว
❌ **Small Tables**: < 1 million rows

## ⚠️ ข้อควรระวัง

1. **Batch Mode**: ต้องมีข้อมูลเพียงพอ (Batch > 900 rows)
2. **Row Groups**: ควรมี 1 million rows ต่อ Row Group
3. **Compression**: Archive Compression ช้ากว่าแต่บีบอัดมากกว่า
4. **DML Performance**: UPDATE/DELETE ใช้ Resources มาก
5. **Index Maintenance**: ต้อง Rebuild อย่างสม่ำเสมอ

## 🔧 Best Practices

### 1. การเลือก Data Type
- ใช้ Data Type ที่เหมาะสม (ไม่ใหญ่เกินไป)
- ลดการใช้ NVARCHAR เมื่อไม่จำเป็น
- หลีกเลี่ยง XML, JSON, GEOGRAPHY

### 2. Index Design
- ใช้ CCI สำหรับ Fact Tables
- ใช้ NCCI สำหรับ Dimension Tables (ถ้า Query บ่อย)
- หลีกเลี่ยง Indexes เยอะเกินไป

### 3. Partitioning Strategy
- จับคู่ Columnstore กับ Partitioning
- ทำ Maintenance แยกกันทีละ Partition
- ใช้ Sliding Window Pattern

### 4. Query Optimization
- ใช้ Batch Mode
- หลีกเลี่ยง Scalar Functions
- Aggregate ข้อมูลให้มากที่สุด

## 📊 Columnstore Architecture

### Row Groups & Segments
```
Table → Row Groups (1M rows each) → Segments (columns)
                                   → Metadata
```

### Compression
- **Delta Store**: ข้อมูลที่ยังไม่ได้บีบอัด
- **Compressed Groups**: ข้อมูลที่บีบอัดแล้ว (Dictionary + Value Encoding)
- **Tombstone**: Deleted Rows

### Batch Mode Execution
- ประมวลผลข้อมูลทีละ Batch (900+ rows)
- ใช้ประโยชน์จาก SIMD Instructions
- ประสิทธิภาพสูงมากสำหรับ Analytics

## 🔗 ลิงก์อ้างอิง

- [Microsoft Documentation: Columnstore Indexes](https://docs.microsoft.com/en-us/sql/relational-databases/indexes/columnstore-indexes-overview)
- [Columnstore Performance Tuning](https://docs.microsoft.com/en-us/sql/relational-databases/indexes/columnstore-index-performance)
- [SQL Server 2022 Columnstore Enhancements](https://docs.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2022)

## 📝 หมายเหตุ

- Columnstore Indexes มีใน SQL Server 2012+ (เริ่มเทียบเท่ากับ 2014+)
- ทดสอบบน AdventureWorks2022
- สำคัญ: Columnstore เหมาะสำหรับ Read-Heavy Workloads
- **Batch Mode** ต้องการข้อมูลจำนวนมากจึงจะได้ประโยชน์สูงสุด

---
**หมายเหตุ**: Columnstore Indexes เป็นเทคโนโลยีหลักสำหรับ Modern Data Warehousing


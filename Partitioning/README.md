# Table Partitioning

คู่มือการสอนเกี่ยวกับ Table Partitioning และ Index Partitioning ใน SQL Server

## 📖 บทนำ

Table Partitioning เป็นเทคนิคที่ช่วยแบ่งตารางขนาดใหญ่ออกเป็นส่วนๆ (Partitions) ตามเกณฑ์ที่กำหนด เช่น ตามวันที่หรือช่วงค่า Partitioning ช่วยเพิ่มประสิทธิภาพในหลายด้าน:
- ⚡ **Query Performance**: Query แค่ Partitions ที่เกี่ยวข้อง
- 🗑️ **Fast Data Loading**: เพิ่ม/ลบข้อมูลได้เร็วขึ้น
- 🔧 **Maintenance**: Rebuild Index แค่บาง Partitions
- 📊 **Scalability**: จัดการข้อมูลขนาดใหญ่ง่ายขึ้น

## ✨ คุณสมบัติหลัก

- 🎯 **Partition Function**: กำหนดเกณฑ์การแบ่ง
- 🔢 **Partition Scheme**: กำหนด Filegroup ที่เก็บแต่ละ Partition
- 📁 **Filegroup Management**: จัดการ Storage แยกกันตาม Partitions
- 🔄 **Partition Switching**: ย้ายข้อมูลระหว่างตารางได้เร็วมาก (Instant)

## 📋 ความต้องการของระบบ

- SQL Server 2016 หรือใหม่กว่า
- AdventureWorks2022 Database
- ตัวอย่างจะใช้ตาราง `Sales.SalesOrderHeader`

## 🗂️ เนื้อหาประกอบด้วย

### 01-create-partition-function-and-scheme.sql
- สร้าง Partition Function สำหรับแบ่งตามปี
- สร้าง Partition Scheme สำหรับกำหนด Filegroups
- ติดตั้ง Filegroups หลายไฟล์

### 02-create-partitioned-table.sql
- สร้างตารางแบบ Partitioned ตาม Partition Scheme
- ใช้ตาราง Sales.SalesOrderHeader เป็นต้นแบบ

### 03-partition-existing-table.sql
- แปลงตารางเดิมที่มีข้อมูลเป็น Partitioned Table
- ใช้ Partition Switching เพื่อย้ายข้อมูล

### 04-manage-partitions.sql
- เพิ่ม Partitions ใหม่
- ลบ/รวม Partitions เก่า
- Manage Boundary Values

### 05-partition-switching.sql
- สลับข้อมูลระหว่าง Partitions (Fast Load)
- ใช้ Staging Table สำหรับ Loading ข้อมูล
- Archive ข้อมูลเก่า

## 🎯 Use Cases

### 1. Date-Based Partitioning
แบ่งตามวันที่ เช่น ตามเดือนหรือปี
- ข้อมูล Sales โดยรายเดือน
- Transaction Logs ตามวัน
- Audit Data ตามปี

### 2. Range Partitioning
แบ่งตามช่วงค่า เช่น ID หรือ Categories
- ข้อมูลลูกค้าแบ่งตาม Region
- Products แบ่งตาม Category

### 3. Staging and Archival
ใช้ Partition Switching สำหรับ:
- Fast Loading ข้อมูลจาก Staging Table
- Archive ข้อมูลเก่าออกไปยังตาราง Archive

## ⚠️ ข้อควรระวัง

1. **Partition Key**: ต้องเป็นคอลัมน์ที่มีอยู่ใน Clustered Index
2. **Boundary Values**: ตอนแรกจะ Partition ใหม่เป็น LEFT/RIGHT-bound
3. **Filegroup**: ต้องเตรียม Filegroups เพียงพอ
4. **Maintenance**: Plan สำหรับการจัดการ Partitions เก่า
5. **Query Optimization**: ใช้ WHERE Clause ให้ตรงกับ Partition Key

## 🔧 Best Practices

### 1. การเลือก Partition Key
- ใช้คอลัมน์ที่ Query บ่อย
- Data Type น้อย (เช่น DATE แทน DATETIME2)
- Distributed ข้อมูลสม่ำเสมอ

### 2. จำนวน Partitions
- **แนะนำ**: 10-100 Partitions (ไม่เกิน 1000)
- Partition เล็กเกินไป = ไม่มีประโยชน์
- Partition ใหญ่เกินไป = จัดการยาก

### 3. Filegroups
- วาง Partitions เก่าและใหม่อยู่คนละ Filegroups
- ใช้ Filegroups แยกสำหรับ Archive
- Consider Compression

### 4. Maintenance Strategy
- Merge Partitions เก่าทุกไตรมาส
- Sliding Window Pattern สำหรับข้อมูลประจำ
- Archive ข้อมูลที่ > 2 ปี

## 📊 Sliding Window Pattern

รูปแบบที่ใช้สำหรับข้อมูลแบบ Time-Series:

```
[Oldest] ← [Older] ← [Old] ← [Current] ← [Future]
   ↓
 Archived  Merged   Active  Sliding
```

1. เพิ่ม Partition ใหม่สำหรับ Future
2. ลบ Partition เก่าสุด
3. Merge Partitions เก่าๆ เข้าด้วยกัน

## 🔗 ลิงก์อ้างอิง

- [Microsoft Documentation: Partitioned Tables and Indexes](https://docs.microsoft.com/en-us/sql/relational-databases/partitions/partitioned-tables-and-indexes)
- [SQL Server Table Partitioning Tutorial](https://www.sqlshack.com/implementing-sql-server-table-partitioning/)
- [SQL Server 2022 Partitioning Enhancements](https://docs.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2022)

## 📝 หมายเหตุ

- ตัวอย่างทั้งหมดใช้ AdventureWorks2022 Database
- ทุกโค้ดทดสอบแล้วกับ SQL Server 2016 - 2022
- แนะนำให้รันทีละขั้นตอนและศึกษา Output
- **สำคัญ**: ต้อง Backup Database ก่อนรัน Scripts ที่เปลี่ยนโครงสร้าง

---
**หมายเหตุ**: Partitioning เป็นเทคนิคขั้นสูง ควรทำความเข้าใจให้ดีก่อนนำไปใช้ใน Production


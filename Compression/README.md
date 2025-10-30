# Data Compression

คู่มือการสอนเกี่ยวกับการบีบอัดข้อมูลใน SQL Server (Row, Page, Columnstore Archive Compression)

## 📖 บทนำ

Data Compression เป็นเทคนิคช่วยลดขนาดข้อมูลและเพิ่มประสิทธิภาพการ Query โดย:
- 💾 **Space Savings**: ลดขนาด database ได้ 30-70%
- ⚡ **Query Performance**: อ่านข้อมูลน้อยลง = เร็วขึ้น
- 💰 **Cost Savings**: ประหยัด Storage Costs
- 📊 **IO Reduction**: ลด Disk I/O ได้มาก

**Trade-off**: ใช้ CPU เพิ่มขึ้นเล็กน้อย

## 🎯 ประเภทการบีบอัด

### 1. Row Compression (SQL Server 2008+)
- บีบอัดแบบแถว
- เหมาะสำหรับ OLTP
- ใช้ CPU น้อย
- บีบอัดได้ 20-30%

### 2. Page Compression (SQL Server 2008+)
- บีบอัดแบบหน้าหน้า
- เหมาะสำหรับ Read-Heavy
- ใช้ CPU มากกว่า
- บีบอัดได้ 40-60%
- รวม Row Compression + Prefix + Dictionary Compression

### 3. Columnstore Compression (SQL Server 2012+)
- บีบอัดแบบ Column
- เหมาะสำหรับ Analytics
- บีบอัดสูงมาก 10:1 ขึ้นไป
- ดูรายละเอียดใน Columnstore Indexes

### 4. Columnstore Archive Compression (SQL Server 2014+)
- บีบอัดแบบ Column + Archive
- เหมาะสำหรับข้อมูลเก่าที่ไม่ Query บ่อย
- บีบอัดสูงสุด 100:1
- Query ช้ากว่า Columnstore ปกติ

## 📋 ความต้องการของระบบ

- SQL Server 2008 หรือใหม่กว่า
- AdventureWorks2022 Database
- เหมาะสำหรับตารางขนาดใหญ่

## 🗂️ เนื้อหาประกอบด้วย

### 01-row-and-page-compression.sql
- การบีบอัด Row vs Page
- เปรียบเทียบผลลัพธ์
- ใช้กับ Nonclustered Indexes

### 02-columnstore-archive-compression.sql
- Archive Compression สำหรับ Columnstore
- การ Switching Columns สำหรับ Archive

### 03-compression-management.sql
- การจัดการ Compression แบบ Dynamic
- แปลงตารางเดิมเป็น Compressed
- Monitoring และ Performance

## ⚠️ ข้อควรระวัง

1. **CPU Overhead**: ใช้ CPU เพิ่มขึ้น (5-10%)
2. **Memory Usage**: ใช้ Memory เพิ่มขึ้นเล็กน้อย
3. **Tempdb**: ต้องการ Tempdb สำหรับ Rebuild
4. **Index Maintenance**: Rebuild ใช้เวลาเพิ่มขึ้น
5. **Backup/Restore**: Backup ไฟล์เล็กลง แต่ใช้เวลาเพิ่มขึ้น

## 🔧 Best Practices

### 1. เมื่อควรใช้ Row Compression
✅ Tables/Indexes ทุกแบบ
✅ OLTP Workloads
✅ CPU Limited Systems
✅ Tables ที่มีค่าซ้ำเยอะ

### 2. เมื่อควรใช้ Page Compression
✅ Read-Heavy Workloads
✅ Staging/Archive Tables
✅ Tables ที่มีข้อมูลซ้ำกัน (prefix/dictionary)
✅ Storage สำคัญกว่า CPU

### 3. เมื่อควรใช้ Columnstore Archive
✅ Historical Data (> 2 ปี)
✅ Rarely Queried Data
✅ Storage ลดได้มาก
✅ CPU Trade-off OK

### 4. ห้ามใช้ Compression
❌ Tables ที่มี DML บ่อยมาก
❌ CPU Constraints สูงมาก
❌ Tables ที่บีบอัดไม่ได้ผล (Unique Data)

## 📊 การตัดสินใจ

```
Small Table (< 100K rows) → No Compression (ไม่คุ้ม)
Medium Table + OLTP → Row Compression
Large Table + Read-Heavy → Page Compression
Data Warehouse → Columnstore (Best)
Archive Data → Columnstore Archive
```

## 🔗 ลิงก์อ้างอิง

- [Microsoft Documentation: Data Compression](https://docs.microsoft.com/en-us/sql/relational-databases/data-compression/data-compression)
- [SQL Server Compression Strategies](https://docs.microsoft.com/en-us/sql/relational-databases/data-compression/data-compression-strategy-guide)
- [Performance Impact of Compression](https://docs.microsoft.com/en-us/sql/relational-databases/data-compression/data-compression)

## 📝 หมายเหตุ

- Compression เป็นฟีเจอร์ Standard Edition (2016 SP1+)
- Partition Level Compression ใช้ได้
- ทดสอบก่อนใช้ใน Production
- Monitor CPU หลัง Enable Compression

---
**หมายเหตุ**: Compression เป็นฟีเจอร์ที่มีประโยชน์สูง แนะนำให้ใช้เมื่อเหมาะสม


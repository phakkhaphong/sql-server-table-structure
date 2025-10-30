# SQL Server Table Structure & Indexes Guide

คู่มือการสอนเกี่ยวกับโครงสร้างตารางและ Indexes ที่สำคัญใน SQL Server 2022 พร้อมตัวอย่างปฏิบัติจริง

## 📚 เนื้อหาประกอบด้วย

### 1. [Temporal Tables](./Temporal-Table/)
ระบบ Temporal Tables สำหรับติดตามประวัติการเปลี่ยนแปลงข้อมูลอัตโนมัติ
- ✅ สร้าง Temporal Table ใหม่
- ✅ แปลงตารางเดิมเป็น Temporal Table  
- ✅ การใช้งานและ Query รูปแบบต่างๆ
- ✅ การปิดใช้งาน Temporal Table

### 2. [Partitioning](./Partitioning/)
การแบ่งพาร์ติชันตารางขนาดใหญ่เพื่อเพิ่มประสิทธิภาพ
- ✅ Table Partitioning
- ✅ Index Partitioning
- ✅ การจัดการพาร์ติชัน

### 3. [Columnstore Indexes](./Columnstore-Indexes/)
Columnstore Indexes สำหรับ Data Warehousing และ Analytics
- ✅ Clustered Columnstore Index
- ✅ Nonclustered Columnstore Index
- ✅ การปรับปรุงและ Maintenance

### 4. [Compression](./Compression/)
เทคนิคการบีบอัดข้อมูลเพื่อลดขนาดและเพิ่มประสิทธิภาพ
- ✅ Row Compression
- ✅ Page Compression
- ✅ Columnstore Archive Compression

### 5. [Indexed Views](./Indexed-Views/)
การสร้างและใช้งาน Indexed Views เพื่อปรับปรุงประสิทธิภาพ Query
- ✅ สร้าง Indexed View
- ✅ การใช้งานและข้อจำกัด
- ✅ Best Practices

### 6. [In-Memory OLTP](./In-Memory-OLTP/)
Memory-Optimized Tables สำหรับ High-Performance OLTP
- ✅ สร้าง Memory-Optimized Tables
- ✅ Hash Indexes และ Range Indexes
- ✅ Natively Compiled Procedures
- ✅ Optimization และ Monitoring

### 7. [Table Design Best Practices](./Table-Design-Best-Practices/)
หลักการออกแบบตารางที่ดีตาม Best Practices
- ✅ Naming Conventions
- ✅ Data Types Selection
- ✅ Primary Keys และ Foreign Keys
- ✅ Indexing Strategies

## 🎯 คุณสมบัติสำคัญ

- 📖 ครอบคลุม SQL Server 2016 ถึง SQL Server 2022
- 🎓 ใช้ AdventureWorks2022 เป็นฐานข้อมูลตัวอย่าง
- 💡 ตัวอย่างโค้ดพร้อมคำอธิบายภาษาไทย
- ✅ ปฏิบัติตาม Best Practices อย่างเคร่งครัด
- 📁 แยกเป็นโฟลเดอร์ตามหัวข้ออย่างชัดเจน

## 🚀 วิธีการใช้งาน

1. **ดาวน์โหลดและติดตั้ง AdventureWorks2022**
   ```sql
   -- ดาวน์โหลดจาก Microsoft SQL Server Samples
   -- https://github.com/Microsoft/sql-server-samples/releases
   ```

2. **รัน Scripts ตามลำดับในแต่ละโฟลเดอร์**
   - เริ่มจากไฟล์แรกเสมอ (01-*.sql)
   - ปฏิบัติตามคำแนะนำในแต่ละไฟล์

3. **ศึกษา README.md ในแต่ละโฟลเดอร์**
   - อ่านข้อเสนอแนะและ Best Practices
   - ทำความเข้าใจข้อควรระวัง

## 📋 ข้อกำหนดเบื้องต้น

- SQL Server 2014 หรือใหม่กว่า (บาง Features ต้องการ 2016+)
- AdventureWorks2022 Database
- SQL Server Management Studio (SSMS) หรือ Azure Data Studio
- ความรู้พื้นฐานเกี่ยวกับ T-SQL
- Enterprise/Developer Edition สำหรับ In-Memory OLTP (Standard Edition 2016 SP1+ จำกัด)

## 🤝 การมีส่วนร่วม

ยินดีรับการมีส่วนร่วม! กรุณา:
- Fork โปรเจค
- สร้าง Feature Branch (`git checkout -b feature/AmazingFeature`)
- Commit การเปลี่ยนแปลง (`git commit -m 'Add some AmazingFeature'`)
- Push to Branch (`git push origin feature/AmazingFeature`)
- เปิด Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👤 ผู้เขียน

สร้างด้วยใจโดยนักพัฒนา SQL Server

## 🙏 Acknowledgement

- Microsoft SQL Server Documentation
- AdventureWorks Sample Database
- SQL Server Community

---
⭐ ถ้าคู่มือนี้มีประโยชน์ อย่าลืมให้ Star ด้วยนะครับ!


# In-Memory OLTP

คู่มือการสอนเกี่ยวกับ In-Memory OLTP (Memory-Optimized Tables) ใน SQL Server

## 📖 บทนำ

In-Memory OLTP เป็นเทคโนโลยีสำหรับเพิ่มประสิทธิภาพการทำงานของ OLTP Workloads ที่มีข้อจำกัดด้านการ Lock และ Latch โดยใช้:
- 💾 **Memory-Optimized Tables**: เก็บข้อมูลใน Memory
- ⚡ **High Performance**: เร็วกว่า Disk-based Tables มาก (5-100x)
- 🔓 **Lock-Free**: ไม่มี Lock Contention
- 📝 **Durability**: สามารถเลือก Durability Level

## ✨ คุณสมบัติหลัก

### Memory-Optimized Tables
- เก็บข้อมูลใน Memory หลัก (RAM)
- Native Compilation ให้ประสิทธิภาพสูง
- ไม่มี Lock และ Latch
- Row Versioning สำหรับ Concurrency

### Hash Indexes
- เหมาะสำหรับ Point Lookups เท่าเทียมกัน
- Bucket Count ต้องเหมาะสม
- Fast Lookups: O(1)

### Range Indexes
- เหมาะสำหรับ Range Queries
- B-tree แบบจำลอง
- Fast Scans: O(log n)

### Natively Compiled Stored Procedures
- Compile เป็น Machine Code
- ประสิทธิภาพสูงสุดสำหรับ Hot Paths
- เหมาะสำหรับ Workloads ที่ทำซ้ำมาก

## 📋 ความต้องการของระบบ

- SQL Server 2014 หรือใหม่กว่า (แนะนำ 2016+)
- Enterprise/Developer Edition (Standard Edition 2016 SP1+)
- AdventureWorks2022 Database
- RAM เพียงพอสำหรับ In-Memory Data

## 🗂️ เนื้อหาประกอบด้วย

### 01-create-memory-optimized-table.sql
สร้าง Memory-Optimized Table พื้นฐาน
- Hash Indexes
- Range Indexes
- Durability Options

### 02-natively-compiled-procedures.sql
สร้าง Natively Compiled Stored Procedures
- Syntax พิเศษ
- Performance Optimization
- Best Practices

### 03-optimization-and-monitoring.sql
เทคนิคการเพิ่มประสิทธิภาพและการ Monitor
- Performance Tuning
- Monitoring Memory Usage
- Troubleshooting

## ⚠️ ข้อควรระวัง

1. **Memory**: ต้องการ RAM เพียงพอ (จำกัดโดย max_server_memory)
2. **Durability**: SCHEMA_ONLY = ไม่มี Durability
3. **Migration**: Migration จาก Disk-based Tables ต้องระวัง
4. **Indexes**: Hash Indexes ต้องการ EQUAL Predicates เท่านั้น
5. **Cross-Database**: จำกัดการใช้งาน Cross-Database Queries

## 🔧 Best Practices

### 1. เหมาะสำหรับ
✅ Hot Data (High-Frequency Access)
✅ Lock Contention Issues
✅ Short Transactions
✅ Point Lookups (Hash Indexes)
✅ Workloads ที่ต้องเร็วมาก

### 2. ไม่เหมาะสำหรับ
❌ Large Memory Tables (> 100GB)
❌ Cold Data (Access น้อย)
❌ Complex Queries
❌ Cross-Database Queries

### 3. Index Design
- Hash Indexes: Point Lookups (WHERE Key = value)
- Range Indexes: Range Queries, Ordering
- Bucket Count: 1-2x Expected Row Count

### 4. Durability
- **SCHEMA_AND_DATA**: Full Durability (แนะนำ Production)
- **SCHEMA_ONLY**: No Durability (Staging/Temp)

## 📊 When to Use In-Memory OLTP

```
❓ Performance Bottleneck?
   ├─ YES → ❓ Lock/Latch Contention?
   │   ├─ YES → ✅ In-Memory OLTP
   │   └─ NO → ❓ High-Frequency Point Queries?
   │       ├─ YES → ✅ In-Memory OLTP
   │       └─ NO → Optimize Indexes/Queries
   └─ NO → Not Needed
```

## 🔗 ลิงก์อ้างอิง

- [Microsoft Documentation: In-Memory OLTP](https://docs.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/in-memory-oltp-in-memory-optimization)
- [Memory-Optimized Tables](https://docs.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/sample-database-for-in-memory-oltp)
- [SQL Server 2022 In-Memory Enhancements](https://docs.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2022)

## 📝 หมายเหตุ

- In-Memory OLTP ใช้ได้ฟรีใน SQL Server 2014+ Enterprise Edition
- Standard Edition 2016 SP1+: Limited (32GB memory per database)
- ทดสอบใน Development ก่อน Production
- Monitor Memory Usage อย่างระมัดระวัง

---
**หมายเหตุ**: In-Memory OLTP เปลี่ยนโฉมการทำงานของ OLTP แต่ต้องใช้อย่างเหมาะสม


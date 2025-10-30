# Table Design Best Practices

คู่มือการสอนเกี่ยวกับการออกแบบตารางที่ดีตาม Best Practices

## 📖 บทนำ

การออกแบบตารางที่ดีเป็นพื้นฐานสำคัญของ Database ที่มีประสิทธิภาพ ครอบคลุม:
- 🎯 **Naming Conventions**: ชื่อที่สื่อความหมายและสอดคล้อง
- 📊 **Data Types**: เลือกประเภทข้อมูลที่เหมาะสม
- 🔑 **Keys**: Primary Keys และ Foreign Keys
- 🔍 **Indexes**: Indexing Strategies

## 📚 เนื้อหาประกอบด้วย

### 01-naming-conventions.sql
- Naming Standards สำหรับ Tables, Columns, Indexes
- Prefixes และ Suffixes
- Schema Organization

### 02-data-types-selection.sql
- การเลือก Data Types ที่เหมาะสม
- Storage Optimization
- Best Practices สำหรับแต่ละ Data Type

### 03-keys-and-constraints.sql
- Primary Keys Design
- Foreign Keys และ Referential Integrity
- Check Constraints และ Default Values

### 04-indexing-strategies.sql
- Clustered Index Selection
- Nonclustered Indexes
- Covering Indexes และ INCLUDE

## 🔧 Best Practices

### Naming Conventions
✅ ใช้ PascalCase หรือ snake_case สม่ำเสมอ
✅ ชื่อสื่อความหมาย
✅ หลีกเลี่ยง Reserved Words
✅ ใช้ Prefix/Suffix อย่างต่อเนื่อง

### Data Types
✅ เลือกให้เหมาะสมกับข้อมูล
✅ หลีกเลี่ยงการใหญ่เกินไป
✅ ใช้ UNIQUEIDENTIFIER อย่างระมัดระวัง
✅ ใช้ DECIMAL เมื่อต้องการความแม่นยำ

### Keys
✅ Primary Key ทุกตาราง
✅ Foreign Keys สำหรับ Relationships
✅ Composite Keys เมื่อเหมาะสม
✅ Avoid Surrogate Keys เมื่อไม่จำเป็น

### Indexes
✅ Clustered Index บน Primary Key
✅ Nonclustered Indexes สำหรับ Query Patterns
✅ Covering Indexes เมื่อเหมาะสม
✅ Monitor และ Tune เป็นประจำ

## 🔗 ลิงก์อ้างอิง

- [Microsoft Documentation: Tables](https://docs.microsoft.com/en-us/sql/relational-databases/tables/tables)
- [Data Types and Best Practices](https://docs.microsoft.com/en-us/sql/t-sql/data-types/data-types-transact-sql)
- [Index Design Guidelines](https://docs.microsoft.com/en-us/sql/relational-databases/indexes/index-design-guidelines)


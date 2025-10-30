# วิธีนำขึ้น GitHub

## ขั้นตอนการ Push ขึ้น GitHub

### 1. สร้าง Repository บน GitHub

1. เข้าสู่ GitHub (https://github.com)
2. คลิก **New repository**
3. ตั้งค่า:
   - **Repository name**: `sql-server-table-structure-guide`
   - **Description**: `คู่มือการสอนเกี่ยวกับโครงสร้างตารางและ Indexes ที่สำคัญใน SQL Server 2022`
   - เลือก **Public** (หรือ Private ตามต้องการ)
   - **ไม่ต้อง**ใส่ checkmarks (README, .gitignore, license เพราะเรามีแล้ว)
4. คลิก **Create repository**

### 2. เพิ่ม Remote และ Push

ใน Command Prompt/Terminal:

```bash
# เพิ่ม GitHub Remote (แทน YOUR_USERNAME ด้วย username จริง)
git remote add origin https://github.com/YOUR_USERNAME/sql-server-table-structure-guide.git

# หรือใช้ SSH (ถ้ามี SSH keys ตั้งค่าแล้ว)
# git remote add origin git@github.com:YOUR_USERNAME/sql-server-table-structure-guide.git

# Push ขึ้น GitHub
git push -u origin main
```

### 3. ตรวจสอบผลลัพธ์

เข้าไปดูที่: `https://github.com/YOUR_USERNAME/sql-server-table-structure-guide`

## โครงสร้างที่ได้

```
sql-server-table-structure-guide/
├── 📄 README.md (หลัก)
├── 📄 LICENSE (MIT License)
├── 📁 Temporal-Table/ (4 scripts)
├── 📁 Partitioning/ (5 scripts)
├── 📁 Columnstore-Indexes/ (3 scripts)
├── 📁 Compression/ (3 scripts)
├── 📁 Indexed-Views/ (3 scripts)
├── 📁 In-Memory-OLTP/ (3 scripts)
└── 📁 Table-Design-Best-Practices/ (4 scripts)
```

## สรุป

✅ **35 ไฟล์** พร้อมใช้งาน
- 25 SQL Scripts
- 8 README.md files
- 1 LICENSE
- 1 .gitignore

พร้อมแบ่งปันสู่ชุมชน! 🎉


-- =============================================
-- Script: 03-optimization-and-monitoring.sql
-- Description: Optimization และ Monitoring In-Memory OLTP
-- Database: AdventureWorks2022
-- Server: SQL Server 2014 ขึ้นไป
-- Author: SQL Server Best Practices Guide
-- Date: 2024
-- =============================================
-- Prerequisite: ต้องรัน 01 และ 02 ก่อน
-- =============================================

USE AdventureWorks2022;
GO

-- === In-Memory OLTP Optimization & Monitoring ===

GO

-- =============================================
-- ส่วนที่ 1: Monitoring Memory Usage
-- =============================================

-- === ส่วนที่ 1: Monitoring Memory Usage ===


-- 1.1 ตรวจสอบ Memory Usage ของ Tables
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    memory_allocated_for_table_kb / 1024.0 AS TableMemoryMB,
    memory_allocated_for_indexes_kb / 1024.0 AS IndexMemoryMB,
    memory_allocated_for_table_kb / 1024.0 / 1024.0 AS TableMemoryGB,
    memory_used_by_table_kb / 1024.0 AS TableMemoryUsedMB,
    memory_used_by_indexes_kb / 1024.0 AS IndexMemoryUsedMB
FROM sys.dm_db_xtp_table_memory_stats
ORDER BY memory_allocated_for_table_kb DESC;
GO

-- 1.2 ตรวจสอบ Memory Usage ของ Database
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    total_allocated_space_kb / 1024.0 AS TotalMemoryMB,
    total_allocated_space_kb / 1024.0 / 1024.0 AS TotalMemoryGB,
    total_used_space_kb / 1024.0 AS UsedMemoryMB
FROM sys.dm_db_xtp_database_memory_stats
WHERE database_id = DB_ID();
GO

-- 1.3 ตรวจสอบ Hash Index Statistics
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS IndexName,
    total_bucket_count AS BucketCount,
    empty_bucket_count AS EmptyBuckets,
    avg_chain_length AS AvgChainLength,
    max_chain_length AS MaxChainLength,
    CASE 
        WHEN total_bucket_count > 0 
        THEN (empty_bucket_count * 100.0 / total_bucket_count)
        ELSE 0
    END AS PercentEmpty,
    CASE 
        WHEN avg_chain_length > 5 THEN 'Consider More Buckets'
        WHEN avg_chain_length < 0.5 THEN 'Too Many Buckets'
        ELSE 'OK'
    END AS Recommendation
FROM sys.dm_db_xtp_hash_index_stats
ORDER BY avg_chain_length DESC;
GO

-- =============================================
-- ส่วนที่ 2: Bucket Count Optimization
-- =============================================


-- === ส่วนที่ 2: Bucket Count Optimization ===


-- ตรวจสอบ Bucket Count ที่เหมาะสม
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS IndexName,
    total_bucket_count AS CurrentBuckets,
    total_bucket_count * 2 AS SuggestedBuckets,
    'ALTER INDEX ' + name + ' ON ' + OBJECT_NAME(object_id) + 
    ' REBUILD WITH (BUCKET_COUNT = ' + 
    CAST(total_bucket_count * 2 AS VARCHAR) + ');' AS AlterStatement
FROM sys.dm_db_xtp_hash_index_stats
WHERE avg_chain_length > 5;
GO


-- คำแนะนำ:
--   - Bucket Count ควรเป็น 1-2x ของจำนวนแถว
--   - ถ้า Chain Length > 5: เพิ่ม Bucket Count
--   - ถ้า Chain Length < 0.5: ลด Bucket Count


-- =============================================
-- ส่วนที่ 3: Garbage Collection
-- =============================================


-- === ส่วนที่ 3: Garbage Collection ===


-- ตรวจสอบ Garbage Collection Status
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    COUNT(*) AS GCQueueCount,
    MIN(creation_timestamp) AS OldestQueueItem,
    MAX(creation_timestamp) AS NewestQueueItem
FROM sys.dm_xtp_gc_queue_stats
WHERE database_id = DB_ID()
GROUP BY database_id;
GO

-- ตรวจสอบ Memory Cleanup
SELECT 
    database_id,
    cleanup_kb / 1024.0 AS CleanupMB,
    avg_log_bytes / 1024.0 AS AvgLogMB,
    object_delete_count AS DeleteCount,
    object_update_count AS UpdateCount
FROM sys.dm_xtp_gc_stats
WHERE database_id = DB_ID();
GO

-- =============================================
-- ส่วนที่ 4: Transaction Statistics
-- =============================================


-- === ส่วนที่ 4: Transaction Statistics ===


-- ตรวจสอบ Transaction Stats
SELECT 
    OBJECT_NAME(table_id) AS TableName,
    scan_count AS ScanCount,
    delete_count AS DeleteCount,
    update_count AS UpdateCount,
    insert_count AS InsertCount,
    schema_insert_count AS SchemaInsertCount,
    schema_update_count AS SchemaUpdateCount
FROM sys.dm_db_xtp_object_stats
WHERE table_id = OBJECT_ID('dbo.ShoppingCart_Memory');
GO

-- =============================================
-- ส่วนที่ 5: Memory Optimization Tips
-- =============================================



-- === ส่วนที่ 5: Memory Optimization Tips ===


-- ตรวจสอบ Row Count vs Memory Size
SELECT 
    OBJECT_NAME(t.object_id) AS TableName,
    t.memory_allocated_for_table_kb / 1024.0 AS MemoryMB,
    p.row_count AS RowCount,
    CASE 
        WHEN p.row_count > 0 
        THEN t.memory_allocated_for_table_kb * 1.0 / p.row_count
        ELSE 0
    END AS BytesPerRow,
    CASE 
        WHEN t.memory_allocated_for_table_kb * 1.0 / p.row_count > 1024 THEN 'Large Rows'
        WHEN t.memory_allocated_for_table_kb * 1.0 / p.row_count < 100 THEN 'Small Rows'
        ELSE 'Normal'
    END AS RowSizeComment
FROM sys.dm_db_xtp_table_memory_stats t
INNER JOIN sys.dm_db_partition_stats p 
    ON t.object_id = p.object_id 
    AND p.index_id IN (0,1)
WHERE p.row_count > 0
ORDER BY t.memory_allocated_for_table_kb DESC;
GO

-- =============================================
-- ส่วนที่ 6: Troubleshooting Common Issues
-- =============================================



-- === ส่วนที่ 6: Troubleshooting Common Issues ===


-- Issue 1: Low Memory
-- Issue 1: Low Memory
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    total_allocated_space_kb / 1024.0 / 1024.0 AS AllocatedGB,
    total_used_space_kb / 1024.0 / 1024.0 AS UsedGB
FROM sys.dm_db_xtp_database_memory_stats
WHERE database_id = DB_ID();
GO

-- Issue 2: Long Garbage Collection

-- Issue 2: Garbage Collection Status
SELECT 
    COUNT(*) AS GCQueueItems,
    DATEDIFF(SECOND, MIN(creation_timestamp), SYSDATETIME()) AS OldestItemAgeSeconds
FROM sys.dm_xtp_gc_queue_stats
WHERE database_id = DB_ID();
GO

-- Issue 3: Hash Index Chain Length

-- Issue 3: Hash Index Performance
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS IndexName,
    avg_chain_length AS AvgChain,
    max_chain_length AS MaxChain,
    CASE 
        WHEN avg_chain_length > 10 THEN 'Poor - Need More Buckets'
        WHEN avg_chain_length > 5 THEN 'Fair - Consider More Buckets'
        ELSE 'Good'
    END AS PerformanceRating
FROM sys.dm_db_xtp_hash_index_stats
ORDER BY avg_chain_length DESC;
GO

-- =============================================
-- Best Practices Summary
-- =============================================



-- === Best Practices Summary ===

-- 1. Memory Management:
--    - Monitor Memory Usage เป็นประจำ
--    - Set max_server_memory อย่างเหมาะสม
--    - Plan for 2x Current Memory (Growth)

-- 2. Bucket Count:
--    - Start: 1x Expected Rows
--    - Ideal: 1.5-2x Expected Rows
--    - Monitor avg_chain_length
--    - Rebuild Index เมื่อจำเป็น

-- 3. Performance Monitoring:
--    - Use DMVs เป็นประจำ
--    - Track Transaction Rates
--    - Monitor GC Activity
--    - Watch for Memory Pressure

-- 4. Troubleshooting:
--    - Low Memory → Check max_server_memory
--    - Long GC → Check Transaction Rates
--    - Slow Queries → Check Bucket Count
--    - Memory Leak → Check Table Growth
GO


-- สำเร็จ! จบการสาธิต Optimization & Monitoring
GO


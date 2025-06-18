-- ====================================================================
-- Paimon Quick Start Test Script
-- 完整的 Paimon 快速测试脚本
-- ====================================================================
-- 
-- How to use | 使用方法:
-- 1. docker exec -it jobmanager bash
-- 2. ./bin/sql-client.sh
-- 3. Copy and paste the SQL below | 复制粘贴下面的 SQL
--
-- ====================================================================

-- Step 1: Create Paimon Catalog | 第1步：创建 Paimon 目录
CREATE CATALOG my_catalog WITH (
  'type' = 'paimon',
  'warehouse' = 'file:/warehouse'
);

-- Step 2: Switch to Paimon Catalog | 第2步：切换到 Paimon 目录
USE CATALOG my_catalog;

-- Step 3: Create Main Table with Primary Key | 第3步：创建带主键的主表
-- Note: PRIMARY KEY NOT ENFORCED supports deduplication but not mandatory
-- 注：PRIMARY KEY NOT ENFORCED 表示支持去重但不强制
CREATE TABLE word_count (
  word STRING PRIMARY KEY NOT ENFORCED,
  cnt BIGINT
);

-- Step 4: Create Data Source Table | 第4步：创建数据源表
-- Using Flink's built-in datagen connector for testing
-- 使用 Flink 内置的 datagen 数据生成器进行测试
CREATE TEMPORARY TABLE word_table (
  word STRING
) WITH (
  'connector' = 'datagen',
  'fields.word.length' = '1'  -- Generates: a, b, c, d, e...
);

-- Step 5: Enable Checkpointing | 第5步：启用检查点
SET 'execution.checkpointing.interval' = '10 s';

-- Step 6: Start Streaming Job | 第6步：启动流式作业
-- This will run continuously, generating real-time aggregated data
-- 这将持续运行，生成实时聚合数据
INSERT INTO word_count
SELECT word, COUNT(*) FROM word_table GROUP BY word;

-- ====================================================================
-- IMPORTANT: The INSERT job above will run continuously!
-- 重要：上面的 INSERT 作业会持续运行！
--
-- In a SECOND terminal session, run:
-- 在第二个终端会话中运行：
-- docker exec -it jobmanager ./bin/sql-client.sh
--
-- Then execute the queries below:
-- 然后执行下面的查询：
-- ====================================================================

-- Query 1: Real-time Results (Stream Mode) | 查询1：实时结果（流模式）
-- USE CATALOG my_catalog;
-- SELECT * FROM word_count;
-- -- You should see counts continuously increasing
-- -- 您应该看到计数持续增加

-- Query 2: Switch to Batch Mode | 查询2：切换到批模式
-- SET 'sql-client.execution.result-mode' = 'tableau';
-- RESET 'execution.checkpointing.interval';
-- SET 'execution.runtime-mode' = 'batch';
-- SELECT * FROM word_count ORDER BY cnt DESC LIMIT 5;
-- -- This shows a static snapshot, won't auto-refresh
-- -- 这显示一个静态快照，不会自动刷新

-- ====================================================================
-- Advanced Example: Business Orders Table | 高级示例：业务订单表
-- ====================================================================

-- Create business table | 创建业务表
CREATE TABLE orders (
  order_id BIGINT,
  user_id BIGINT,
  product_id BIGINT,
  order_time TIMESTAMP(3),
  amount DECIMAL(10,2),
  PRIMARY KEY (order_id) NOT ENFORCED
) WITH ('bucket' = '4');

-- Insert sample data | 插入示例数据
INSERT INTO orders VALUES
(1001, 101, 201, TIMESTAMP '2024-01-15 10:30:00', 99.99),
(1002, 102, 202, TIMESTAMP '2024-01-15 11:15:00', 149.50),
(1003, 101, 203, TIMESTAMP '2024-01-15 12:00:00', 79.99),
(1004, 103, 201, TIMESTAMP '2024-01-15 13:45:00', 199.99),
(1005, 102, 204, TIMESTAMP '2024-01-15 14:30:00', 299.99);

-- Query orders data | 查询订单数据
SELECT * FROM orders;

-- Analytics query | 分析查询
SELECT 
  user_id,
  COUNT(*) as order_count,
  SUM(amount) as total_amount,
  AVG(amount) as avg_amount
FROM orders 
GROUP BY user_id
ORDER BY total_amount DESC;

-- ====================================================================
-- Cleanup (Optional) | 清理（可选）
-- ====================================================================

-- Stop the streaming job first in Flink Web UI (http://localhost:8081)
-- 首先在 Flink Web UI 中停止流式作业 (http://localhost:8081)

-- Then drop tables | 然后删除表
-- DROP TABLE word_count;
-- DROP TABLE orders;

-- Exit SQL Client | 退出 SQL 客户端
-- QUIT;

-- ====================================================================
-- Expected Results | 预期结果:
-- 
-- 1. word_count table shows increasing counts for letters a, b, c, d, e
--    word_count 表显示字母 a, b, c, d, e 的递增计数
--
-- 2. Flink Web UI shows running streaming job
--    Flink Web UI 显示正在运行的流式作业
--
-- 3. Batch queries show static snapshots
--    批查询显示静态快照
--
-- 4. orders table shows business data with analytics
--    orders 表显示带分析功能的业务数据
-- ==================================================================== 
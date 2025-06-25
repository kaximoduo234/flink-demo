-- ====================================================================
-- Flink Catalog 初始化脚本
-- 用途：容器启动时自动配置所有catalog，避免每次手动执行
-- 执行方式：通过 init_catalogs.sh 自动调用
-- ====================================================================

-- 🔧 Flink执行环境配置
SET 'execution.checkpointing.interval' = '30s';
SET 'execution.checkpointing.mode' = 'EXACTLY_ONCE';
SET 'execution.runtime-mode' = 'streaming';
SET 'parallelism.default' = '1';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '1s';
SET 'table.exec.mini-batch.size' = '1000';
-- ✅ Paimon sink 必需配置
SET 'table.exec.sink.upsert-materialize' = 'NONE';

-- ====================================================================
-- 📁 创建 Paimon Catalog（数据湖存储）
-- ====================================================================
CREATE CATALOG IF NOT EXISTS paimon_catalog WITH (
    'type' = 'paimon', 
    'warehouse' = 'file:/warehouse'
);

-- 验证 catalog 创建成功
SHOW CATALOGS;

-- 切换到 paimon catalog
USE CATALOG paimon_catalog;

-- 验证现有数据库
SHOW DATABASES;

-- ====================================================================
-- 📊 检查现有表（如果存在）
-- ====================================================================

-- 检查 ODS 层表
USE ods;
SHOW TABLES;

-- 检查 DWD 层表  
USE dwd;
SHOW TABLES;

-- 检查默认数据库表
USE default;
SHOW TABLES;

-- ====================================================================
-- 🎯 输出初始化完成信息
-- ====================================================================
SELECT 
    'Paimon Catalog 初始化完成' as status,
    CURRENT_TIMESTAMP as init_time; 
-- ====================================================================
-- StreamPark 作业04：DWS层聚合分析 (DWD → StarRocks)
-- 描述：从DWD层读取明细数据，聚合计算后写入StarRocks进行多维分析
-- 依赖：Paimon DWD层、StarRocks
-- 更新时间：2025-06-21 (基于验证通过的SQL)
-- ====================================================================

-- 设置执行环境
SET 'execution.checkpointing.interval' = '30s';
SET 'execution.checkpointing.mode' = 'EXACTLY_ONCE';
SET 'execution.runtime-mode' = 'streaming';
SET 'parallelism.default' = '1';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '1s';
SET 'table.exec.mini-batch.size' = '1000';
-- Paimon sink 必需配置
SET 'table.exec.sink.upsert-materialize' = 'NONE';

-- ====================================================================
-- 创建 Paimon Catalog
-- ====================================================================

CREATE CATALOG paimon_catalog WITH (
    'type' = 'paimon', 
    'warehouse' = 'file:/warehouse'
);

-- ====================================================================
-- 源表定义：DWD层明细数据
-- ====================================================================

CREATE TABLE paimon_catalog.dwd.dwd_user (
    id BIGINT,
    name STRING,
    gender STRING,
    age INT,
    age_group STRING,
    email STRING,
    phone STRING,
    city STRING,
    register_time TIMESTAMP(3),
    update_time TIMESTAMP(3),
    is_active BOOLEAN,
    user_level STRING,
    last_behavior_time TIMESTAMP(3),
    data_quality_score DECIMAL(3,2),
    ts TIMESTAMP(3),
    etl_time TIMESTAMP(3),
    dt STRING,
    PRIMARY KEY (id) NOT ENFORCED
) PARTITIONED BY (dt) WITH (
    'bucket' = '-1',
    'changelog-producer' = 'input',
    'merge-engine' = 'deduplicate',
    'file.format' = 'parquet'
);

-- ====================================================================
-- 目标表定义：StarRocks DWS层
-- ====================================================================

-- 切换回默认 catalog
USE CATALOG default_catalog;
CREATE DATABASE IF NOT EXISTS dws COMMENT '汇总数据层';
USE dws;

-- StarRocks: 用户统计汇总表
CREATE TABLE starrocks_dws_user_stats (
    date_key DATE,
    gender STRING,
    age_group STRING,
    city STRING,
    user_level STRING,
    user_count BIGINT,
    new_user_count BIGINT,
    active_user_count BIGINT,
    avg_data_quality_score DECIMAL(5,2),
    latest_ts TIMESTAMP(3),
    PRIMARY KEY (date_key, gender, age_group, city, user_level) NOT ENFORCED
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://starrocks:9030',
    'load-url' = 'starrocks:8030;starrocks:8040',
    'database-name' = 'analytics',
    'table-name' = 'dws_user_stats',
    'username' = 'root',
    'password' = '',
    'sink.version' = 'V1',
    'sink.at-least-once.use-transaction-stream-load' = 'false',
    'sink.semantic' = 'at-least-once',
    'sink.buffer-flush.max-rows' = '64000',
    'sink.buffer-flush.interval-ms' = '5000',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);

-- ====================================================================
-- 聚合分析任务：DWD → StarRocks DWS
-- ====================================================================

INSERT INTO starrocks_dws_user_stats
SELECT
    CAST(dt AS DATE) as date_key,
    gender,
    age_group,
    city,
    user_level,
    COUNT(DISTINCT id) as user_count,
    COUNT(DISTINCT CASE WHEN user_level = '新用户' THEN id END) as new_user_count,
    COUNT(DISTINCT CASE WHEN is_active = true THEN id END) as active_user_count,
    ROUND(AVG(data_quality_score), 2) as avg_data_quality_score,
    MAX(ts) as latest_ts
FROM paimon_catalog.dwd.dwd_user
GROUP BY 
    CAST(dt AS DATE),
    gender,
    age_group,
    city,
    user_level; 
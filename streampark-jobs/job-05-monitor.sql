-- ====================================================================
-- StreamPark 作业05：数据质量监控
-- 描述：监控各层数据质量，记录数据统计指标和异常情况
-- 依赖：MySQL、Kafka、Paimon、StarRocks
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

-- ====================================================================
-- 创建 Paimon Catalog
-- ====================================================================

CREATE CATALOG paimon_catalog WITH (
    'type' = 'paimon', 
    'warehouse' = 'file:/warehouse'
);

-- ====================================================================
-- 监控源表定义
-- ====================================================================

-- ODS层监控
CREATE TABLE paimon_catalog.ods.ods_user_raw (
    id BIGINT,
    name STRING,
    gender STRING,
    age INT,
    email STRING,
    phone STRING,
    city STRING,
    register_time TIMESTAMP(3),
    update_time TIMESTAMP(3),
    cdc_ts TIMESTAMP(3),
    etl_time TIMESTAMP(3),
    dt STRING,
    PRIMARY KEY (id, dt) NOT ENFORCED
) PARTITIONED BY (dt) WITH (
    'bucket' = '4',
    'bucket-key' = 'id',
    'file.format' = 'parquet',
    'changelog-producer' = 'input',
    'merge-engine' = 'deduplicate',
    'compaction.max.file-num' = '50'
);

-- DWD层监控
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
-- 数据质量监控表
-- ====================================================================

USE CATALOG default_catalog;

CREATE TABLE data_quality_monitor (
    table_name STRING,
    check_time TIMESTAMP(3),
    total_records BIGINT,
    null_records BIGINT,
    duplicate_records BIGINT,
    data_quality_score DECIMAL(5,2),
    PRIMARY KEY (table_name, check_time) NOT ENFORCED
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:mysql://starrocks:9030/analytics',
    'table-name' = 'data_quality_monitor',
    'username' = 'root',
    'password' = ''
);

-- ====================================================================
-- 数据质量监控任务
-- ====================================================================

-- 监控ODS层数据质量
INSERT INTO data_quality_monitor
SELECT 
    'ods_user_raw' as table_name,
    CURRENT_TIMESTAMP as check_time,
    COUNT(*) as total_records,
    COUNT(CASE WHEN name IS NULL OR email IS NULL THEN 1 END) as null_records,
    COUNT(*) - COUNT(DISTINCT id) as duplicate_records,
    ROUND(
        CASE 
            WHEN COUNT(*) = 0 THEN 0 
            ELSE (COUNT(*) - COUNT(CASE WHEN name IS NULL OR email IS NULL THEN 1 END)) * 100.0 / COUNT(*) 
        END, 2
    ) as data_quality_score
FROM paimon_catalog.ods.ods_user_raw
WHERE dt = DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd');

-- 监控DWD层数据质量
INSERT INTO data_quality_monitor  
SELECT 
    'dwd_user' as table_name,
    CURRENT_TIMESTAMP as check_time,
    COUNT(*) as total_records,
    COUNT(CASE WHEN name IS NULL OR age IS NULL THEN 1 END) as null_records,
    COUNT(*) - COUNT(DISTINCT id) as duplicate_records,
    ROUND(AVG(data_quality_score), 2) as data_quality_score
FROM paimon_catalog.dwd.dwd_user
WHERE dt = DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd'); 
-- ====================================================================
-- StreamPark 作业03：DWD层数据转换 (ODS → DWD)
-- 描述：数据清洗加工，业务规则计算，构建明细层数据
-- 依赖：Paimon ODS层
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
-- 创建 Paimon Catalog 和数据库
-- ====================================================================

CREATE CATALOG paimon_catalog WITH (
    'type' = 'paimon', 
    'warehouse' = 'file:/warehouse'
);

USE CATALOG paimon_catalog;

-- 创建数据库分层
CREATE DATABASE IF NOT EXISTS ods COMMENT '原始数据层';
CREATE DATABASE IF NOT EXISTS dwd COMMENT '明细数据层';

-- ====================================================================
-- 源表定义：ODS层原始数据
-- ====================================================================

USE ods;

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

-- ====================================================================
-- 目标表定义：DWD层明细数据
-- ====================================================================

USE dwd;

DROP TABLE IF EXISTS paimon_catalog.dwd.dwd_user;

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
)
PARTITIONED BY (dt)
WITH (
    'bucket' = '-1',
    'changelog-producer' = 'input',
    'merge-engine' = 'deduplicate',
    'file.format' = 'parquet'
);

-- ====================================================================
-- 数据转换任务：ODS → DWD (含业务逻辑)
-- ====================================================================

INSERT INTO paimon_catalog.dwd.dwd_user
SELECT
    id,
    name,
    COALESCE(gender, '未知') AS gender,
    age,
    CASE 
        WHEN age < 18 THEN '00-17'
        WHEN age < 30 THEN '18-29'
        WHEN age < 40 THEN '30-39'
        WHEN age < 50 THEN '40-49'
        ELSE '50+'
    END AS age_group,
    email,
    phone,
    COALESCE(city, '未知') AS city,
    register_time,
    update_time,
    
    -- 业务规则计算
    TRUE AS is_active,
    '常规用户' AS user_level,
    
    update_time AS last_behavior_time,

    -- 数据质量评分
    1.0 AS data_quality_score,

    cdc_ts AS ts,
    CURRENT_TIMESTAMP AS etl_time,
    DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd') AS dt

FROM paimon_catalog.ods.ods_user_raw
WHERE update_time IS NOT NULL; 
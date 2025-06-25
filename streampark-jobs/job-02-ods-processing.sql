-- ====================================================================
-- StreamPark 作业02：ODS层数据处理 (Kafka → Paimon ODS)
-- 描述：从Kafka读取数据，写入Paimon ODS层，保留完整历史记录
-- 依赖：Kafka、Paimon
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

-- ====================================================================
-- 源表定义：Kafka数据流
-- ====================================================================

CREATE TABLE default_catalog.default_database.kafka_user_stream (
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
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'user_stream',
    'properties.bootstrap.servers' = 'kafka:9092',
    'key.format' = 'json',
    'value.format' = 'json',
    'value.fields-include' = 'ALL'
);

-- ====================================================================
-- 目标表定义：Paimon ODS层
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
    dt STRING,  -- 分区字段
    PRIMARY KEY (id, dt) NOT ENFORCED  -- 添加主键支持upsert
) PARTITIONED BY (dt) WITH (
    'bucket' = '4',
    'bucket-key' = 'id',
    'file.format' = 'parquet',
    'changelog-producer' = 'input',  -- 支持changelog模式
    'merge-engine' = 'deduplicate',  -- 支持去重合并
    'compaction.max.file-num' = '50'
);

-- ====================================================================
-- 数据写入任务：Kafka → ODS
-- ====================================================================

INSERT INTO ods.ods_user_raw
SELECT
    id,
    name,
    gender,
    age,
    email,
    phone,
    city,
    register_time,
    update_time,
    cdc_ts,
    CURRENT_TIMESTAMP as etl_time,
    DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd') as dt
FROM default_catalog.default_database.kafka_user_stream; 
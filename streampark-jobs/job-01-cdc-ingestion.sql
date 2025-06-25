-- ====================================================================
-- StreamPark 作业01：CDC数据采集 (MySQL → Kafka)
-- 描述：从MySQL捕获用户表变更数据，写入Kafka进行数据缓冲
-- 依赖：MySQL、Kafka
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
-- 源表定义：MySQL CDC
-- ====================================================================

CREATE TABLE mysql_user_cdc (
    id BIGINT,
    name STRING,
    gender STRING,
    age INT,
    email STRING,
    phone STRING,
    city STRING,
    register_time TIMESTAMP(3),
    update_time TIMESTAMP(3),
    ts TIMESTAMP(3),  -- MySQL 实体字段
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = 'mysql',
    'port' = '3306',
    'username' = 'root',
    'password' = 'root123',
    'database-name' = 'ods',
    'table-name' = 'user',
    'server-time-zone' = 'Asia/Shanghai',
    'scan.startup.mode' = 'initial',
    'scan.incremental.snapshot.enabled' = 'true',
    'debezium.snapshot.mode' = 'initial'
);

-- ====================================================================
-- 目标表定义：Kafka数据流
-- ====================================================================

CREATE TABLE kafka_user_stream (
    id BIGINT,
    name STRING,
    gender STRING,
    age INT,
    email STRING,
    phone STRING,
    city STRING,
    register_time TIMESTAMP(3),
    update_time TIMESTAMP(3),
    cdc_ts TIMESTAMP(3),  -- 从 ts 字段映射
    PRIMARY KEY (id) NOT ENFORCED  -- 自动作为 upsert key
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'user_stream',
    'properties.bootstrap.servers' = 'kafka:9092',
    'key.format' = 'json',
    'value.format' = 'json',
    'value.fields-include' = 'ALL'
);

-- ====================================================================
-- 数据同步任务：CDC → Kafka
-- ====================================================================

INSERT INTO kafka_user_stream
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
    ts AS cdc_ts
FROM mysql_user_cdc; 
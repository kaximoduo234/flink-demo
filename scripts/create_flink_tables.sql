-- ====================================================================
-- Flink SQL 表定义脚本 - 架构优化版本
-- 用途：创建完整的实时数仓架构 (CDC → Kafka → Paimon → StarRocks)
-- 执行：通过 SQL Gateway 或 SQL Client 执行
-- 架构：ODS(原始层) → DWD(明细层) → DWS(汇总层)
-- ====================================================================

-- 设置 Flink 执行环境
SET 'execution.checkpointing.interval' = '30s';
SET 'execution.checkpointing.mode' = 'EXACTLY_ONCE';
SET 'execution.runtime-mode' = 'streaming';
SET 'parallelism.default' = '1';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '1s';
SET 'table.exec.mini-batch.size' = '1000';
-- ✅ Paimon sink 必需配置 - 禁用 upsert materializer
SET 'table.exec.sink.upsert-materialize' = 'NONE';

-- ====================================================================
-- 第一部分：数据源表 (MySQL CDC) - ODS层
-- ====================================================================
/* 用户表结构 MYSQL 原始表
CREATE TABLE `user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '姓名',
  `gender` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '姓名',
  `age` int NOT NULL COMMENT '性别',
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '年龄',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '邮箱',
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '城市',
  `register_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间',
  `ts` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间',
  PRIMARY KEY (`id`),
  KEY `idx_gender` (`gender`),
  KEY `idx_city` (`city`),
  KEY `idx_register_time` (`register_time`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户表'
*/

-- MySQL CDC: 用户表 - 支持全量快照 + 增量捕获
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
    ts TIMESTAMP(3),  -- ✅ MySQL 实体字段
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
-- 第二部分：Kafka 中转表 - 数据缓冲与解耦
-- ====================================================================

-- Kafka: 用户数据流 - 带完整字段映射 (支持changelog)
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
    PRIMARY KEY (id) NOT ENFORCED  -- ✅ 自动作为 upsert key
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'user_stream',
    'properties.bootstrap.servers' = 'kafka:9092',
    'key.format' = 'json',
    'value.format' = 'json',
    'value.fields-include' = 'ALL'
);

-- 实时数据同步：CDC → Kafka
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

-- ====================================================================
-- 第三部分：Paimon 数据湖存储 (ODS/DWD层)
-- ====================================================================

-- 创建 Paimon Catalog - 使用Docker映射路径
CREATE CATALOG paimon_catalog WITH (
    'type' = 'paimon', 
    'warehouse' = 'file:/warehouse'
);

USE CATALOG paimon_catalog;

-- 创建数据库分层
CREATE DATABASE IF NOT EXISTS ods COMMENT '原始数据层';
CREATE DATABASE IF NOT EXISTS dwd COMMENT '明细数据层';


-- ====================================================================
-- ODS层：原始数据存储 (append-only模式)
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
    PRIMARY KEY (id, dt) NOT ENFORCED  -- ✅ 添加主键支持upsert
) PARTITIONED BY (dt) WITH (
    'bucket' = '4',
    'bucket-key' = 'id',
    'file.format' = 'parquet',
    'changelog-producer' = 'input',  -- ✅ 支持changelog模式
    'merge-engine' = 'deduplicate',  -- ✅ 支持去重合并
    'compaction.max.file-num' = '50'
);


-- ODS数据写入：保留完整历史记录
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


-- ====================================================================
-- DWD层：清洗加工的明细数据 (主键表模式，支持upsert)
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


-- DWD数据写入：带业务逻辑加工
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
    
    -- ✅ 固定值替代
    TRUE AS is_active,
    '常规用户' AS user_level,
    
    update_time AS last_behavior_time,

    -- ✅ 简化评分
    1.0 AS data_quality_score,

    cdc_ts AS ts,
    CURRENT_TIMESTAMP AS etl_time,
    DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd') AS dt

FROM paimon_catalog.ods.ods_user_raw
WHERE update_time IS NOT NULL;


-- ====================================================================
-- 第四部分：StarRocks 分析层 (DWS层)
-- ====================================================================

-- 切换回默认 catalog
USE CATALOG default_catalog;
CREATE DATABASE IF NOT EXISTS dws COMMENT '汇总数据层';
use dws；

-- StarRocks: 用户统计汇总表 - 使用StarRocks连接器
CREATE TABLE default_catalogdws.starrocks_dws_user_stats (
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
     'load-url' = 'starrocks:8030;starrocks:8040',              -- ✅ 同时提供FE和BE地址
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




-- 实时统计写入StarRocks
INSERT INTO default_catalog.dws.starrocks_dws_user_stats
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



-- ====================================================================
-- 第五部分：数据质量监控表
-- ====================================================================

-- 数据质量监控表
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
-- StarRocks 建表语句（在StarRocks中执行）
-- ====================================================================

/*
-- 在StarRocks中执行以下SQL创建目标表

create database if not exists analytics;

USE analytics;

-- 用户统计汇总表
CREATE TABLE dws_user_stats (
    date_key DATE,
    gender VARCHAR(32),
    age_group VARCHAR(32),
    city VARCHAR(128),
    user_level VARCHAR(32),
    user_count BIGINT,
    new_user_count BIGINT,
    active_user_count BIGINT,
    avg_data_quality_score DECIMAL(5,2),
    latest_ts DATETIME
)
ENGINE=OLAP
PRIMARY KEY(date_key, gender, age_group, city, user_level)
DISTRIBUTED BY HASH(date_key) BUCKETS 10
PROPERTIES (
    "replication_num" = "1",
    "compression" = "LZ4"
);
INSERT INTO starrocks_dws_user_stats VALUES (
   DATE '2025-06-20',
   '男',
   '18-24',
   '上海',
   '新用户',
   100,
   50,
   70,
   88.65,
   TIMESTAMP '2025-06-20 23:59:59.000'
);
*/



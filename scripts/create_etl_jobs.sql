-- ====================================================================
-- ETL 数据流转作业脚本
-- 用途：定义从 MySQL 到 StarRocks 的完整数据流转链路
-- 执行：按步骤顺序执行，或使用作业依赖管理
-- ====================================================================

-- ====================================================================
-- 第一阶段：MySQL CDC 到 Kafka
-- ====================================================================

-- 作业 1: 用户数据 CDC 到 Kafka
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
    ts
FROM mysql_user_cdc;

-- 作业 2: 用户行为数据 CDC 到 Kafka
INSERT INTO kafka_user_behavior_stream
SELECT 
    id,
    user_id,
    behavior_type,
    item_id,
    item_category,
    behavior_time,
    session_id,
    ip_address,
    user_agent,
    ts
FROM mysql_user_behavior_cdc;

-- ====================================================================
-- 第二阶段：Kafka 到 Paimon ODS
-- ====================================================================

-- 使用 Paimon Catalog
USE CATALOG paimon_catalog;

-- 作业 3: Kafka 用户数据到 Paimon ODS
INSERT INTO ods_user_raw
SELECT 
    id,
    name,
    gender,
    age,
    email,
    phone,
    city,
    register_time,
    ts,
    CURRENT_TIMESTAMP as etl_time
FROM default_catalog.default_database.kafka_user_stream;

-- 作业 4: Kafka 用户行为数据到 Paimon ODS
INSERT INTO ods_user_behavior_raw
SELECT 
    id,
    user_id,
    behavior_type,
    item_id,
    item_category,
    behavior_time,
    session_id,
    ip_address,
    user_agent,
    ts,
    CURRENT_TIMESTAMP as etl_time
FROM default_catalog.default_database.kafka_user_behavior_stream;

-- ====================================================================
-- 第三阶段：ODS 到 DWD 数据清洗和转换
-- ====================================================================

-- 作业 5: ODS 用户数据到 DWD 用户维度表
INSERT INTO dwd_user
SELECT 
    id,
    name,
    gender,
    age,
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        ELSE '46+'
    END as age_group,
    email,
    phone,
    city,
    register_time,
    true as is_active,
    CURRENT_TIMESTAMP as last_behavior_time,
    ts,
    CURRENT_TIMESTAMP as etl_time
FROM ods_user_raw;

-- 作业 6: ODS 用户行为数据到 DWD 事实表
INSERT INTO dwd_user_behavior
SELECT 
    id,
    user_id,
    behavior_type,
    item_id,
    item_category,
    behavior_time,
    session_id,
    DATE_FORMAT(behavior_time, 'yyyy-MM-dd') as date_key,
    HOUR(behavior_time) as hour_key,
    ts,
    CURRENT_TIMESTAMP as etl_time
FROM ods_user_behavior_raw;

-- ====================================================================
-- 第四阶段：DWD 到 StarRocks DWS 聚合统计
-- ====================================================================

-- 切换回默认 catalog
USE CATALOG default_catalog;

-- 作业 7: 用户维度统计到 StarRocks
INSERT INTO starrocks_dws_user_stats
SELECT 
    CAST(DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd') AS DATE) as date_key,
    u.gender,
    u.age_group,
    u.city,
    COUNT(DISTINCT u.id) as user_count,
    COUNT(DISTINCT CASE WHEN DATE(u.register_time) = CURRENT_DATE THEN u.id END) as new_user_count,
    COUNT(DISTINCT CASE WHEN u.is_active = true THEN u.id END) as active_user_count,
    MAX(u.ts) as latest_ts
FROM paimon_catalog.default.dwd_user u
GROUP BY 
    DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd'),
    u.gender,
    u.age_group,
    u.city;

-- 作业 8: 用户行为统计到 StarRocks
INSERT INTO starrocks_dws_user_behavior_stats
SELECT 
    CAST(b.date_key AS DATE) as date_key,
    b.hour_key,
    b.user_id,
    b.behavior_type,
    b.item_category,
    COUNT(*) as behavior_count,
    COUNT(DISTINCT b.session_id) as session_count,
    MAX(b.behavior_time) as latest_behavior_time,
    MAX(b.ts) as latest_ts
FROM paimon_catalog.default.dwd_user_behavior b
GROUP BY 
    b.date_key,
    b.hour_key,
    b.user_id,
    b.behavior_type,
    b.item_category;

-- ====================================================================
-- 第五阶段：实时指标计算到 ADS
-- ====================================================================

-- 作业 9: 实时指标计算
INSERT INTO starrocks_ads_realtime_metrics
SELECT 
    'total_users' as metric_key,
    '总用户数' as metric_name,
    CAST(COUNT(DISTINCT id) AS DECIMAL(18,2)) as metric_value,
    '人' as metric_unit,
    'user' as category,
    CURRENT_TIMESTAMP as update_time
FROM paimon_catalog.default.dwd_user

UNION ALL

SELECT 
    'total_behaviors_today' as metric_key,
    '今日总行为数' as metric_name,
    CAST(COUNT(*) AS DECIMAL(18,2)) as metric_value,
    '次' as metric_unit,
    'behavior' as category,
    CURRENT_TIMESTAMP as update_time
FROM paimon_catalog.default.dwd_user_behavior
WHERE date_key = DATE_FORMAT(CURRENT_DATE, 'yyyy-MM-dd')

UNION ALL

SELECT 
    'active_users_today' as metric_key,
    '今日活跃用户' as metric_name,
    CAST(COUNT(DISTINCT user_id) AS DECIMAL(18,2)) as metric_value,
    '人' as metric_unit,
    'user' as category,
    CURRENT_TIMESTAMP as update_time
FROM paimon_catalog.default.dwd_user_behavior
WHERE date_key = DATE_FORMAT(CURRENT_DATE, 'yyyy-MM-dd')

UNION ALL

SELECT 
    'avg_behaviors_per_user' as metric_key,
    '人均行为次数' as metric_name,
    CAST(COUNT(*) * 1.0 / COUNT(DISTINCT user_id) AS DECIMAL(18,2)) as metric_value,
    '次/人' as metric_unit,
    'behavior' as category,
    CURRENT_TIMESTAMP as update_time
FROM paimon_catalog.default.dwd_user_behavior
WHERE date_key = DATE_FORMAT(CURRENT_DATE, 'yyyy-MM-dd');

-- ====================================================================
-- 第六阶段：测试数据流 (使用数据生成器)
-- ====================================================================

-- 作业 10: 测试数据生成到 Paimon
INSERT INTO paimon_catalog.default.dwd_user_behavior
SELECT 
    ROW_NUMBER() OVER (ORDER BY behavior_time) + 10000 as id,
    user_id,
    behavior_type,
    item_id,
    item_category,
    behavior_time,
    session_id,
    DATE_FORMAT(behavior_time, 'yyyy-MM-dd') as date_key,
    HOUR(behavior_time) as hour_key,
    behavior_time as ts,
    CURRENT_TIMESTAMP as etl_time
FROM datagen_user_behavior;

-- ====================================================================
-- 监控和验证查询
-- ====================================================================

-- 验证数据流转情况
USE CATALOG paimon_catalog;

-- 检查 ODS 层数据量
SELECT 'ods_user_raw' as table_name, COUNT(*) as record_count FROM ods_user_raw
UNION ALL
SELECT 'ods_user_behavior_raw' as table_name, COUNT(*) as record_count FROM ods_user_behavior_raw;

-- 检查 DWD 层数据量
SELECT 'dwd_user' as table_name, COUNT(*) as record_count FROM dwd_user
UNION ALL
SELECT 'dwd_user_behavior' as table_name, COUNT(*) as record_count FROM dwd_user_behavior;

-- 检查最新数据时间戳
SELECT 
    'dwd_user' as table_name,
    MAX(ts) as latest_timestamp,
    MAX(etl_time) as latest_etl_time
FROM dwd_user
UNION ALL
SELECT 
    'dwd_user_behavior' as table_name,
    MAX(ts) as latest_timestamp,
    MAX(etl_time) as latest_etl_time
FROM dwd_user_behavior;

-- 数据质量检查
SELECT 
    gender,
    age_group,
    city,
    COUNT(*) as user_count
FROM dwd_user
GROUP BY gender, age_group, city
ORDER BY user_count DESC; 
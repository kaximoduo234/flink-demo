#!/bin/bash

# 等待Doris FE启动
echo "等待Doris FE启动..."
sleep 30

# 连接到Doris并注册BE节点
docker exec -i doris-fe mysql -uroot -P9030 -h127.0.0.1 << EOF
-- 添加BE节点
ALTER SYSTEM ADD BACKEND "doris-be:9050";

-- 查看集群状态
SHOW BACKENDS;

-- 创建测试数据库
CREATE DATABASE IF NOT EXISTS ods_doris;

-- 使用数据库
USE ods_doris;

-- 创建用户维表 (Duplicate模型，适合维表场景)
CREATE TABLE IF NOT EXISTS dim_users (
    id INT,
    username VARCHAR(255),
    email VARCHAR(255),
    birthdate DATE,
    is_active TINYINT,
    created_at DATETIME,
    updated_at DATETIME
) DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 1
PROPERTIES (
    "replication_num" = "1"
);

-- 创建用户行为事实表 (Aggregate模型，适合指标聚合)
CREATE TABLE IF NOT EXISTS fact_user_events (
    user_id INT,
    event_date DATE,
    event_type VARCHAR(50),
    event_count BIGINT SUM DEFAULT "0"
) AGGREGATE KEY(user_id, event_date, event_type)
DISTRIBUTED BY HASH(user_id) BUCKETS 1
PROPERTIES (
    "replication_num" = "1"
);

-- 显示表结构
DESCRIBE dim_users;
DESCRIBE fact_user_events;

EOF

echo "Doris 初始化完成！"
echo "访问地址："
echo "  - Doris FE Web UI: http://localhost:8030"
echo "  - Doris BE Web UI: http://localhost:8040"
echo "  - MySQL连接: mysql -uroot -P9030 -hlocalhost" 
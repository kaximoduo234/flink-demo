#!/bin/bash

# ====================================================================
# Flink SQL Client 执行脚本
# 用途：通过 Docker 容器内的 Flink SQL Client 执行 SQL
# ====================================================================

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "======================================================================"
echo "🚀 Flink SQL Client 执行器"
echo "======================================================================"

# 创建临时 SQL 文件
SQL_FILE="/tmp/flink_init.sql"

cat > "$SQL_FILE" << 'EOF'
-- 创建 Paimon Catalog
CREATE CATALOG paimon_catalog WITH (
    'type' = 'paimon',
    'warehouse' = 'file:///opt/flink/paimon-warehouse'
);

USE CATALOG paimon_catalog;

-- 创建数据库
CREATE DATABASE IF NOT EXISTS ods;
CREATE DATABASE IF NOT EXISTS dwd;
USE ods;

-- 显示当前状态
SHOW CATALOGS;
SHOW DATABASES;
SHOW TABLES;

-- 创建 MySQL CDC 源表
CREATE TABLE mysql_user (
    id BIGINT,
    name STRING,
    gender STRING,
    age INT,
    email STRING,
    phone STRING,
    city STRING,
    created_at TIMESTAMP(3),
    updated_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = 'mysql',
    'port' = '3306',
    'username' = 'root',
    'password' = 'root123',
    'database-name' = 'ods',
    'table-name' = 'user',
    'server-time-zone' = 'Asia/Shanghai'
);

-- 创建 Paimon 目标表
CREATE TABLE ods_user (
    id BIGINT,
    name STRING,
    gender STRING,
    age INT,
    email STRING,
    phone STRING,
    city STRING,
    created_at TIMESTAMP(3),
    updated_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'bucket' = '4',
    'file.format' = 'parquet'
);

-- 显示创建的表
SHOW TABLES;
EOF

log_step "创建初始化 SQL 文件..."
log_info "SQL 文件创建完成: $SQL_FILE"

log_step "复制 SQL 文件到 Flink 容器..."
docker cp "$SQL_FILE" jobmanager:/opt/flink/init.sql

log_step "通过 Flink SQL Client 执行初始化 SQL..."
log_info "注意：这将启动交互式 SQL Client，您可以手动执行 SQL 语句"

echo ""
echo "🔧 使用方法："
echo "1. 在 SQL Client 中执行: SOURCE '/opt/flink/init.sql';"
echo "2. 或者手动执行各个 SQL 语句"
echo "3. 使用 'quit;' 退出 SQL Client"
echo ""

# 启动 Flink SQL Client
docker exec -it jobmanager ./bin/sql-client.sh

log_info "SQL Client 会话结束" 
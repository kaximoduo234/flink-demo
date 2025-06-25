# 🚀 Flink SQL Client 执行指南

## 启动 SQL Client
```bash
docker exec -it jobmanager ./bin/sql-client.sh
```

## 📋 完整 SQL 执行步骤

### 第一步：查看系统状态
```sql
-- 查看可用的 Catalog
SHOW CATALOGS;

-- 查看当前数据库
SHOW DATABASES;

-- 查看现有表
SHOW TABLES;
```

### 第二步：创建数据源表（DataGen 连接器）
```sql
-- 创建用户数据生成器表
CREATE TABLE user_datagen (
    user_id BIGINT,
    user_name STRING,
    age INT,
    city STRING,
    register_time TIMESTAMP(3),
    WATERMARK FOR register_time AS register_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'datagen',
    'rows-per-second' = '2',
    'fields.user_id.kind' = 'sequence',
    'fields.user_id.start' = '1',
    'fields.user_id.end' = '1000',
    'fields.user_name.length' = '10',
    'fields.age.min' = '18',
    'fields.age.max' = '65',
    'fields.city.length' = '8'
);
```

### 第三步：创建输出表（Print 连接器）
```sql
-- 创建控制台输出表
CREATE TABLE user_print (
    user_id BIGINT,
    user_name STRING,
    age INT,
    city STRING,
    register_time TIMESTAMP(3)
) WITH (
    'connector' = 'print'
);
```

### 第四步：验证表创建
```sql
-- 查看创建的表
SHOW TABLES;

-- 查看表结构
DESCRIBE user_datagen;
DESCRIBE user_print;
```

### 第五步：启动流处理作业
```sql
-- 启动数据流处理作业（过滤年龄大于30的用户）
INSERT INTO user_print 
SELECT user_id, user_name, age, city, register_time 
FROM user_datagen 
WHERE age > 30;
```

### 第六步：监控作业状态
```sql
-- 查看运行中的作业
SHOW JOBS;
```

---

## 🔧 高级示例：完整数据流水线

### 1. 创建 Kafka 源表（如果需要）
```sql
CREATE TABLE user_behavior_source (
    user_id BIGINT,
    item_id BIGINT,
    behavior STRING,
    ts TIMESTAMP(3),
    WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'user_behavior',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'flink_consumer',
    'format' = 'json',
    'scan.startup.mode' = 'latest-offset'
);
```

### 2. 创建 MySQL CDC 源表
```sql
CREATE TABLE mysql_users (
    id BIGINT,
    name STRING,
    age INT,
    city STRING,
    created_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = 'mysql',
    'port' = '3306',
    'username' = 'root',
    'password' = 'root123',
    'database-name' = 'ods',
    'table-name' = 'user'
);
```

### 3. 创建 StarRocks 目标表
```sql
CREATE TABLE starrocks_user_stats (
    age_group STRING,
    user_count BIGINT,
    avg_age DOUBLE,
    update_time TIMESTAMP(3)
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://starrocks:9030',
    'load-url' = 'starrocks:8030',
    'username' = 'root',
    'password' = '',
    'database-name' = 'analytics',
    'table-name' = 'dws_user_stats'
);
```

### 4. 复杂的聚合查询
```sql
-- 实时用户统计
INSERT INTO starrocks_user_stats
SELECT 
    CASE 
        WHEN age < 25 THEN '青年'
        WHEN age < 45 THEN '中年'
        ELSE '中老年'
    END as age_group,
    COUNT(*) as user_count,
    AVG(CAST(age AS DOUBLE)) as avg_age,
    CURRENT_TIMESTAMP as update_time
FROM mysql_users
GROUP BY 
    CASE 
        WHEN age < 25 THEN '青年'
        WHEN age < 45 THEN '中年'
        ELSE '中老年'
    END;
```

---

## 🎯 推荐的执行顺序

### 初学者示例（简单）
```sql
-- 1. 查看系统状态
SHOW CATALOGS;
SHOW TABLES;

-- 2. 创建简单的数据生成器
CREATE TABLE simple_datagen (
    id BIGINT,
    name STRING
) WITH (
    'connector' = 'datagen',
    'rows-per-second' = '1',
    'fields.id.kind' = 'sequence',
    'fields.id.start' = '1',
    'fields.id.end' = '10',
    'fields.name.length' = '5'
);

-- 3. 创建输出表
CREATE TABLE simple_print (
    id BIGINT,
    name STRING
) WITH (
    'connector' = 'print'
);

-- 4. 启动作业
INSERT INTO simple_print SELECT * FROM simple_datagen;

-- 5. 查看作业状态
SHOW JOBS;
```

### 实际业务示例（复杂）
```sql
-- 1. 创建 MySQL CDC 源
CREATE TABLE ods_users (
    id BIGINT,
    name STRING,
    age INT,
    city STRING,
    created_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = 'mysql',
    'port' = '3306',
    'username' = 'root',
    'password' = 'root123',
    'database-name' = 'ods',
    'table-name' = 'user'
);

-- 2. 创建 Paimon 中间表
CREATE CATALOG paimon_catalog WITH (
    'type' = 'paimon',
    'warehouse' = 'file:///opt/flink/paimon-warehouse'
);

USE CATALOG paimon_catalog;

CREATE DATABASE IF NOT EXISTS ods;
USE ods;

CREATE TABLE user_ods (
    id BIGINT,
    name STRING,
    age INT,
    city STRING,
    created_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
);

-- 3. 启动 CDC 同步作业
USE CATALOG default_catalog;
INSERT INTO paimon_catalog.ods.user_ods 
SELECT id, name, age, city, created_at 
FROM ods_users;
```

---

## ⚠️ 重要提示

### 执行注意事项
1. **保持会话活跃** - 不要执行 `quit;` 命令
2. **逐条执行** - 一次执行一个 SQL 语句
3. **检查状态** - 使用 `SHOW JOBS;` 监控作业
4. **查看输出** - 在另一个终端执行 `docker logs -f taskmanager`

### 常用监控命令
```sql
-- 查看作业状态
SHOW JOBS;

-- 查看表列表
SHOW TABLES;

-- 查看表结构
DESCRIBE table_name;

-- 重置环境（如果需要）
DROP TABLE IF EXISTS table_name;
```

### 故障排除
```sql
-- 如果作业失败，查看具体错误
SHOW JOBS;

-- 删除有问题的表重新创建
DROP TABLE problem_table;
```

---

## 🎉 成功标志

当您看到以下输出时，说明作业运行成功：

1. `SHOW JOBS;` 显示作业状态为 `RUNNING`
2. TaskManager 日志中出现数据输出（`+I[...]` 格式）
3. Flink Web UI (http://localhost:8081) 显示运行中的作业

记住：**保持 SQL Client 会话不要退出**，这样流处理作业才能持续运行！ 
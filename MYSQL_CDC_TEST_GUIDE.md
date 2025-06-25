# MySQL CDC Connector 测试指南

## ✅ 解决方案总结

您之前遇到的错误：
```
Could not find any factory for identifier 'mysql-cdc'
```

已经通过以下步骤成功解决：

1. ✅ 下载了 `flink-sql-connector-mysql-cdc-3.0.1.jar`
2. ✅ 复制到所有 Flink 集群容器的 `/opt/flink/lib/` 目录
3. ✅ 重启了 Flink 相关容器（jobmanager, taskmanager, sql-gateway）

## 🔍 验证步骤

### 1. 检查容器状态
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### 2. 连接到 Flink SQL Gateway
```bash
# 方法1：使用本地 SQL Client
./flink-local/bin/sql-client.sh

# 方法2：通过 HTTP 接口测试
curl -X POST http://localhost:8083/sessions \
  -H "Content-Type: application/json" \
  -d '{"properties": {}}'
```

### 3. 验证可用的 Connector
在 Flink SQL Client 中执行：
```sql
-- 查看所有可用的 connector 工厂
SHOW FUNCTIONS;

-- 查看加载的 JAR 包
SHOW JARS;
```

现在应该能看到 `mysql-cdc` 在可用的 connector 列表中。

## 📋 完整的测试 SQL 脚本

### Step 1: 创建 MySQL CDC 源表
```sql
-- 创建用户表的 CDC 源
CREATE TABLE mysql_user_cdc (
    id INT,
    name STRING,
    email STRING,
    age INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = 'mysql',
    'port' = '3306',
    'username' = 'root',
    'password' = 'root123',
    'database-name' = 'ods',
    'table-name' = 'user_info',
    'server-time-zone' = 'Asia/Shanghai'
);
```

### Step 2: 创建 Kafka Sink 表
```sql
-- 创建 Kafka 用户流表
CREATE TABLE kafka_user_stream (
    id INT,
    name STRING,
    email STRING,
    age INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'kafka',
    'topic' = 'user_stream',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'user_cdc_group',
    'format' = 'json',
    'scan.startup.mode' = 'earliest-offset'
);
```

### Step 3: 执行数据同步
```sql
-- 将 MySQL CDC 数据写入 Kafka
INSERT INTO kafka_user_stream 
SELECT * FROM mysql_user_cdc;
```

## 🐛 故障排除

### 如果仍然遇到问题：

1. **检查容器日志**
```bash
docker logs jobmanager
docker logs taskmanager  
docker logs sql-gateway
```

2. **验证 JAR 文件存在**
```bash
docker exec jobmanager ls -la /opt/flink/lib/ | grep mysql-cdc
docker exec sql-gateway ls -la /opt/flink/lib/ | grep mysql-cdc
```

3. **手动重启特定容器**
```bash
docker restart sql-gateway
docker restart jobmanager
docker restart taskmanager
```

4. **检查 MySQL 连接**
```bash
docker exec mysql mysql -u root -p'root123' -e "SHOW DATABASES;"
```

## 📊 测试数据准备

### 在 MySQL 中插入测试数据
```sql
-- 连接到 MySQL
docker exec -it mysql mysql -u root -p'root123' ods

-- 插入测试数据
INSERT INTO user_info (name, email, age, created_at, updated_at) VALUES
('张三', 'zhangsan@example.com', 25, NOW(), NOW()),
('李四', 'lisi@example.com', 30, NOW(), NOW()),
('王五', 'wangwu@example.com', 28, NOW(), NOW());

-- 验证数据
SELECT * FROM user_info;
```

## ✅ 成功标志

如果一切正常，您应该看到：

1. Flink SQL Client 能够成功执行 `CREATE TABLE` 语句
2. 没有 "Could not find factory for identifier 'mysql-cdc'" 错误
3. 能够从 MySQL CDC 表中读取数据
4. 数据能够成功写入 Kafka

## 🎯 下一步操作

现在您可以：
1. 重新尝试之前失败的 SQL 语句
2. 构建完整的实时数据流水线
3. 集成更多的数据源和目标系统

如果您需要进一步的帮助或遇到其他问题，请告诉我！ 
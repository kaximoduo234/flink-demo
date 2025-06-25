# 实时数据仓库测试指南

## 🎯 测试目标
验证 StarRocks + Flink + Zeppelin + SQL Gateway 完整功能

## ✅ 当前状态确认

### 服务运行状态
- ✅ StarRocks FE (端口 8030) - 可访问
- ✅ Flink UI (端口 8081) - 可访问  
- ✅ SQL Gateway (端口 8083) - 可访问
- ✅ Zeppelin (端口 8082) - 可访问
- ✅ MySQL (端口 3306) - 可访问

### Web UI 访问地址
- **StarRocks**: http://localhost:8030
- **Flink**: http://localhost:8081
- **Zeppelin**: http://localhost:8082
- **StreamPark**: http://localhost:10000

## 📝 详细测试步骤

### 第1步：Web UI 功能验证

1. **访问 Flink Web UI**
   - 打开: http://localhost:8081
   - 确认 JobManager 和 TaskManager 正常运行
   - 查看 Available Task Slots 数量

2. **访问 StarRocks Web UI**
   - 打开: http://localhost:8030
   - 登录 (默认用户名: root, 密码: 空)
   - 查看 Frontend 和 Backend 状态

3. **访问 Zeppelin Web UI**
   - 打开: http://localhost:8082
   - 确认界面正常加载

### 第2步：Zeppelin + Flink 集成测试

#### 2.1 创建新 Notebook
1. 在 Zeppelin 中点击 "Create new note"
2. 输入名称: "Flink-Test"
3. 选择解释器: flink

#### 2.2 基础连接测试
```sql
%flink.ssql

-- 测试 1: 查看可用的 Catalog
SHOW CATALOGS;
```

**预期结果**: 显示 `default_catalog` 等

#### 2.3 环境配置测试
```sql
%flink.ssql

-- 测试 2: 查看当前配置
SET 'execution.runtime-mode' = 'streaming';
SET 'parallelism.default' = '1';

-- 显示所有配置
SET;
```

#### 2.4 数据生成器测试
```sql
%flink.ssql

-- 测试 3: 创建数据生成表
CREATE TABLE test_datagen (
    id INT,
    name STRING,
    age INT,
    event_time TIMESTAMP(3),
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'datagen',
    'rows-per-second' = '2',
    'fields.id.kind' = 'sequence',
    'fields.id.start' = '1',
    'fields.id.end' = '100',
    'fields.name.length' = '10',
    'fields.age.min' = '18',
    'fields.age.max' = '65'
);

-- 查询生成的数据
SELECT * FROM test_datagen LIMIT 10;
```

**预期结果**: 显示生成的随机数据

### 第3步：流处理功能测试

#### 3.1 聚合查询测试
```sql
%flink.ssql

-- 测试 4: 实时聚合
SELECT 
    COUNT(*) as total_count,
    AVG(age) as avg_age,
    MIN(age) as min_age,
    MAX(age) as max_age
FROM test_datagen;
```

#### 3.2 窗口函数测试
```sql
%flink.ssql

-- 测试 5: 滚动窗口聚合
SELECT 
    TUMBLE_START(event_time, INTERVAL '10' SECOND) as window_start,
    TUMBLE_END(event_time, INTERVAL '10' SECOND) as window_end,
    COUNT(*) as count_per_window,
    AVG(age) as avg_age_per_window
FROM test_datagen
GROUP BY TUMBLE(event_time, INTERVAL '10' SECOND);
```

### 第4步：Kafka 集成测试

#### 4.1 创建 Kafka Topic
```bash
# 在终端中执行
docker exec kafka kafka-topics.sh --create --topic test-events --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

#### 4.2 创建 Kafka 源表
```sql
%flink.ssql

-- 测试 6: Kafka 源表
CREATE TABLE kafka_events (
    id INT,
    message STRING,
    event_time TIMESTAMP(3),
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'test-events',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'test-group',
    'format' = 'json',
    'scan.startup.mode' = 'latest-offset',
    'json.timestamp-format.standard' = 'ISO-8601'
);
```

#### 4.3 创建 Kafka 目标表
```sql
%flink.ssql

-- 测试 7: Kafka 目标表
CREATE TABLE kafka_output (
    id INT,
    processed_message STRING,
    process_time TIMESTAMP(3)
) WITH (
    'connector' = 'kafka',
    'topic' = 'processed-events',
    'properties.bootstrap.servers' = 'kafka:9092',
    'format' = 'json',
    'json.timestamp-format.standard' = 'ISO-8601'
);
```

### 第5步：MySQL 集成测试

#### 5.1 在 MySQL 中创建测试表
```sql
%flink.ssql

-- 测试 8: MySQL 表 (需要先在 MySQL 中创建)
CREATE TABLE mysql_sink (
    id INT,
    name STRING,
    age INT,
    create_time TIMESTAMP(3)
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:mysql://mysql:3306/ods',
    'table-name' = 'user_events',
    'username' = 'root',
    'password' = 'root123'
);
```

### 第6步：StarRocks 集成测试

#### 6.1 创建 StarRocks 连接
```sql
%flink.ssql

-- 测试 9: StarRocks 目标表
CREATE TABLE starrocks_sink (
    id INT,
    name STRING,
    age INT,
    event_time TIMESTAMP
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://starrocks:9030',
    'load-url' = 'starrocks:8030',
    'database-name' = 'test_db',
    'table-name' = 'user_events',
    'username' = 'root',
    'password' = '',
    'sink.properties.format' = 'json',
    'sink.properties.strip_outer_array' = 'true'
);
```

### 第7步：端到端数据流测试

#### 7.1 完整数据流水线
```sql
%flink.ssql

-- 测试 10: 完整数据流
INSERT INTO starrocks_sink
SELECT 
    id,
    name,
    age,
    event_time
FROM test_datagen
WHERE age > 30;
```

## 🔍 故障排查

### 常见问题及解决方案

1. **Zeppelin 连接 Flink 失败**
   - 检查 `zeppelin-conf/interpreter.json` 配置
   - 确认 `flink.execution.mode = gateway`
   - 验证 `flink.execution.remote.host = sql-gateway`

2. **SQL Gateway 连接失败**
   - 检查 SQL Gateway 容器日志: `docker logs sql-gateway`
   - 确认端口 8083 是否正常监听

3. **StarRocks 连接失败**
   - 检查 StarRocks 健康状态: `docker exec starrocks mysql -h127.0.0.1 -P9030 -uroot -e "SELECT 1"`
   - 确认端口 9030 (MySQL) 和 8030 (HTTP) 正常

4. **Kafka 连接失败**
   - 检查 Kafka 容器状态
   - 验证 Topic 是否存在: `docker exec kafka kafka-topics.sh --list --bootstrap-server localhost:9092`

## 📊 性能测试

### 吞吐量测试
```sql
%flink.ssql

-- 高频数据生成
CREATE TABLE high_volume_test (
    id BIGINT,
    message STRING,
    event_time TIMESTAMP(3),
    WATERMARK FOR event_time AS event_time - INTERVAL '1' SECOND
) WITH (
    'connector' = 'datagen',
    'rows-per-second' = '1000',  -- 1000 条/秒
    'fields.id.kind' = 'sequence',
    'fields.message.length' = '50'
);

-- 监控处理性能
SELECT 
    COUNT(*) as total_processed,
    COUNT(*) / TIMESTAMPDIFF(SECOND, MIN(event_time), MAX(event_time)) as avg_tps
FROM high_volume_test;
```

## ✅ 测试完成检查清单

- [ ] Zeppelin Web UI 正常访问
- [ ] Flink 解释器连接成功
- [ ] 基础 SQL 查询正常执行
- [ ] 数据生成器正常工作
- [ ] 流处理查询正常运行
- [ ] Kafka 集成正常
- [ ] MySQL 连接正常
- [ ] StarRocks 连接正常
- [ ] 端到端数据流正常

## 📈 下一步建议

1. **生产环境优化**
   - 调整并发度和内存配置
   - 设置 Checkpoint 和 Savepoint
   - 配置监控和告警

2. **安全性增强**
   - 启用认证和授权
   - 配置网络安全
   - 数据加密传输

3. **扩展功能**
   - 集成更多数据源
   - 添加复杂事件处理
   - 实现实时仪表板 
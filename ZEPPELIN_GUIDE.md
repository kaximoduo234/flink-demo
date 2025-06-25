# Zeppelin Notebook 使用指南

## 📋 概述

Zeppelin Notebook 已集成到我们的实时数仓环境中，提供交互式数据分析和可视化功能。

## 🚀 快速开始

### 访问 Zeppelin
- **URL**: http://localhost:8082
- **默认用户**: anonymous (无需登录)

### 服务架构
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Zeppelin      │    │   StarRocks     │    │     Flink       │
│   :8082         │────│   :9030         │────│   :8081         │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 解释器配置

### 1. JDBC 解释器 (连接 StarRocks)

**配置名称**: `jdbc.starrocks`
```properties
default.driver: com.mysql.cj.jdbc.Driver
default.url: jdbc:mysql://starrocks:9030/
default.user: root
default.password: 
```

**使用方式**:
```sql
%jdbc(starrocks)
SHOW DATABASES;
```

### 2. Flink 解释器

**配置名称**: `flink`
```properties
flink.execution.mode: remote
flink.execution.remote.host: jobmanager
flink.execution.remote.port: 8081
```

**使用方式**:
```sql
%flink.ssql
SHOW CATALOGS;
```

## 📚 示例 Notebook

### StarRocks 数据分析
```sql
%jdbc(starrocks)
-- 创建数据库
CREATE DATABASE IF NOT EXISTS analytics;
USE analytics;

-- 创建用户行为表
CREATE TABLE user_events (
    user_id INT,
    event_type VARCHAR(50),
    timestamp DATETIME,
    properties JSON
) ENGINE=OLAP
DUPLICATE KEY(user_id)
DISTRIBUTED BY HASH(user_id) BUCKETS 8
PROPERTIES('replication_num' = '1');

-- 数据分析查询
SELECT 
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM user_events 
WHERE DATE(timestamp) = CURRENT_DATE()
GROUP BY event_type
ORDER BY event_count DESC;
```

### Flink 流处理
```sql
%flink.ssql
-- 创建 Kafka 源表
CREATE TABLE kafka_source (
    user_id INT,
    product_id INT,
    action STRING,
    timestamp TIMESTAMP(3),
    WATERMARK FOR timestamp AS timestamp - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'user_behavior',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'flink-consumer-group',
    'format' = 'json',
    'scan.startup.mode' = 'latest-offset'
);

-- 创建 StarRocks 结果表
CREATE TABLE starrocks_sink (
    user_id INT,
    product_id INT,
    action STRING,
    event_time TIMESTAMP(3)
) WITH (
    'connector' = 'starrocks',
    'jdbc-url' = 'jdbc:mysql://starrocks:9030',
    'load-url' = 'starrocks:8030',
    'database-name' = 'realtime',
    'table-name' = 'user_behavior_sink',
    'username' = 'root',
    'password' = ''
);

-- 实时数据处理
INSERT INTO starrocks_sink
SELECT 
    user_id,
    product_id,
    action,
    timestamp as event_time
FROM kafka_source
WHERE action IN ('click', 'buy', 'like');
```

## 📊 可视化功能

### 1. 表格显示
```sql
%jdbc(starrocks)
SELECT * FROM user_events LIMIT 100;
```

### 2. 图表可视化
Zeppelin 支持多种图表类型：
- 📈 **线图**: 时间序列分析
- 📊 **柱状图**: 分类数据对比
- 🥧 **饼图**: 占比分析
- 📋 **表格**: 详细数据展示

### 3. 动态参数
```sql
%jdbc(starrocks)
SELECT 
    event_type,
    COUNT(*) as count
FROM user_events 
WHERE DATE(timestamp) >= '${start_date=2025-06-01}'
  AND DATE(timestamp) <= '${end_date=2025-06-30}'
GROUP BY event_type;
```

## 🛠️ 高级功能

### 1. 多语言支持
```python
%python
import pandas as pd
import matplotlib.pyplot as plt

# 从 StarRocks 获取数据
df = pd.read_sql("""
    SELECT event_type, COUNT(*) as count 
    FROM analytics.user_events 
    GROUP BY event_type
""", connection)

# 创建可视化
plt.figure(figsize=(10, 6))
plt.bar(df['event_type'], df['count'])
plt.title('用户事件统计')
plt.show()
```

### 2. Shell 命令
```bash
%sh
# 查看服务状态
curl -s http://starrocks:8030/api/show_proc?path=/frontends
```

### 3. 定时执行
在 Notebook 设置中可以配置定时执行，实现：
- 📅 定期数据报表生成
- 🔄 自动化数据质量检查
- 📧 结果邮件通知

## 🎯 最佳实践

### 1. Notebook 组织
- **命名规范**: 使用描述性名称，如 `Daily_Sales_Analysis`
- **分段清晰**: 使用 Markdown 分段说明
- **版本控制**: 定期导出重要 Notebook

### 2. 性能优化
- **限制结果集**: 使用 `LIMIT` 避免大量数据传输
- **索引利用**: 查询时利用 StarRocks 的排序键
- **连接池**: 合理配置数据库连接

### 3. 安全考虑
- **权限控制**: 配置适当的数据库权限
- **数据敏感性**: 避免在 Notebook 中硬编码敏感信息
- **访问日志**: 定期审查 Notebook 访问记录

## 📁 目录结构
```
flink-demo/
├── zeppelin-notebook/          # Notebook 存储
│   ├── StarRocks-Flink-Demo.json
│   └── ...
├── zeppelin-conf/              # 配置文件
│   ├── zeppelin-site.xml
│   └── interpreter.json
└── docker-compose.yml
```

## 🔧 故障排除

### 常见问题

1. **无法连接 StarRocks**
   ```bash
   # 检查网络连接
   docker exec zeppelin ping starrocks
   
   # 验证端口
   docker exec zeppelin telnet starrocks 9030
   ```

2. **Flink 连接失败**
   ```bash
   # 检查 Flink 服务状态
   curl http://jobmanager:8081/overview
   ```

3. **Notebook 无法保存**
   ```bash
   # 检查挂载目录权限
   ls -la ./zeppelin-notebook/
   chmod 755 ./zeppelin-notebook/
   ```

## 🎉 快速验证

1. **访问 Zeppelin**: http://localhost:8082
2. **创建新 Notebook**
3. **测试 StarRocks 连接**:
   ```sql
   %jdbc(starrocks)
   SELECT 1 as test;
   ```
4. **测试 Flink 连接**:
   ```sql
   %flink.ssql
   SHOW CATALOGS;
   ```

## 📞 支持资源

- [Zeppelin 官方文档](https://zeppelin.apache.org/docs/)
- [Flink Zeppelin 集成](https://nightlies.apache.org/flink/flink-docs-release-1.18/docs/dev/python/dependency_management/#using-zeppelin-notebooks)
- [StarRocks JDBC 连接](https://docs.starrocks.io/zh/docs/loading/Jdbc/)

---

**配置完成时间**: 2025-06-18  
**环境版本**: Zeppelin 0.12.0 + StarRocks 3.5.0 + Flink 1.20.1 
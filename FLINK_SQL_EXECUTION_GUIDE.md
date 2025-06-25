# 🚀 Flink SQL 执行指南

## 📋 概述

由于 Zeppelin 无法正常使用，我们提供了多种替代方式来创建和执行 Flink SQL 作业。以下是所有可用的方法：

## 🛠️ 执行方式

### 方式一：SQL Gateway API (推荐)

**脚本**: `./scripts/execute_flink_sql.sh`

**优点**:
- 完全自动化执行
- 支持复杂的 SQL 流水线
- 可以集成到 CI/CD 中
- 错误处理完善

**使用方法**:
```bash
./scripts/execute_flink_sql.sh
```

**适用场景**: 生产环境、自动化部署

---

### 方式二：Flink SQL Client (交互式)

**脚本**: `./scripts/flink_sql_client.sh`

**优点**:
- 交互式操作
- 实时查看执行结果
- 支持复杂查询调试
- 官方标准工具

**使用方法**:
```bash
./scripts/flink_sql_client.sh
```

然后在 SQL Client 中执行：
```sql
SOURCE '/opt/flink/init.sql';
```

**适用场景**: 开发调试、交互式查询

---

### 方式三：简单演示 (快速测试)

**脚本**: `./scripts/simple_flink_demo.sh`

**优点**:
- 快速验证 Flink 功能
- 使用内置数据生成器
- 无需外部依赖
- 适合学习和演示

**使用方法**:
```bash
./scripts/simple_flink_demo.sh
```

**适用场景**: 功能验证、学习演示

---

### 方式四：直接 API 调用

**手动执行 API 请求**:

```bash
# 1. 创建会话
SESSION_HANDLE=$(curl -s -X POST "http://localhost:8083/v1/sessions" \
    -H "Content-Type: application/json" \
    -d '{"properties": {"execution.runtime-mode": "streaming"}}' | \
    jq -r '.sessionHandle')

# 2. 执行 SQL
curl -s -X POST "http://localhost:8083/v1/sessions/$SESSION_HANDLE/statements" \
    -H "Content-Type: application/json" \
    -d '{"statement": "SHOW CATALOGS"}'
```

**适用场景**: 自定义集成、API 开发

## 📊 当前系统状态

### ✅ 已验证功能

- [x] **系统部署**: 所有服务正常运行
- [x] **API 接口**: SQL Gateway 可正常访问
- [x] **数据源**: MySQL 数据已就绪 (8 用户, 9 行为记录)
- [x] **目标存储**: StarRocks 表已创建 (6 张表)
- [x] **Paimon 仓库**: 数据湖存储已准备就绪

### 🔧 服务状态

| 服务 | 状态 | 端口 | 说明 |
|------|------|------|------|
| Flink JobManager | 🟢 运行中 | 8081 | 2 个可用槽位 |
| SQL Gateway | 🟢 运行中 | 8083 | API 接口正常 |
| MySQL | 🟢 运行中 | 3306 | 测试数据已就绪 |
| StarRocks | 🟢 运行中 | 9030 | 分析表已创建 |
| Kafka | 🟢 运行中 | 9092 | 消息队列就绪 |

## 🎯 推荐执行流程

### 第一步：验证系统状态
```bash
./scripts/quick_test.sh
```

### 第二步：检查数据流
```bash
./scripts/check_data_flow.sh
```

### 第三步：执行 Flink SQL (选择一种方式)

**方式 A - 自动化执行**:
```bash
./scripts/execute_flink_sql.sh
```

**方式 B - 交互式执行**:
```bash
./scripts/flink_sql_client.sh
```

**方式 C - 快速演示**:
```bash
./scripts/simple_flink_demo.sh
```

### 第四步：监控作业状态
- 访问 Flink Web UI: http://localhost:8081
- 查看作业运行状态和监控指标

## 📚 SQL 脚本说明

### 核心 SQL 文件

| 文件 | 用途 | 说明 |
|------|------|------|
| `scripts/create_flink_tables.sql` | 表定义 | 创建所有 Flink 表 |
| `scripts/create_etl_jobs.sql` | ETL 作业 | 完整数据流转链路 |
| `scripts/create_mysql_tables.sql` | 源数据 | MySQL 业务表和测试数据 |
| `scripts/create_starrocks_tables.sql` | 目标表 | StarRocks 分析表 |

### 执行顺序

1. **表定义阶段**: 创建 Catalog、数据库、表结构
2. **数据流阶段**: 启动 CDC、数据同步、ETL 转换
3. **验证阶段**: 检查数据流转、查询结果

## 🔍 故障排查

### 常见问题

1. **作业提交失败**
   ```bash
   # 检查 SQL Gateway 状态
   curl -s http://localhost:8083/v1/info
   
   # 查看错误日志
   docker logs sql-gateway
   ```

2. **作业运行异常**
   ```bash
   # 查看 Flink 集群状态
   curl -s http://localhost:8081/overview
   
   # 查看 TaskManager 日志
   docker logs taskmanager
   ```

3. **数据不同步**
   ```bash
   # 检查 MySQL 连接
   docker exec mysql mysql -uroot -proot123 -e "SELECT 1"
   
   # 检查 Kafka 消息
   docker exec kafka kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning
   ```

### 日志查看

```bash
# Flink JobManager 日志
docker logs jobmanager

# Flink TaskManager 日志  
docker logs taskmanager

# SQL Gateway 日志
docker logs sql-gateway

# MySQL 日志
docker logs mysql

# StarRocks 日志
docker logs starrocks
```

## 🎉 成功标志

当您看到以下情况时，说明 Flink SQL 作业执行成功：

1. **Flink Web UI** 中显示运行中的作业
2. **TaskManager 日志** 中有数据处理输出
3. **StarRocks 表** 中有实时更新的数据
4. **Paimon 仓库** 中生成了数据文件

## 📞 获取帮助

如果遇到问题，可以：

1. 查看本文档的故障排查部分
2. 检查相关服务的日志输出
3. 访问 Flink Web UI 查看详细错误信息
4. 运行 `./scripts/check_data_flow.sh` 进行全面检查

---

**💡 提示**: 建议先使用 `./scripts/simple_flink_demo.sh` 进行快速验证，确认 Flink 功能正常后，再执行复杂的 ETL 作业。 
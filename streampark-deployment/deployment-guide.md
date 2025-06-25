# 🚀 StreamPark 实时数仓工程部署指南

## 📋 部署概述

本指南详细说明如何将基于验证通过的SQL脚本的StreamPark实时数仓工程部署到生产环境。

## 🏗️ 系统架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   数据源层      │    │   流处理层      │    │   存储分析层    │
│                 │    │                 │    │                 │
│  MySQL业务库    │───▶│  Flink+Paimon   │───▶│  StarRocks OLAP │
│  (CDC捕获)      │    │  (StreamPark管理)│    │  (多维分析)     │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
   Kafka消息队列         Paimon数据湖             可视化分析平台
```

## 🛠️ 环境准备

### 系统要求
- **操作系统**: CentOS 7+ / Ubuntu 18+ / RHEL 7+
- **Java**: OpenJDK 11 / Oracle JDK 11
- **内存**: 最低16GB，推荐32GB+
- **CPU**: 最低4核，推荐8核+
- **磁盘**: SSD，最低100GB可用空间

### 软件版本
| 组件 | 版本 | 必需/可选 |
|------|------|----------|
| Flink | 1.20.1 | 必需 |
| StreamPark | 2.1.5 | 必需 |
| Paimon | 1.0.0 | 必需 |
| MySQL | 8.0+ | 必需 |
| Kafka | 3.6.0 | 必需 |
| StarRocks | 3.5.0 | 必需 |
| Zookeeper | 3.8+ | 必需 |

## 📦 安装部署

### 步骤1：基础环境安装

#### 1.1 Java环境
```bash
# 安装OpenJDK 11
sudo yum install -y java-11-openjdk java-11-openjdk-devel

# 配置JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 验证安装
java -version
```

#### 1.2 Hadoop环境 (可选，用于HDFS存储)
```bash
# 下载Hadoop
wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz
tar -xzf hadoop-3.3.4.tar.gz -C /opt/
ln -s /opt/hadoop-3.3.4 /opt/hadoop

# 配置环境变量
echo 'export HADOOP_HOME=/opt/hadoop' >> ~/.bashrc
echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ~/.bashrc
source ~/.bashrc
```

### 步骤2：Flink集群部署

#### 2.1 下载和配置Flink
```bash
# 下载Flink 1.20.1
wget https://archive.apache.org/dist/flink/flink-1.20.1/flink-1.20.1-bin-scala_2.12.tgz
tar -xzf flink-1.20.1-bin-scala_2.12.tgz -C /opt/
ln -s /opt/flink-1.20.1 /opt/flink

# 配置环境变量
echo 'export FLINK_HOME=/opt/flink' >> ~/.bashrc
source ~/.bashrc
```

#### 2.2 配置flink-conf.yaml
```yaml
# /opt/flink/conf/flink-conf.yaml
jobmanager.rpc.address: localhost
jobmanager.rpc.port: 6123
jobmanager.memory.process.size: 2g
taskmanager.memory.process.size: 4g
taskmanager.numberOfTaskSlots: 4
parallelism.default: 1

# Checkpoint配置
state.backend: rocksdb
state.backend.incremental: true
execution.checkpointing.interval: 30s
execution.checkpointing.mode: EXACTLY_ONCE

# 高可用配置
high-availability: zookeeper
high-availability.zookeeper.quorum: localhost:2181
high-availability.storageDir: file:///opt/flink/ha-data
```

#### 2.3 启动Flink集群
```bash
# 启动集群
$FLINK_HOME/bin/start-cluster.sh

# 验证启动
curl http://localhost:8081
```

### 步骤3：StreamPark安装配置

#### 3.1 下载StreamPark
```bash
# 下载StreamPark 2.1.5
wget https://github.com/apache/streampark/releases/download/v2.1.5/apache-streampark_2.12-2.1.5-incubating-bin.tar.gz
tar -xzf apache-streampark_2.12-2.1.5-incubating-bin.tar.gz -C /opt/
ln -s /opt/apache-streampark_2.12-2.1.5-incubating /opt/streampark
```

#### 3.2 配置application.yml
```yaml
# /opt/streampark/conf/application.yml
server:
  port: 10000
  
spring:
  application:
    name: StreamPark
  profiles:
    active: mysql
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/streampark?useUnicode=true&characterEncoding=UTF-8&useJDBCCompliantTimezoneShift=true&useLegacyDatetimeCode=false&serverTimezone=GMT%2B8
    username: streampark
    password: streampark123

streampark:
  # Flink配置
  flink:
    client:
      timeout: 60s
  # 工作空间配置  
  workspace:
    local: /opt/streampark/workspace
    remote: hdfs://localhost:9000/streampark
```

#### 3.3 初始化数据库
```bash
# 创建数据库
mysql -u root -p -e "CREATE DATABASE streampark CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

# 创建用户
mysql -u root -p -e "CREATE USER 'streampark'@'%' IDENTIFIED BY 'streampark123';"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON streampark.* TO 'streampark'@'%';"

# 初始化表结构
mysql -u streampark -p streampark < /opt/streampark/conf/sql/schema/mysql-schema.sql
```

#### 3.4 启动StreamPark
```bash
# 启动StreamPark
/opt/streampark/bin/streampark.sh start

# 查看日志
tail -f /opt/streampark/logs/streampark.out

# 验证启动
curl http://localhost:10000
```

### 步骤4：数据存储组件部署

#### 4.1 MySQL配置 (已有)
```sql
-- 确保开启binlog
-- 在my.cnf中添加
[mysqld]
log-bin=mysql-bin
binlog-format=ROW
server-id=1
gtid_mode=ON
enforce_gtid_consistency=ON
```

#### 4.2 Kafka集群部署
```bash
# 下载Kafka
wget https://archive.apache.org/dist/kafka/3.6.0/kafka_2.12-3.6.0.tgz
tar -xzf kafka_2.12-3.6.0.tgz -C /opt/
ln -s /opt/kafka_2.12-3.6.0 /opt/kafka

# 启动Zookeeper
/opt/kafka/bin/zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties

# 启动Kafka
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties

# 创建Topic
/opt/kafka/bin/kafka-topics.sh --create --topic user_stream --bootstrap-server localhost:9092 --partitions 4 --replication-factor 1
```

#### 4.3 StarRocks部署
```bash
# 下载StarRocks
wget https://releases.starrocks.io/starrocks/StarRocks-3.5.0.tar.gz
tar -xzf StarRocks-3.5.0.tar.gz -C /opt/
ln -s /opt/StarRocks-3.5.0 /opt/starrocks

# 配置FE
cp /opt/starrocks/fe/conf/fe.conf.template /opt/starrocks/fe/conf/fe.conf

# 启动FE
/opt/starrocks/fe/bin/start_fe.sh --daemon

# 配置和启动BE
cp /opt/starrocks/be/conf/be.conf.template /opt/starrocks/be/conf/be.conf
/opt/starrocks/be/bin/start_be.sh --daemon
```

## 🚀 项目部署

### 步骤5：部署StreamPark作业

#### 5.1 上传项目文件
```bash
# 创建项目目录
mkdir -p /opt/streampark/workspace/realtime-dw

# 上传SQL文件
scp streampark-jobs/*.sql server:/opt/streampark/workspace/realtime-dw/
```

#### 5.2 登录StreamPark控制台
- 访问: http://localhost:10000
- 默认账号: admin / streampark

#### 5.3 创建Flink集群
1. 进入 **系统管理** → **集群管理**
2. 点击 **添加集群**
3. 配置集群信息:
   - 集群名称: `flink-cluster-prod`
   - 集群地址: `http://localhost:8081`
   - 版本: `1.20.1`

#### 5.4 创建作业

**作业1: CDC数据采集**
- 作业名称: `rt-dw-cdc-ingestion`
- 作业类型: `Flink SQL`
- 运行模式: `yarn-per-job`
- 执行模式: `streaming`
- 并行度: `2`
- SQL文件: `job-01-cdc-ingestion.sql`

**作业2: ODS层处理**
- 作业名称: `rt-dw-ods-processing`
- 作业类型: `Flink SQL`
- 依赖作业: `rt-dw-cdc-ingestion`
- 并行度: `2`
- SQL文件: `job-02-ods-processing.sql`

**作业3: DWD层转换**
- 作业名称: `rt-dw-dwd-transform`
- 依赖作业: `rt-dw-ods-processing`
- 并行度: `4`
- SQL文件: `job-03-dwd-transform.sql`

**作业4: DWS层聚合**
- 作业名称: `rt-dw-dws-aggregate`
- 依赖作业: `rt-dw-dwd-transform`
- 并行度: `2`
- SQL文件: `job-04-dws-aggregate.sql`

**作业5: 数据质量监控**
- 作业名称: `rt-dw-monitor`
- 并行度: `1`
- SQL文件: `job-05-monitor.sql`

### 步骤6：配置作业参数

#### 6.1 通用JVM参数
```bash
-Xms2g -Xmx2g -XX:+UseG1GC
-Dfile.encoding=UTF-8
-Duser.timezone=Asia/Shanghai
```

#### 6.2 Flink配置参数
```yaml
execution.checkpointing.interval: 30s
execution.checkpointing.mode: EXACTLY_ONCE
execution.runtime-mode: streaming
parallelism.default: 1
table.exec.mini-batch.enabled: true
table.exec.mini-batch.allow-latency: 1s
table.exec.mini-batch.size: 1000
table.exec.sink.upsert-materialize: NONE
```

## 🔍 监控和验证

### 步骤7：验证部署

#### 7.1 检查作业状态
```bash
# StreamPark作业状态
curl http://localhost:10000/api/flink/app/list

# Flink作业状态  
curl http://localhost:8081/jobs
```

#### 7.2 数据流验证
```bash
# 检查Kafka topic
/opt/kafka/bin/kafka-console-consumer.sh --topic user_stream --from-beginning --bootstrap-server localhost:9092

# 检查Paimon表
/opt/flink/bin/sql-client.sh -f verify-paimon-tables.sql

# 检查StarRocks表
mysql -h localhost -P 9030 -u root -e "SELECT COUNT(*) FROM analytics.dws_user_stats;"
```

#### 7.3 监控指标
- **Flink UI**: http://localhost:8081
- **StreamPark控制台**: http://localhost:10000  
- **Kafka Manager**: 部署Kafka-UI查看Topic状态
- **StarRocks监控**: 查看FE/BE状态页面

## 🚨 故障排查

### 常见问题解决

#### 问题1: Paimon Sink错误
```
错误: Sink materializer must not be used with Paimon sink
解决: 确保设置 table.exec.sink.upsert-materialize = NONE
```

#### 问题2: CDC连接失败
```
错误: Failed to connect to MySQL
解决: 检查MySQL用户权限和binlog配置
```

#### 问题3: 内存溢出
```
错误: OutOfMemoryError
解决: 增加TaskManager内存或调整并行度
```

### 日志查看
```bash
# StreamPark日志
tail -f /opt/streampark/logs/streampark.out

# Flink JobManager日志
tail -f /opt/flink/log/flink-*-jobmanager-*.log

# Flink TaskManager日志
tail -f /opt/flink/log/flink-*-taskmanager-*.log
```

## 📋 运维建议

### 性能优化
1. **内存配置**: 根据数据量调整JM/TM内存
2. **并行度**: 根据CPU核数和数据倾斜情况调整
3. **Checkpoint**: 根据业务需求调整间隔时间
4. **状态后端**: 生产环境使用RocksDB

### 高可用配置
1. **Flink HA**: 配置Zookeeper实现JobManager高可用
2. **数据备份**: 定期备份Checkpoint和Savepoint
3. **监控告警**: 集成Prometheus+Grafana
4. **故障恢复**: 制定详细的故障恢复流程

### 安全配置
1. **认证授权**: 启用Kerberos或LDAP认证
2. **网络安全**: 配置防火墙规则
3. **数据加密**: 启用SSL/TLS传输加密
4. **权限控制**: 实现细粒度的权限管理

---

🎯 **部署成功后，你将拥有一个完整的企业级实时数据仓库！**

## 🔗 相关文档

- [StreamPark官方文档](https://streampark.apache.org/)
- [Flink SQL开发指南](https://nightlies.apache.org/flink/flink-docs-stable/docs/dev/table/sql/)
- [Paimon数据湖文档](https://paimon.apache.org/)
- [项目架构设计文档](./ARCHITECTURE.md)

## 📞 技术支持

- 技术咨询: tech-support@company.com
- 故障报告: incident-report@company.com
- 项目Wiki: https://wiki.company.com/realtime-dw 
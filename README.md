# Apache Flink + Paimon Demo

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Apache Flink](https://img.shields.io/badge/Apache%20Flink-1.20.1-E6526F?style=for-the-badge&logo=apache-flink&logoColor=white)](https://flink.apache.org/)
[![Apache Paimon](https://img.shields.io/badge/Apache%20Paimon-1.0.0-blue?style=for-the-badge)](https://paimon.apache.org/)
[![Java](https://img.shields.io/badge/Java-17-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)](https://openjdk.org/projects/jdk/17/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> 🎉 **最新更新**: 已升级至 **Flink 1.20.1** + **Java 17** + **Paimon 1.0.0**，享受最新特性和性能提升！

🌏 **[中文文档](#中文文档) | [English Documentation](#english-documentation)**

---

<a name="english-documentation"></a>
## 🇺🇸 English Documentation

A comprehensive Apache Flink streaming platform demo with pre-integrated Apache Paimon connector, containerized using Docker Compose for production-ready deployment.

### 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Services Overview](#-services-overview)
- [Configuration](#-configuration)
- [Development](#-development)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

### ✨ Features

- 🚀 **One-Click Deployment** - Automated build and startup with Docker Compose
- 📦 **Latest Stack** - Flink 1.20.1 + Java 17 + Paimon 1.0.0 for optimal performance
- 🏗️ **Complete Data Stack** - Flink + Kafka + MySQL + Doris + Redis
- 🔧 **Production Ready** - Containerized deployment with proper configurations
- 🛠️ **Developer Friendly** - Easy to extend with custom JARs and configurations
- 📊 **Multiple Data Sources** - Support for various input/output connectors
- 🔄 **Stream Processing** - Real-time data processing capabilities
- 📈 **Monitoring Ready** - Built-in web UIs for all components
- ⚡ **Modern APIs** - Uses latest Flink Configuration API and Jackson JSON processing
- 🔒 **Enhanced Security** - Removed deprecated FastJSON, improved dependency management

### 🏗️ Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           Flink Cluster                 │
                    │  ┌─────────────┐   ┌─────────────┐     │
                    │  │JobManager   │───│TaskManager  │     │
                    │  │(Master)     │   │(Worker)     │     │
                    │  └─────────────┘   └─────────────┘     │
                    └─────────────┬───────────────────────────┘
                                  │
    ┌─────────────┐              │              ┌─────────────┐
    │   Apache    │──────────────┼──────────────│   Apache    │
    │   Kafka     │              │              │   Doris     │
    │ (Streaming) │              │              │(Analytics)  │
    └─────────────┘              │              └─────────────┘
                                  │
    ┌─────────────┐              │              ┌─────────────┐
    │   MySQL     │──────────────┼──────────────│   Redis     │
    │(Transactional)              │              │  (Cache)    │
    └─────────────┘              │              └─────────────┘
                                  │
                          ┌───────▼────────┐
                          │  Apache Paimon │
                          │   (Lake Store) │
                          └────────────────┘
```

### 📋 Prerequisites

- **Docker** (version 20.10+) - [Installation Guide](https://docs.docker.com/get-docker/)
- **Docker Compose** (version 2.0+) - [Installation Guide](https://docs.docker.com/compose/install/)
- **Git** - [Installation Guide](https://git-scm.com/downloads)
- **Java 17** (for development) - [Installation Guide](https://openjdk.org/projects/jdk/17/)
- **Maven 3.6+** (for building) - [Installation Guide](https://maven.apache.org/install.html)
- At least **8GB RAM** and **10GB** free disk space

### 🆕 What's New in v1.1.0

#### 🎯 Major Upgrades
- **Apache Flink**: 1.17.1 → **1.20.1** (Latest stable release)
- **Java Runtime**: 11 → **17** (Enhanced performance and security)
- **Apache Paimon**: 0.8.2 → **1.0.0** (Production-ready features, 实际使用版本)

#### 🔧 Technical Improvements
- **Modern Configuration API**: Uses new `Configuration` + `ConfigOptions` pattern
- **Enhanced Security**: Replaced FastJSON with Jackson ObjectMapper
- **Better Dependency Management**: Resolved version conflicts and added missing dependencies
- **Docker Optimization**: Fixed network conflicts and updated base images
- **Code Modernization**: Removed all deprecated APIs and warnings

#### 🚀 Performance Enhancements
- **Java 17 Benefits**: Improved GC performance and memory efficiency  
- **Flink 1.20.1 Features**: Better checkpoint mechanisms and state management
- **Connector Updates**: Latest Kafka, JDBC, and CDC connectors for better stability

> 📖 **Migration Guide**: See [CHANGELOG.md](CHANGELOG.md) for detailed upgrade instructions

### 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/flink-demo.git
cd flink-demo

# Start all services (one-click deployment)
docker-compose up --build -d

# Verify services
docker-compose ps
```

### 🌐 Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Flink Dashboard** | http://localhost:8081 | - |
| **MySQL (Adminer)** | http://localhost:8080 | root/root123 |
| **Doris FE** | http://localhost:8030 | root/(empty) |
| **StreamPark** | http://localhost:10000 | admin/streampark |

### 🛠️ Services Overview

| Service | Version | Port(s) | Description |
|---------|---------|---------|-------------|
| **Apache Flink** | 1.20.1 | 8081 | Stream processing engine with Paimon |
| **Apache Kafka** | Latest | 9092 | Distributed streaming platform |
| **MySQL** | 8.0 | 3306 | Relational database with CDC enabled |
| **Apache Doris** | Latest | 8030, 9030 | MPP analytical database |
| **Redis** | 6.2 | 6379 | In-memory data structure store |
| **StreamPark** | 2.1.5 | 10000 | Flink job management platform |

### 📖 Usage Examples

#### 🚀 Complete Paimon Quick Start Tutorial

This tutorial provides a step-by-step guide to test Paimon functionality with real-time data.

**Step 1: Access Flink SQL Client**
```bash
# Enter Flink JobManager container
docker exec -it jobmanager bash

# Start Flink SQL Client
./bin/sql-client.sh
```

**Step 2: Basic Paimon Setup (Copy & Run)**
```sql
-- Create Paimon catalog
CREATE CATALOG my_catalog WITH (
  'type' = 'paimon',
  'warehouse' = 'file:/warehouse'
);

-- Switch to Paimon catalog (IMPORTANT: Required for subsequent operations)
USE CATALOG my_catalog;

-- Create main table with primary key
-- Note: PRIMARY KEY NOT ENFORCED means supports deduplication but not mandatory
CREATE TABLE word_count (
  word STRING PRIMARY KEY NOT ENFORCED,
  cnt BIGINT
);

-- Create data source table using Flink's built-in datagen connector
CREATE TEMPORARY TABLE word_table (
  word STRING
) WITH (
  'connector' = 'datagen',
  'fields.word.length' = '1'  -- Generates single character words (a, b, c, etc.)
);

-- Enable checkpointing for fault tolerance
SET 'execution.checkpointing.interval' = '10 s';

-- Start streaming job: Insert real-time aggregated data
INSERT INTO word_count
SELECT word, COUNT(*) FROM word_table GROUP BY word;
```


**Step 3: Monitor Results in Real-time**

Open a **second terminal session** while the INSERT job is running:
```bash
# Open another SQL Client session
docker exec -it jobmanager ./bin/sql-client.sh
```

```sql
USE CATALOG my_catalog;

-- Query real-time results (will show continuously growing counts)
SELECT * FROM word_count;

-- Expected output (counts will keep increasing):
/*
+----+--------------------------------+----------------------+
| op |                           word |                  cnt |
+----+--------------------------------+----------------------+
| +I |                              a |                   45 |
| +I |                              b |                   38 |
| +I |                              c |                   42 |
| +I |                              d |                   51 |
+----+--------------------------------+----------------------+
*/
```

**Step 4: Switch to Batch Mode (OLAP Query)**
```sql
-- Configure for batch processing (static snapshot)
SET 'sql-client.execution.result-mode' = 'tableau';
RESET 'execution.checkpointing.interval';
SET 'execution.runtime-mode' = 'batch';

-- Query static snapshot (won't auto-refresh)
SELECT * FROM word_count ORDER BY cnt DESC LIMIT 5;

-- This demonstrates Paimon's "storage-compute separation" design
-- Stream mode: Real-time updates | Batch mode: Static analysis
```

**Step 5: Advanced Example - Business Table**
```sql
-- Create a business orders table
CREATE TABLE orders (
  order_id BIGINT,
  user_id BIGINT,
  product_id BIGINT,
  order_time TIMESTAMP(3),
  amount DECIMAL(10,2),
  PRIMARY KEY (order_id) NOT ENFORCED
) WITH ('bucket' = '4');

-- Insert sample data
INSERT INTO orders VALUES
(1001, 101, 201, TIMESTAMP '2024-01-15 10:30:00', 99.99),
(1002, 102, 202, TIMESTAMP '2024-01-15 11:15:00', 149.50),
(1003, 101, 203, TIMESTAMP '2024-01-15 12:00:00', 79.99);

-- Query data
SELECT * FROM orders;
```

**Step 6: Cleanup & Exit**
```sql
-- Optional cleanup
DROP TABLE word_count;
DROP TABLE orders;

-- Exit SQL Client
QUIT;
```

#### 📊 Expected Results & Verification

1. **Flink Web UI Status**: Visit http://localhost:8081 to see running jobs
2. **Real-time Growth**: `word_count` query results should show increasing numbers
3. **Batch vs Stream**: Notice the difference in query behavior between modes

#### 🔍 Troubleshooting Tips

- **Catalog Error**: Always use `USE CATALOG my_catalog` after creating the catalog
- **No Data**: Check if the INSERT job is running in Flink Web UI
- **Permission Issues**: Ensure `/warehouse` directory is writable in containers

#### 📄 Ready-to-Use Script

For convenience, you can also use the complete test script:
```bash
# Copy the ready-to-use SQL script
cat examples/paimon-quick-test.sql

# Or execute it directly in SQL Client
# 或在 SQL 客户端中直接执行
```
The script contains all the commands above with detailed comments in both English and Chinese.

### 🔧 Development

#### Adding Custom JARs
1. Place JAR files in `flink-jars/` directory
2. Rebuild: `docker-compose up --build -d jobmanager taskmanager`

#### Custom Configuration
- Flink: Edit `FLINK_PROPERTIES` in `docker-compose.yml`
- MySQL: Place scripts in `sql-scripts/` directory
- Doris: Modify `doris/*/conf/` configuration files

### 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

<a name="中文文档"></a>
## 🇨🇳 中文文档

一个集成了 Apache Paimon 连接器的综合性 Apache Flink 流处理平台演示项目，使用 Docker Compose 进行容器化部署，适合生产环境使用。

### 📋 目录

- [功能特性](#-功能特性)
- [系统架构](#-系统架构)
- [环境要求](#-环境要求)
- [快速开始](#-快速开始)
- [服务概览](#-服务概览)
- [配置说明](#-配置说明)
- [开发指南](#-开发指南)
- [使用示例](#-使用示例)
- [故障排查](#-故障排查)
- [贡献指南](#-贡献指南)
- [许可证](#-许可证)

### ✨ 功能特性

- 🚀 **一键部署** - 通过 Docker Compose 自动构建和启动
- 📦 **最新技术栈** - Flink 1.20.1 + Java 17 + Paimon 1.0.0 最佳性能
- 🏗️ **完整数据栈** - Flink + Kafka + MySQL + Doris + Redis
- 🔧 **生产就绪** - 容器化部署，配置合理
- 🛠️ **开发友好** - 易于扩展自定义 JAR 和配置
- 📊 **多种数据源** - 支持各种输入输出连接器
- 🔄 **流式处理** - 实时数据处理能力
- 📈 **监控就绪** - 内置所有组件的 Web UI
- ⚡ **现代化 API** - 使用最新 Flink Configuration API 和 Jackson JSON 处理
- 🔒 **安全增强** - 移除过时的 FastJSON，改进依赖管理

### 🏗️ 系统架构

```
                    ┌─────────────────────────────────────────┐
                    │           Flink 集群                    │
                    │  ┌─────────────┐   ┌─────────────┐     │
                    │  │JobManager   │───│TaskManager  │     │
                    │  │(主节点)     │   │(工作节点)   │     │
                    │  └─────────────┘   └─────────────┘     │
                    └─────────────┬───────────────────────────┘
                                  │
    ┌─────────────┐              │              ┌─────────────┐
    │   Apache    │──────────────┼──────────────│   Apache    │
    │   Kafka     │              │              │   Doris     │
    │  (流处理)   │              │              │ (分析型DB)  │
    └─────────────┘              │              └─────────────┘
                                  │
    ┌─────────────┐              │              ┌─────────────┐
    │   MySQL     │──────────────┼──────────────│   Redis     │
    │ (事务型DB)  │              │              │  (缓存)     │
    └─────────────┘              │              └─────────────┘
                                  │
                          ┌───────▼────────┐
                          │  Apache Paimon │
                          │   (湖仓存储)   │
                          └────────────────┘
```

### 📋 环境要求

- **Docker** (版本 20.10+) - [安装指南](https://docs.docker.com/get-docker/)
- **Docker Compose** (版本 2.0+) - [安装指南](https://docs.docker.com/compose/install/)
- **Git** - [安装指南](https://git-scm.com/downloads)
- **Java 17** (开发环境) - [安装指南](https://openjdk.org/projects/jdk/17/)
- **Maven 3.6+** (构建工具) - [安装指南](https://maven.apache.org/install.html)
- 至少 **8GB 内存** 和 **10GB** 可用磁盘空间

### 🆕 v1.1.0 版本新特性

#### 🎯 重大升级
- **Apache Flink**: 1.17.1 → **1.20.1** (最新稳定版)
- **Java 运行时**: 11 → **17** (性能和安全性提升)
- **Apache Paimon**: 0.8.2 → **1.0.0** (生产就绪特性，实际使用版本)

#### 🔧 技术改进
- **现代化配置 API**: 使用新的 `Configuration` + `ConfigOptions` 模式
- **安全性增强**: 用 Jackson ObjectMapper 替换 FastJSON
- **依赖管理优化**: 解决版本冲突，添加缺失依赖
- **Docker 优化**: 修复网络冲突，更新基础镜像
- **代码现代化**: 移除所有过时 API 和警告

#### 🚀 性能提升
- **Java 17 优势**: 改进的 GC 性能和内存效率
- **Flink 1.20.1 特性**: 更好的检查点机制和状态管理
- **连接器更新**: 最新的 Kafka、JDBC 和 CDC 连接器，稳定性更佳

> 📖 **迁移指南**: 详细升级说明请参考 [CHANGELOG.md](CHANGELOG.md)

### 🚀 快速开始

#### 方式一：自动化部署（推荐）
```bash
# 1. 环境准备：自动安装所有依赖
./scripts/setup.sh

# 2. 克隆仓库
git clone https://github.com/yourusername/flink-demo.git
cd flink-demo

# 3. 企业级构建（包含测试、质量检查）
./scripts/build.sh

# 4. 启动所有服务
docker-compose up -d

# 5. 验证服务状态
docker-compose ps
```

#### 方式二：手动部署
```bash
# 1. 检查依赖环境
java -version  # 需要 Java 11+（推荐Java 17用于开发）
mvn -version   # 需要 Maven 3.6+
docker --version
docker-compose --version

# 2. 克隆仓库
git clone https://github.com/yourusername/flink-demo.git
cd flink-demo

# 3. Maven 构建
mvn clean package -DskipTests

# 4. 启动所有服务 (一键部署)
docker-compose up --build -d

# 5. 验证服务状态
docker-compose ps
```

#### 构建选项
```bash
# 🔥 完整构建（测试 + 质量检查）
./scripts/build.sh

# ⚡ 快速构建（跳过测试）
./scripts/build.sh --quick

# 🐳 跳过 Docker 构建
./scripts/build.sh --skip-docker

# 📖 查看帮助
./scripts/build.sh --help
```

### 🌐 服务访问

| 服务 | 地址 | 默认凭据 ⚠️ |
|------|------|------|
| **Flink 控制台** | http://localhost:8081 | - |
| **MySQL (Adminer)** | http://localhost:8080 | root/root123 |
| **Doris FE** | http://localhost:8030 | root/(空) |
| **StreamPark** | http://localhost:10000 | admin/streampark |

> ⚠️ **安全警告**：以上是演示用默认凭据，**生产环境必须更改**！  
> 📋 参考：[安全配置指南](#-安全配置)

### 🛠️ 服务概览

| 服务 | 版本 | 端口 | 描述 |
|------|------|------|------|
| **Apache Flink** | 1.20.1 | 8081 | 流处理引擎 + Paimon 连接器 |
| **Apache Kafka** | Latest | 9092 | 分布式流处理平台 |
| **MySQL** | 8.0 | 3306 | 关系型数据库，启用 CDC |
| **Apache Doris** | Latest | 8030, 9030 | MPP 分析型数据库 |
| **Redis** | 6.2 | 6379 | 内存数据结构存储 |
| **StreamPark** | 2.1.5 | 10000 | Flink 作业管理平台 |

### 📖 使用示例

#### 🚀 完整 Paimon 快速入门教程

本教程提供了逐步指南来测试 Paimon 的实时数据功能。

**第1步：进入 Flink SQL 客户端**
```bash
# 进入 Flink JobManager 容器
docker exec -it jobmanager bash

# 启动 Flink SQL 客户端
./bin/sql-client.sh
```

**第2步：基础 Paimon 设置（复制即可运行）**
```sql
-- 创建 Paimon 目录
CREATE CATALOG my_catalog WITH (
  'type' = 'paimon',
  'warehouse' = 'file:/warehouse'
);

-- 切换到 Paimon 目录（重要：后续操作必需）
USE CATALOG my_catalog;

-- 创建带主键的主表
-- 注：PRIMARY KEY NOT ENFORCED 表示支持去重但不强制
CREATE TABLE word_count (
  word STRING PRIMARY KEY NOT ENFORCED,
  cnt BIGINT
);

-- 创建数据源表，使用 Flink 内置的 datagen 数据生成器
CREATE TEMPORARY TABLE word_table (
  word STRING
) WITH (
  'connector' = 'datagen',
  'fields.word.length' = '1'  -- 生成单字符单词 (a, b, c, 等)
);

-- 启用检查点以保证容错
SET 'execution.checkpointing.interval' = '10 s';

-- 开始流式作业：插入实时聚合数据
INSERT INTO word_count
SELECT word, COUNT(*) FROM word_table GROUP BY word;
```

**第3步：实时监控结果**

在 INSERT 作业运行时，**打开第二个终端会话**：
```bash
# 打开另一个 SQL 客户端会话
docker exec -it jobmanager ./bin/sql-client.sh
```

```sql
USE CATALOG my_catalog;

-- 查询实时结果（将显示持续增长的计数）
SELECT * FROM word_count;

-- 预期输出（计数会持续增加）：
/*
+----+--------------------------------+----------------------+
| op |                           word |                  cnt |
+----+--------------------------------+----------------------+
| +I |                              a |                   45 |
| +I |                              b |                   38 |
| +I |                              c |                   42 |
| +I |                              d |                   51 |
+----+--------------------------------+----------------------+
*/
```

**第4步：切换到批处理模式（OLAP 查询）**
```sql
-- 配置批处理模式（静态快照）
SET 'sql-client.execution.result-mode' = 'tableau';
RESET 'execution.checkpointing.interval';
SET 'execution.runtime-mode' = 'batch';

-- 查询静态快照（不会自动刷新）
SELECT * FROM word_count ORDER BY cnt DESC LIMIT 5;

-- 这演示了 Paimon 的"存算分离"设计
-- 流模式：实时更新 | 批模式：静态分析
```

**第5步：高级示例 - 业务表**
```sql
-- 创建业务订单表
CREATE TABLE orders (
  order_id BIGINT,
  user_id BIGINT,
  product_id BIGINT,
  order_time TIMESTAMP(3),
  amount DECIMAL(10,2),
  PRIMARY KEY (order_id) NOT ENFORCED
) WITH ('bucket' = '4');

-- 插入示例数据
INSERT INTO orders VALUES
(1001, 101, 201, TIMESTAMP '2024-01-15 10:30:00', 99.99),
(1002, 102, 202, TIMESTAMP '2024-01-15 11:15:00', 149.50),
(1003, 101, 203, TIMESTAMP '2024-01-15 12:00:00', 79.99);

-- 查询数据
SELECT * FROM orders;
```

**第6步：清理与退出**
```sql
-- 可选清理
DROP TABLE word_count;
DROP TABLE orders;

-- 退出 SQL 客户端
QUIT;
```

#### 📊 预期结果与验证

1. **Flink Web UI 状态**：访问 http://localhost:8081 查看运行中的作业
2. **实时增长**：`word_count` 查询结果应显示递增的数字
3. **批流区别**：注意不同模式下查询行为的差异

#### 🔍 故障排查提示

- **目录错误**：创建目录后务必使用 `USE CATALOG my_catalog`
- **无数据**：检查 INSERT 作业是否在 Flink Web UI 中运行
- **权限问题**：确保容器中 `/warehouse` 目录可写

#### 📄 现成的测试脚本

为方便使用，您也可以使用完整的测试脚本：
```bash
# 查看现成的 SQL 脚本
cat examples/paimon-quick-test.sql

# 或在 SQL 客户端中直接执行
```
该脚本包含上述所有命令，并提供中英文详细注释。

#### 🔄 MySQL CDC 到 Paimon 示例
```sql
-- 创建 MySQL CDC 源表
CREATE TABLE mysql_orders (
  order_id BIGINT,
  user_id BIGINT,
  product_id BIGINT,
  order_time TIMESTAMP(3),
  amount DECIMAL(10,2),
  PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc',
  'hostname' = 'mysql',
  'port' = '3306',
  'username' = 'root',
  'password' = 'root123',
  'database-name' = 'ods',
  'table-name' = 'orders'
);

-- 插入到 Paimon 表
INSERT INTO my_catalog.default.orders
SELECT * FROM mysql_orders;
```

### 🔧 开发指南

#### 添加自定义 JAR
1. 将 JAR 文件放入 `flink-jars/` 目录
2. 重新构建：`docker-compose up --build -d jobmanager taskmanager`

#### 自定义配置
- **Flink 配置**：编辑 `docker-compose.yml` 中的 `FLINK_PROPERTIES`
- **MySQL 初始化**：将脚本放入 `sql-scripts/` 目录
- **Doris 配置**：修改 `doris/*/conf/` 目录下的配置文件

#### 项目结构
```
flink-demo/
├── docker-compose.yml          # 主要编排文件
├── flink/
│   └── Dockerfile             # 自定义 Flink 镜像
├── flink-jars/                # 自定义 JAR 文件目录
│   └── paimon-flink-*.jar    # Paimon 连接器
├── doris/                     # Doris 配置
├── sql-scripts/               # MySQL 初始化脚本
├── .dockerignore              # Docker 构建忽略规则
├── README.md                  # 本文件
└── DEPLOYMENT.md              # 详细部署指南
```

### 🔍 故障排查

#### 常见问题

1. **服务无法启动**
   ```bash
   # 查看日志
   docker-compose logs [服务名]
   
   # 重启特定服务
   docker-compose restart [服务名]
   ```

2. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep :8081
   
   # 如需要可修改 docker-compose.yml 中的端口
   ```

3. **资源不足**
   ```bash
   # 检查 Docker 资源
   docker system df
   docker system prune  # 清理未使用的资源
   ```

4. **Paimon JAR 未找到**
   ```bash
   # 验证 JAR 文件是否存在于容器中
   docker exec jobmanager find /opt/flink/lib -name "*paimon*"
   
   # 如有必要重新构建
   docker-compose build --no-cache jobmanager taskmanager
   ```

### 🛡️ 安全配置

⚠️ **重要**：本项目默认配置仅用于开发和演示，**生产环境必须进行安全加固**！

#### 快速安全配置
1. **复制环境变量模板**：
   ```bash
   cp env.template .env
   ```

2. **修改 `.env` 文件中的敏感信息**：
   ```bash
   # 数据库密码（必须修改）
   MYSQL_ROOT_PASSWORD=YourSecurePassword123!
   MYSQL_PASSWORD=YourAppPassword123!
   
   # Redis 密码
   REDIS_PASSWORD=YourRedisPassword123!
   ```

3. **更新 docker-compose.yml 使用环境变量**：
   ```yaml
   environment:
     - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
     - MYSQL_PASSWORD=${MYSQL_PASSWORD}
   ```

#### 生产安全检查清单

- [ ] 🔐 **更改所有默认密码**
- [ ] 🚫 **禁用不必要的端口暴露**
- [ ] 🔒 **启用 SSL/TLS 加密**
- [ ] 👤 **配置访问控制和用户权限**
- [ ] 📝 **启用审计日志**
- [ ] 🏠 **配置网络隔离**
- [ ] 🛡️ **定期安全扫描和更新**

#### 网络安全
```yaml
# 仅内部网络通信，不暴露敏感端口
services:
  mysql:
    ports: []  # 移除端口暴露
  redis:
    ports: []  # 移除端口暴露
```

### 🔧 性能调优

生产环境建议：

1. **增加内存分配**：
   ```yaml
   environment:
     - "FLINK_PROPERTIES=taskmanager.memory.process.size: 2gb"
   ```

2. **调整并行度**：
   ```yaml
   environment:
     - "FLINK_PROPERTIES=parallelism.default: 4"
   ```

3. **配置检查点**：
   ```yaml
   environment:
     - "FLINK_PROPERTIES=execution.checkpointing.interval: 30s"
   ```

4. **质量门禁**：
   ```bash
   # 运行完整质量检查
   mvn clean package -P quality-check
   
   # 代码覆盖率报告
   open target/site/jacoco/index.html
   ```

### 🤝 贡献指南

欢迎贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细信息。

#### 开发流程
1. Fork 仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

### 📄 许可证

本项目基于 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详细信息。

### 🙏 致谢

- [Apache Flink](https://flink.apache.org/) - 流处理框架
- [Apache Paimon](https://paimon.apache.org/) - 湖仓存储系统
- [Apache Kafka](https://kafka.apache.org/) - 分布式流处理平台
- [Apache Doris](https://doris.apache.org/) - MPP 分析型数据库
- [Docker](https://www.docker.com/) - 容器化平台

### 📞 支持

- 📁 [项目结构](./PROJECT_STRUCTURE.md)
- 📚 [部署文档](./DEPLOYMENT.md)
- 🧪 [测试指南](./TESTING_GUIDE.md)
- 📖 [Flink SQL 指南](./FLINK_SQL_COMMANDS_GUIDE.md)
- 🔧 [贡献指南](./CONTRIBUTING.md)
- 🐛 [问题反馈](https://github.com/yourusername/flink-demo/issues)
- 💬 [讨论区](https://github.com/yourusername/flink-demo/discussions)

---

⭐ **如果这个项目对您有帮助，请给个星标！ | Star this repository if it helped you!**

## 🔄 Flink 1.20.1 升级指南

### 重大变更说明

本项目已从 **Apache Flink 1.17.1** 升级至 **Apache Flink 1.20.1**，同时将 **Java 运行时从 11 升级到 17**。

### 升级内容

#### 🚀 核心组件升级
- **Apache Flink**: 1.17.1 → 1.20.1
- **Java 运行时**: 11 → 17  
- **Apache Paimon**: 0.8.2 → 1.0.0 (实际使用版本)
- **连接器版本**: 更新至最新兼容版本

#### 🆕 新功能支持
- **Materialized Tables**: 简化数据管道开发
- **统一文件合并检查点**: 减少小文件数量
- **增强的批处理作业恢复**: JobMaster 故障后恢复
- **新的 Sink API**: SinkFunction 已弃用

#### 🛡️ 安全改进
- 移除 FastJSON，使用安全的 Jackson 库
- 更新所有依赖至最新安全版本

### 迁移步骤

#### 1. 环境准备
确保开发环境安装 Java 17+：

```bash
# 检查 Java 版本
java -version

# 如果使用 SDKMAN
sdk install java 17.0.8-tem
sdk use java 17.0.8-tem
```

#### 2. 重新构建项目
```bash
# 清理旧构建
mvn clean

# 重新构建
mvn compile package

# 构建 Docker 镜像
docker build -t custom-flink:1.20.1-paimon -f flink/Dockerfile .
```

#### 3. 更新 Docker Compose
已自动更新镜像标签为 `custom-flink:1.20.1-paimon`，无需手动修改。

#### 4. 验证升级
```bash
# 启动服务
docker-compose up -d

# 检查 Flink 版本
curl http://localhost:8081/config

# 验证 Paimon 连接器
docker exec jobmanager find /opt/flink/lib -name "*paimon*"
```

### 兼容性说明

#### ✅ 保持兼容
- 现有的 DataStream API 代码
- Kafka/MySQL 连接配置
- 检查点和状态后端配置
- 现有的 SQL 查询和表定义

#### ⚠️ 需要注意
- **JSON 处理**: FastJSON 已替换为 Jackson
- **连接器版本**: 某些连接器可能需要重新测试
- **新检查点功能**: 可选启用文件合并功能

### 新功能使用

#### Materialized Tables (实验性)
```sql
-- 创建物化表
CREATE MATERIALIZED TABLE orders_summary
PARTITIONED BY (ds)
FRESHNESS = INTERVAL '1' HOUR
AS SELECT 
  ds,
  COUNT(*) as order_count,
  SUM(amount) as total_amount
FROM orders 
GROUP BY ds;
```

#### 启用文件合并检查点
```yaml
# flink-conf.yaml
execution.checkpointing.file-merging.enabled: true
```

### 故障排除

#### 常见问题
1. **依赖冲突**: 清理 Maven 缓存 `mvn dependency:purge-local-repository`
2. **连接器问题**: 检查连接器版本兼容性
3. **状态恢复**: 验证检查点存储路径

#### 获得帮助
- 查看 [Flink 1.20 升级指南](https://flink.apache.org/docs/stable/ops/upgrading/)
- 提交 Issue 到项目仓库
- 参考官方迁移文档

--- 
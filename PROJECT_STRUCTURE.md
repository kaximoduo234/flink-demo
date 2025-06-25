# 📁 项目结构说明

本项目基于 Apache Flink + Paimon 构建的实时数据处理平台，采用 Docker Compose 进行容器化部署。

## 🏗️ 核心目录结构

```
flink-demo/
├── 📄 核心文档
│   ├── README.md                    # 项目主文档
│   ├── CHANGELOG.md                 # 版本变更记录
│   ├── CONTRIBUTING.md              # 贡献指南
│   ├── DEPLOYMENT.md                # 部署文档
│   ├── TESTING_GUIDE.md             # 测试指南
│   ├── FLINK_SQL_COMMANDS_GUIDE.md  # Flink SQL 命令指南
│   ├── FLINK_SQL_EXECUTION_GUIDE.md # Flink SQL 执行指南
│   ├── MYSQL_CDC_TEST_GUIDE.md      # MySQL CDC 测试指南
│   └── ZEPPELIN_GUIDE.md            # Zeppelin 使用指南
│
├── 🐳 Docker 配置
│   ├── docker-compose.yml          # 完整功能部署
│   ├── docker-compose.fast.yml     # 快速启动版本
│   ├── docker-compose.ultra-fast.yml # 极速启动版本
│   ├── docker-compose.minimal.yml  # 最小化部署
│   ├── docker-compose.test.yml     # 测试环境
│   └── flink/Dockerfile            # 自定义 Flink 镜像
│
├── 🔧 核心脚本 (scripts/)
│   ├── build.sh                    # 项目构建脚本
│   ├── setup.sh                    # 环境设置脚本
│   ├── deploy_realtime_datawarehouse.sh # 实时数仓部署脚本
│   ├── quick_test.sh               # 快速测试脚本
│   ├── fast_start.sh               # 快速启动脚本
│   ├── minimal_start.sh            # 最小启动脚本
│   ├── ultra_fast_start.sh         # 极速启动脚本
│   ├── flink_sql_client.sh         # Flink SQL 客户端脚本
│   ├── init_catalogs.sh/.sql       # Catalog 初始化脚本
│   ├── setup-*.sh                  # 连接器安装脚本
│   ├── create_mysql_tables.sql     # MySQL 表创建脚本
│   ├── create_starrocks_tables.sql # StarRocks 表创建脚本
│   ├── create_flink_tables.sql     # Flink 表定义脚本
│   └── create_etl_jobs.sql         # ETL 作业脚本
│
├── 📦 依赖和配置
│   ├── pom.xml                     # Maven 项目配置
│   ├── flink-jars/                 # Flink 连接器 JAR 包
│   ├── drivers/                    # 数据库驱动
│   ├── sql-gateway-config/         # SQL Gateway 配置
│   ├── streampark-config/          # StreamPark 配置
│   ├── zeppelin-conf/              # Zeppelin 配置
│   └── env.template                # 环境变量模板
│
├── 💾 数据存储
│   ├── paimon-warehouse/           # Paimon 数据湖存储
│   ├── mysql-data/                 # MySQL 数据目录
│   ├── kafka-data/                 # Kafka 数据目录
│   ├── checkpoints/                # Flink 检查点目录
│   └── starrocks-storage/          # StarRocks 存储目录
│
├── 👨‍💻 应用代码
│   └── src/                        # Java 源代码目录
│       ├── main/java/com/flinkdemo/ # 应用主代码
│       └── test/                   # 测试代码
│
└── 📓 其他配置
    ├── .gitignore                  # Git 忽略文件
    ├── .dockerignore               # Docker 忽略文件
    ├── LICENSE                     # 开源协议
    └── *.zpln                      # Zeppelin 笔记本文件
```

## 🚀 快速开始

### 1. 完整功能部署
```bash
docker-compose up --build -d
```

### 2. 快速开发测试
```bash
./scripts/fast_start.sh
```

### 3. 极速启动（5秒内）
```bash
./scripts/ultra_fast_start.sh
```

## 📋 核心组件

| 组件 | 端口 | 说明 |
|------|------|------|
| Flink JobManager | 8081 | 流处理引擎管理节点 |
| Flink TaskManager | - | 流处理引擎执行节点 |
| SQL Gateway | 8083 | Flink SQL 接口服务 |
| MySQL | 3306 | 业务数据库 |
| StarRocks FE | 9030 | OLAP 查询引擎 |
| Kafka | 9092 | 消息队列 |
| Zeppelin | 8082 | 交互式查询界面 |
| Redis | 6379 | 缓存服务 |

## 🔄 数据流转架构

```
MySQL → Kafka → Paimon → StarRocks
  ↓       ↓        ↓         ↓
业务数据 → 消息流 → 湖仓存储 → OLAP分析
```

## 📖 相关文档

- [🚀 快速开始指南](README.md#quick-start)
- [🔧 部署指南](DEPLOYMENT.md)
- [🧪 测试指南](TESTING_GUIDE.md)
- [📖 SQL 使用指南](FLINK_SQL_COMMANDS_GUIDE.md)
- [🤝 贡献指南](CONTRIBUTING.md) 
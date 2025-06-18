# Flink + Paimon 部署文档

## 概述
本项目使用自定义 Docker 镜像的方式将 Paimon connector 集成到 Flink 中，这是生产环境的推荐方案。

## 架构方案
我们采用了**方案三：自定义 Dockerfile**，具有以下优势：
- ✅ 构建时集成 JAR 文件
- ✅ 启动速度最快
- ✅ 不依赖外部挂载
- ✅ 版本控制友好

## 文件结构
```
flink-demo/
├── flink-jars/
│   └── paimon-flink-1.17-1.2-20250612.003030-39.jar  # Paimon connector
├── flink/
│   └── Dockerfile                                      # 自定义 Flink 镜像
├── docker-compose.yml                                  # 服务编排
└── .dockerignore                                       # 构建时忽略的文件
```

## 部署步骤

### 一键启动（推荐）
```bash
# 自动构建镜像并启动服务
docker-compose up --build -d

# 或者只启动 Flink 集群
docker-compose up --build -d jobmanager taskmanager
```

### 分步部署（可选）

#### 1. 手动构建镜像
```bash
# 构建包含 Paimon connector 的自定义 Flink 镜像
docker build -t custom-flink:1.20.1-paimon -f flink/Dockerfile .
```

#### 2. 验证镜像构建
```bash
# 验证 Paimon JAR 是否正确安装
docker run --rm custom-flink:1.20.1-paimon find /opt/flink/lib -name "*paimon*"
```

#### 3. 启动服务
```bash
# 启动 Flink 集群
docker-compose up -d jobmanager taskmanager

# 检查服务状态
docker ps | grep -E "(jobmanager|taskmanager)"
```

### 4. 验证部署
```bash
# 验证运行中的容器包含 Paimon JAR
docker exec jobmanager find /opt/flink/lib -name "*paimon*"
docker exec taskmanager find /opt/flink/lib -name "*paimon*"

# 访问 Flink Web UI
curl http://localhost:8081
```

## 服务访问
- **Flink Web UI**: http://localhost:8081
- **JobManager RPC**: localhost:6123
- **TaskManager Slots**: 2

## 关键配置

### Dockerfile 关键特性
- 基于官方 `flink:1.20.1-scala_2.12-java17` 镜像
- 自动复制 `flink-jars/*.jar` 到 `/opt/flink/lib/`
- 构建时验证文件复制
- 设置正确的文件权限

### Docker Compose 集成构建
- 集成了自动构建逻辑 (`build` 指令)
- 支持 `docker compose up --build` 一键启动
- 移除了复杂的挂载和脚本
- 使用标准的 Flink 启动命令
- 减少了运行时依赖

## 故障排查

### 1. 镜像构建失败
```bash
# 检查 flink-jars 目录
ls -la flink-jars/

# 清理并重新构建
docker build --no-cache -t custom-flink:1.20.1-paimon -f flink/Dockerfile .
```

### 2. 容器启动失败
```bash
# 检查容器日志
docker logs jobmanager
docker logs taskmanager

# 检查网络配置
docker network ls | grep flink
```

### 3. Paimon connector 不可用
```bash
# 验证 JAR 文件存在
docker exec jobmanager ls -la /opt/flink/lib/paimon*

# 检查文件大小（应该是 ~53MB）
docker exec jobmanager ls -lh /opt/flink/lib/paimon*
```

## 更新 Paimon 版本
1. 替换 `flink-jars/` 目录中的 JAR 文件
2. 重新构建并重启服务：`docker-compose up --build -d jobmanager taskmanager`

## 生产环境建议
- 使用版本标签管理镜像（如 `custom-flink:1.20.1-paimon-v1.0`）
- 配置镜像仓库用于团队协作
- 定期更新和测试 Paimon connector 版本
- 监控容器资源使用情况 
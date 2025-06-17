# Flink CDC Demo Docker 环境

这个Docker Compose配置为Flink CDC演示项目提供了完整的开发环境。

## 服务组件

### 核心服务
- **MySQL 8.0**: 数据库服务器 (端口: 3306)
- **Kafka**: 消息队列 (端口: 9092)
- **Zookeeper**: Kafka协调服务 (端口: 2181)
- **Flink JobManager**: Flink集群管理节点 (端口: 8081)
- **Flink TaskManager**: Flink任务执行节点
- **Apache Doris FE**: 数据仓库前端节点 (端口: 8030/9030)
- **Apache Doris BE**: 数据仓库后端节点 (端口: 8040)
- **Redis**: 内存数据库 (端口: 6379)

### 管理工具
- **Adminer**: 数据库管理界面 (端口: 8080)
- **Doris FE Web UI**: 数据仓库管理界面 (端口: 8030)

## 快速开始

### 1. 启动环境
```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 2. 验证服务
- **Flink Web UI**: http://localhost:8081
- **Doris FE Web UI**: http://localhost:8030
- **Adminer (数据库管理)**: http://localhost:8080
  - 系统: MySQL
  - 服务器: mysql
  - 用户名: root
  - 密码: root123
  - 数据库: ods

### 3. 数据库连接信息

#### MySQL
- **主机**: localhost
- **端口**: 3306
- **数据库**: ods
- **用户名**: root
- **密码**: root123

#### Apache Doris
- **FE Web UI**: http://localhost:8030
- **MySQL协议端口**: 9030
- **连接命令**: `mysql -uroot -P9030 -hlocalhost`
- **默认数据库**: ods_doris

### 4. Kafka连接信息
- **Broker**: localhost:9092
- **Zookeeper**: localhost:2181

### 5. Redis连接信息
- **主机**: localhost
- **端口**: 6379

## 项目构建和部署

### 1. 编译项目
```bash
mvn clean package -DskipTests
```

### 2. 构建自定义Doris镜像
```bash
# 构建包含正确Java环境的Doris镜像
cd doris
./build-images.sh
cd ..
```

### 3. 运行Java应用
```bash
# 确保Docker环境已启动（首次启动会自动构建镜像）
docker-compose up -d --build

# 查看服务启动状态
docker-compose ps

# 查看Doris服务日志
docker-compose logs -f doris-fe
docker-compose logs -f doris-be

# 等待所有服务启动完成（约3-5分钟，包含镜像构建时间）

# 初始化Doris集群（注册BE节点和创建表）
./doris/init-doris.sh

# 运行数据插入程序
java -cp target/classes:target/lib/* com.flinkdemo.cdcdemo.InsertIntoMysql
```

## 数据库表结构

项目会自动创建 `users` 表：
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    birthdate DATE,
    is_active INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## 常用命令

```bash
# 停止所有服务
docker-compose down

# 清理所有数据（包括数据卷）
docker-compose down -v

# 重新构建服务
docker-compose up --build

# 查看特定服务日志
docker-compose logs -f mysql
docker-compose logs -f kafka
docker-compose logs -f jobmanager

# 进入容器
docker-compose exec mysql bash
docker-compose exec kafka bash
```

## 故障排除

### MySQL连接问题
1. 确保MySQL容器已完全启动
2. 检查防火墙设置
3. 验证数据库用户权限

### Kafka连接问题
1. 确保Zookeeper服务正常运行
2. 检查Kafka broker配置
3. 验证网络连接

### Flink任务提交问题
1. 确保JobManager和TaskManager都在运行
2. 检查JAR文件路径
3. 查看Flink Web UI中的任务状态

### Doris集群问题
1. **BE节点未注册**: 运行 `./doris/init-doris.sh` 脚本
2. **连接问题**: 检查服务是否完全启动（`docker-compose ps`）
3. **数据导入失败**: 检查表结构和数据格式是否匹配

### Java环境问题 ✅ 已解决
之前Doris容器启动时出现JAVA_HOME相关错误，现已通过以下方案解决：

1. **自定义Dockerfile**：创建了`doris/fe-dockerfile`和`doris/be-dockerfile`，安装OpenJDK 17
2. **JDK 17配置**：在`fe.conf`和`be.conf`中添加了`JAVA_OPTS_FOR_JDK_17`配置
3. **环境变量设置**：在Docker镜像中正确设置了`JAVA_HOME`和`JDK_VERSION`

**系统验证**：
运行验证脚本检查所有服务状态：
```bash
./verify-system.sh
```

**当前系统状态**：
- ✅ Kafka: 正常运行，主题`Login-User`已创建
- ✅ Flink: JobManager和TaskManager正常运行 
- ✅ Redis: 连接正常
- ✅ Adminer: Web界面正常
- ✅ Doris FE/BE: 成功启动，心跳连接正常
- ✅ MySQL: 容器内运行正常，可通过Adminer或docker访问

### 数据流调试
```bash
# 查看Kafka Topic
docker exec -it kafka kafka-topics.sh --bootstrap-server localhost:9092 --list

# 查看Kafka消息
docker exec -it kafka kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic Login-User --from-beginning

# 查看Doris集群状态
docker exec -it doris-fe mysql -uroot -P9030 -h127.0.0.1 -e "SHOW BACKENDS;"

# 查看Redis数据
docker exec -it redis redis-cli
```

## 开发建议

1. **数据持久化**: 数据存储在 `mysql-data` 和 `kafka-data` 目录中
2. **性能调优**: 根据需要调整各服务的内存配置
3. **网络配置**: 所有服务都在 `flink-network` 网络中，可以通过服务名相互访问
4. **安全性**: 生产环境中请修改默认密码和配置 
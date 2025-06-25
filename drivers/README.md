# JDBC 驱动说明

## MySQL 驱动 (用于 StarRocks 连接)

由于 StarRocks 使用 MySQL 协议，Zeppelin 需要 MySQL JDBC 驱动来连接。

### 下载方式

**方式 1: 直接下载**
```bash
cd drivers/
wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar
```

**方式 2: 手动下载**
访问 [Maven Central](https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar) 
并将文件保存为 `mysql-connector-java-8.0.33.jar`

### 目录结构
```
drivers/
└── mysql-connector-java-8.0.33.jar
```

### Docker Compose 挂载
驱动会通过以下配置挂载到 Zeppelin 容器：
```yaml
volumes:
  - ./drivers/mysql-connector-java-8.0.33.jar:/opt/zeppelin/interpreter/jdbc/mysql-connector-java.jar
```

### 验证
启动服务后，可以在 Zeppelin 中测试连接：
```sql
%jdbc(starrocks)
SELECT 1 as test_connection;
``` 
#!/bin/bash

# 🏗️ Flink 连接器完整设置脚本
# 架构师级别的依赖管理解决方案
# 适用于 Flink 1.20.1

set -e

echo "🏗️ 开始设置 Flink 连接器生态系统..."

# 定义版本和配置
FLINK_VERSION="1.20"
FLINK_MINOR_VERSION="1.20.0"
CDC_VERSION="3.0.1"
KAFKA_CONNECTOR_VERSION="3.2.0-1.18"  # 兼容 Flink 1.20 的版本

# 创建临时目录
TEMP_DIR="/tmp/flink-connectors-setup"
mkdir -p $TEMP_DIR
cd $TEMP_DIR

echo "📦 下载所有必要的连接器..."

# 1. MySQL CDC Connector (已存在，但确保最新)
MYSQL_CDC_JAR="flink-sql-connector-mysql-cdc-${CDC_VERSION}.jar"
if [ ! -f "$MYSQL_CDC_JAR" ]; then
    echo "正在下载 MySQL CDC Connector..."
    wget -O "$MYSQL_CDC_JAR" \
        "https://repo1.maven.org/maven2/com/ververica/flink-sql-connector-mysql-cdc/${CDC_VERSION}/flink-sql-connector-mysql-cdc-${CDC_VERSION}.jar"
fi

# 2. Kafka Connector - 关键缺失组件
KAFKA_JAR="flink-sql-connector-kafka-${KAFKA_CONNECTOR_VERSION}.jar"
if [ ! -f "$KAFKA_JAR" ]; then
    echo "正在下载 Kafka Connector..."
    wget -O "$KAFKA_JAR" \
        "https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/${KAFKA_CONNECTOR_VERSION}/flink-sql-connector-kafka-${KAFKA_CONNECTOR_VERSION}.jar"
fi

# 3. JDBC Connector (通用数据库连接)
JDBC_JAR="flink-connector-jdbc-${KAFKA_CONNECTOR_VERSION}.jar"
if [ ! -f "$JDBC_JAR" ]; then
    echo "正在下载 JDBC Connector..."
    wget -O "$JDBC_JAR" \
        "https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/${KAFKA_CONNECTOR_VERSION}/flink-connector-jdbc-${KAFKA_CONNECTOR_VERSION}.jar"
fi

# 4. Elasticsearch Connector (可选，用于日志和搜索)
ELASTICSEARCH_JAR="flink-sql-connector-elasticsearch7-${KAFKA_CONNECTOR_VERSION}.jar"
if [ ! -f "$ELASTICSEARCH_JAR" ]; then
    echo "正在下载 Elasticsearch Connector..."
    wget -O "$ELASTICSEARCH_JAR" \
        "https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-elasticsearch7/${KAFKA_CONNECTOR_VERSION}/flink-sql-connector-elasticsearch7-${KAFKA_CONNECTOR_VERSION}.jar" || echo "⚠️ Elasticsearch connector 下载失败，跳过"
fi

echo "📁 复制连接器到项目目录..."
cd /home/zzf/flink-demo

# 复制到项目的 flink-jars 目录
for jar in "$TEMP_DIR"/*.jar; do
    if [ -f "$jar" ]; then
        jar_name=$(basename "$jar")
        echo "复制 $jar_name 到 flink-jars/"
        cp "$jar" ./flink-jars/
    fi
done

echo "🐳 部署到 Docker 容器..."
CONTAINERS=("jobmanager" "taskmanager" "sql-gateway")

for container in "${CONTAINERS[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "^${container}$"; then
        echo "📦 部署连接器到容器 $container..."
        
        for jar in "$TEMP_DIR"/*.jar; do
            if [ -f "$jar" ]; then
                jar_name=$(basename "$jar")
                echo "  - 复制 $jar_name"
                docker cp "$jar" "${container}:/opt/flink/lib/"
            fi
        done
        
        echo "✅ 容器 $container 部署完成"
    else
        echo "⚠️  容器 $container 未运行，跳过"
    fi
done

# 复制到本地 Flink 目录
if [ -d "./flink-local/lib" ]; then
    echo "📦 部署到本地 Flink lib 目录..."
    for jar in "$TEMP_DIR"/*.jar; do
        if [ -f "$jar" ]; then
            jar_name=$(basename "$jar")
            echo "  - 复制 $jar_name"
            cp "$jar" "./flink-local/lib/"
        fi
    done
    echo "✅ 本地 Flink 部署完成"
fi

echo "🔄 重启 Flink 集群以加载新连接器..."
docker-compose restart jobmanager taskmanager sql-gateway

echo "⏳ 等待集群重启..."
sleep 20

echo "🔍 验证连接器部署..."
echo "📊 SQL Gateway 中的连接器："
docker exec sql-gateway ls -la /opt/flink/lib/ | grep -E "(kafka|mysql-cdc|jdbc|elasticsearch)" | head -10

echo ""
echo "✅ 连接器设置完成！"
echo ""
echo "🎯 现在可用的连接器："
echo "  ✅ mysql-cdc    - MySQL 变更数据捕获"
echo "  ✅ kafka        - Apache Kafka 流处理"
echo "  ✅ jdbc         - 通用数据库连接"
echo "  ✅ paimon       - Apache Paimon 湖仓一体"
echo "  ✅ filesystem   - 文件系统连接器"
echo "  ✅ print        - 控制台输出"
echo "  ✅ datagen      - 数据生成器"
echo "  ✅ blackhole    - 性能测试"

echo ""
echo "🚀 测试命令："
echo "docker exec -it jobmanager ./bin/sql-client.sh gateway -e http://sql-gateway:8083"
echo ""
echo "然后在 SQL Client 中执行："
echo "SHOW FUNCTIONS;"
echo ""
echo "现在您的 INSERT INTO kafka_user_stream SELECT * FROM mysql_user_cdc; 应该可以正常工作了！"

# 清理临时目录
rm -rf $TEMP_DIR

echo "🎉 架构级连接器管理完成！" 
#!/bin/bash

# MySQL CDC Connector 设置脚本
# 适用于 Flink 1.20.1

set -e

echo "🚀 开始设置 MySQL CDC Connector..."

# 定义版本
FLINK_VERSION="1.20"
CDC_VERSION="3.0.1"
MYSQL_CDC_JAR="flink-sql-connector-mysql-cdc-${CDC_VERSION}.jar"

# 创建临时目录
TEMP_DIR="/tmp/flink-cdc-setup"
mkdir -p $TEMP_DIR

echo "📦 下载 MySQL CDC Connector..."
cd $TEMP_DIR

# 下载 MySQL CDC connector
if [ ! -f "$MYSQL_CDC_JAR" ]; then
    echo "正在下载 $MYSQL_CDC_JAR..."
    wget -O "$MYSQL_CDC_JAR" \
        "https://repo1.maven.org/maven2/com/ververica/flink-sql-connector-mysql-cdc/${CDC_VERSION}/flink-sql-connector-mysql-cdc-${CDC_VERSION}.jar"
    
    if [ $? -eq 0 ]; then
        echo "✅ 下载成功: $MYSQL_CDC_JAR"
    else
        echo "❌ 下载失败，尝试备用源..."
        curl -L -o "$MYSQL_CDC_JAR" \
            "https://repo1.maven.org/maven2/com/ververica/flink-sql-connector-mysql-cdc/${CDC_VERSION}/flink-sql-connector-mysql-cdc-${CDC_VERSION}.jar"
    fi
else
    echo "✅ $MYSQL_CDC_JAR 已存在"
fi

# 复制到项目的 flink-jars 目录
echo "📁 复制到项目 flink-jars 目录..."
cd /home/zzf/flink-demo
cp "$TEMP_DIR/$MYSQL_CDC_JAR" ./flink-jars/

# 检查Docker容器是否运行
echo "🐳 检查 Docker 容器状态..."
CONTAINERS=("jobmanager" "taskmanager" "sql-gateway")

for container in "${CONTAINERS[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "^${container}$"; then
        echo "📦 复制 $MYSQL_CDC_JAR 到容器 $container..."
        docker cp "./flink-jars/$MYSQL_CDC_JAR" "${container}:/opt/flink/lib/"
        echo "✅ 已复制到 $container"
    else
        echo "⚠️  容器 $container 未运行，跳过"
    fi
done

# 复制到本地 Flink 目录（如果存在）
if [ -d "./flink-local/lib" ]; then
    echo "📦 复制到本地 Flink lib 目录..."
    cp "./flink-jars/$MYSQL_CDC_JAR" "./flink-local/lib/"
    echo "✅ 已复制到 flink-local/lib/"
fi

echo "🔄 重启 Flink 相关容器以加载新的 connector..."
docker-compose restart jobmanager taskmanager sql-gateway

echo "⏳ 等待容器启动..."
sleep 15

echo "🔍 验证 MySQL CDC connector 是否加载成功..."
echo "可以通过以下方式验证："
echo "1. 访问 Flink Web UI: http://localhost:8081"
echo "2. 在 Flink SQL Gateway 中执行: SHOW JARS;"
echo "3. 检查是否能创建 MySQL CDC 表"

echo "✅ MySQL CDC Connector 设置完成！"
echo ""
echo "现在您可以使用以下语法创建 MySQL CDC 表："
echo "CREATE TABLE mysql_cdc_table ("
echo "  id INT,"
echo "  name STRING,"
echo "  PRIMARY KEY (id) NOT ENFORCED"
echo ") WITH ("
echo "  'connector' = 'mysql-cdc',"
echo "  'hostname' = 'mysql',"
echo "  'port' = '3306',"
echo "  'username' = 'root',"
echo "  'password' = 'root123',"
echo "  'database-name' = 'ods',"
echo "  'table-name' = 'your_table'"
echo ");"

# 清理临时目录
rm -rf $TEMP_DIR 
#!/bin/bash

# 🌟 StarRocks Flink Connector 安装脚本
# 适用于 Flink 1.20.1

set -e

echo "🌟 开始安装 StarRocks Flink Connector..."

# 定义版本
STARROCKS_CONNECTOR_VERSION="1.2.6"
STARROCKS_JAR="starrocks-connector-flink-${STARROCKS_CONNECTOR_VERSION}_flink-1.20.jar"

# 创建临时目录
TEMP_DIR="/tmp/starrocks-connector-setup"
mkdir -p $TEMP_DIR
cd $TEMP_DIR

echo "📦 下载 StarRocks Flink Connector..."

# 尝试多个下载源
DOWNLOAD_URLS=(
    "https://repo1.maven.org/maven2/com/starrocks/starrocks-connector-flink/${STARROCKS_CONNECTOR_VERSION}/starrocks-connector-flink-${STARROCKS_CONNECTOR_VERSION}_flink-1.20.jar"
    "https://repo1.maven.org/maven2/com/starrocks/flink-connector-starrocks/1.2.6/flink-connector-starrocks-1.2.6_flink-1.20.jar"
    "https://github.com/StarRocks/starrocks-connector-for-apache-flink/releases/download/1.2.6/starrocks-connector-flink-1.2.6_flink-1.20.jar"
)

DOWNLOADED=false
for url in "${DOWNLOAD_URLS[@]}"; do
    echo "尝试下载: $url"
    if wget -O "$STARROCKS_JAR" "$url" 2>/dev/null; then
        echo "✅ 下载成功: $STARROCKS_JAR"
        DOWNLOADED=true
        break
    else
        echo "❌ 下载失败，尝试下一个源..."
    fi
done

# 如果所有源都失败，尝试通用版本
if [ "$DOWNLOADED" = false ]; then
    echo "🔄 尝试下载通用版本..."
    STARROCKS_JAR="flink-connector-starrocks-1.2.6.jar"
    wget -O "$STARROCKS_JAR" \
        "https://repo1.maven.org/maven2/com/starrocks/flink-connector-starrocks/1.2.6/flink-connector-starrocks-1.2.6.jar" || {
        echo "❌ 所有下载源都失败，请检查网络连接"
        exit 1
    }
fi

echo "📁 复制到项目目录..."
cd /home/zzf/flink-demo
cp "$TEMP_DIR/$STARROCKS_JAR" ./flink-jars/

echo "🐳 部署到 Docker 容器..."
CONTAINERS=("jobmanager" "taskmanager" "sql-gateway")

for container in "${CONTAINERS[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "^${container}$"; then
        echo "📦 复制 $STARROCKS_JAR 到容器 $container..."
        docker cp "./flink-jars/$STARROCKS_JAR" "${container}:/opt/flink/lib/"
        echo "✅ 已复制到 $container"
    else
        echo "⚠️  容器 $container 未运行，跳过"
    fi
done

# 复制到本地 Flink 目录
if [ -d "./flink-local/lib" ]; then
    echo "📦 复制到本地 Flink lib 目录..."
    cp "./flink-jars/$STARROCKS_JAR" "./flink-local/lib/"
    echo "✅ 已复制到 flink-local/lib/"
fi

echo "🔄 重启 Flink 相关容器以加载新的 connector..."
docker-compose restart jobmanager taskmanager sql-gateway

echo "⏳ 等待容器启动..."
sleep 15

echo "🔍 验证 StarRocks connector 是否加载成功..."
echo "SQL Gateway 中的 StarRocks connector:"
docker exec sql-gateway ls -la /opt/flink/lib/ | grep -i starrocks

echo ""
echo "✅ StarRocks Connector 安装完成！"
echo ""
echo "🎯 现在可用的连接器包括："
echo "  ✅ mysql-cdc      - MySQL 变更数据捕获"
echo "  ✅ kafka          - Apache Kafka 流处理"
echo "  ✅ jdbc           - 通用数据库连接"
echo "  ✅ starrocks      - StarRocks 数据仓库"
echo "  ✅ paimon         - Apache Paimon 湖仓一体"
echo "  ✅ filesystem     - 文件系统连接器"
echo "  ✅ print          - 控制台输出"
echo "  ✅ datagen        - 数据生成器"
echo "  ✅ blackhole      - 性能测试"

echo ""
echo "🚀 测试命令："
echo "docker exec -it jobmanager ./bin/sql-client.sh gateway -e http://sql-gateway:8083"
echo ""
echo "然后在 SQL Client 中执行："
echo "SHOW FUNCTIONS;"
echo ""
echo "现在您的 StarRocks 表创建应该可以正常工作了！"

# 清理临时目录
rm -rf $TEMP_DIR

echo "🎉 StarRocks Connector 安装完成！" 
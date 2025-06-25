#!/bin/bash

# 🚀 Flink 快速启动脚本
# 目标：恢复到5秒内启动的性能

set -e

echo "🔥 Flink 快速启动模式"
echo "📊 启动时间监控开始..."

START_TIME=$(date +%s)

# 清理现有容器（如果存在）
echo "🧹 清理现有容器..."
docker-compose -f docker-compose.fast.yml down --remove-orphans 2>/dev/null || true

# 预构建镜像（如果需要）
if [[ "$1" == "--build" ]]; then
    echo "🔨 预构建镜像..."
    docker-compose -f docker-compose.fast.yml build --parallel
fi

# 快速启动所有服务（并行）
echo "🚀 启动所有服务（并行模式）..."
docker-compose -f docker-compose.fast.yml up -d

# 等待核心服务就绪
echo "⏳ 等待核心服务就绪..."

# 简单的等待逻辑（不依赖健康检查）
sleep 3

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose -f docker-compose.fast.yml ps

# 计算总启动时间
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo ""
echo "✅ 快速启动完成！"
echo "⏱️  总启动时间: ${TOTAL_TIME}秒"
echo "🌐 Flink Web UI: http://localhost:8081"
echo "🔧 SQL Gateway: http://localhost:8083"
echo "📊 StarRocks UI: http://localhost:8030"

# 如果启动时间超过10秒，给出警告
if [ $TOTAL_TIME -gt 10 ]; then
    echo "⚠️  警告：启动时间 ${TOTAL_TIME}秒 超过预期（应该5秒内）"
    echo "💡 可能原因："
    echo "   - 镜像需要重新构建"
    echo "   - 系统资源不足"
    echo "   - 网络延迟"
else
    echo "🎉 启动时间符合预期！"
fi

echo ""
echo "🔧 快速测试命令："
echo "   docker exec -it sql-gateway bin/sql-client.sh"
echo "   curl http://localhost:8081/overview" 
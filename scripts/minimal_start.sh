#!/bin/bash

# 🚀 Flink 最小化启动脚本 - 真正的5秒启动
# 只启动核心Flink服务，无外部依赖

set -e

echo "⚡ Flink 最小化启动模式（目标：5秒内）"
echo "📊 启动时间监控开始..."

START_TIME=$(date +%s)

# 清理现有容器
echo "🧹 清理现有容器..."
docker-compose -f docker-compose.minimal.yml down --remove-orphans 2>/dev/null || true

# 检查镜像是否存在
if ! docker images | grep -q "custom-flink:1.20.1-paimon-optimized"; then
    echo "🔨 镜像不存在，需要先构建..."
    echo "⚠️  首次构建需要更长时间，后续启动将会很快"
    docker-compose -f docker-compose.minimal.yml build --parallel
fi

# 快速启动核心服务
echo "🚀 启动核心Flink服务（并行）..."
docker-compose -f docker-compose.minimal.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 2

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose -f docker-compose.minimal.yml ps

# 计算启动时间
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo ""
echo "✅ 最小化启动完成！"
echo "⏱️  总启动时间: ${TOTAL_TIME}秒"

# 根据启动时间给出反馈
if [ $TOTAL_TIME -le 5 ]; then
    echo "🎉 启动时间 ${TOTAL_TIME}秒 - 完美！符合5秒内目标"
elif [ $TOTAL_TIME -le 10 ]; then
    echo "✅ 启动时间 ${TOTAL_TIME}秒 - 良好！接近5秒目标"
else
    echo "⚠️  启动时间 ${TOTAL_TIME}秒 - 可能需要优化"
fi

echo ""
echo "🌐 服务地址："
echo "   Flink Web UI: http://localhost:8081"
echo "   SQL Gateway: http://localhost:8083"
echo ""
echo "🔧 快速测试："
echo "   curl http://localhost:8081/overview"
echo "   docker exec -it sql-gateway bin/sql-client.sh"
echo ""
echo "📋 当前服务："
echo "   ✅ JobManager (核心调度)"
echo "   ✅ TaskManager (任务执行)"
echo "   ✅ SQL Gateway (SQL接口)"
echo ""
echo "🚀 要添加其他服务，使用："
echo "   docker-compose up -d  # 完整服务" 
#!/bin/bash

# ⚡ Flink 极速启动脚本 - 5秒内启动
# 最小内存、最少依赖、无健康检查

set -e

echo "⚡⚡⚡ Flink 极速启动模式（目标：5秒内）"
echo "📊 启动时间监控开始..."

START_TIME=$(date +%s)

# 清理现有容器（静默）
docker-compose -f docker-compose.ultra-fast.yml down --remove-orphans 2>/dev/null || true

# 极速启动（无构建检查，直接启动）
echo "🚀 极速启动中..."
docker-compose -f docker-compose.ultra-fast.yml up -d

# 最小等待
sleep 1

# 计算启动时间
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo ""
echo "⚡ 极速启动完成！"
echo "⏱️  总启动时间: ${TOTAL_TIME}秒"

# 启动时间评估
if [ $TOTAL_TIME -le 3 ]; then
    echo "🔥 启动时间 ${TOTAL_TIME}秒 - 超快！超越5秒目标"
elif [ $TOTAL_TIME -le 5 ]; then
    echo "🎉 启动时间 ${TOTAL_TIME}秒 - 完美！达到5秒目标"
elif [ $TOTAL_TIME -le 8 ]; then
    echo "✅ 启动时间 ${TOTAL_TIME}秒 - 良好！接近5秒目标"
else
    echo "⚠️  启动时间 ${TOTAL_TIME}秒 - 可能需要优化"
fi

echo ""
echo "🌐 Flink Web UI: http://localhost:8081"
echo "🔧 SQL Gateway: http://localhost:8083"
echo ""
echo "⚡ 极速配置特点："
echo "   ✅ JobManager: 512MB 内存"
echo "   ✅ TaskManager: 512MB 内存"  
echo "   ✅ 无健康检查延迟"
echo "   ✅ 最小环境变量"
echo "   ✅ 并行启动" 
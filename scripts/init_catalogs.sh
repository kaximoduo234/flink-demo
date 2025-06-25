#!/bin/bash

# ====================================================================
# Flink Catalog 自动初始化脚本
# 用途：容器启动时自动配置 Paimon catalog，避免每次手动执行
# 调用：docker-compose 启动时或手动执行
# ====================================================================

set -e

echo "🚀 开始初始化 Flink Catalogs..."

# 等待 Flink 集群启动
echo "⏳ 等待 Flink JobManager 启动..."
until curl -s http://jobmanager:8081/overview > /dev/null 2>&1; do
    echo "   等待 Flink JobManager 响应..."
    sleep 5
done

echo "✅ Flink JobManager 已启动"

# 等待 SQL Gateway 启动
echo "⏳ 等待 SQL Gateway 启动..."
until curl -s http://sql-gateway:8083/v1/info > /dev/null 2>&1; do
    echo "   等待 SQL Gateway 响应..."
    sleep 5
done

echo "✅ SQL Gateway 已启动"

# 执行 catalog 初始化 SQL
echo "📊 执行 Catalog 初始化..."

# 创建会话（静默模式，不显示进度）
echo "📝 创建SQL会话..."
if curl -s -X POST http://sql-gateway:8083/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{"properties": {"execution.runtime-mode": "streaming"}}' \
  > /tmp/session.json; then
    echo "✅ 会话创建成功"
else
    echo "❌ 会话创建失败"
    exit 1
fi

# 提取会话ID（使用sed替代jq）
SESSION_HANDLE=$(cat /tmp/session.json | sed -n 's/.*"sessionHandle":"\([^"]*\)".*/\1/p')

if [ -z "$SESSION_HANDLE" ]; then
    echo "❌ 无法获取会话句柄，初始化失败"
    echo "会话响应内容:"
    cat /tmp/session.json
    exit 1
fi

echo "📝 会话ID: $SESSION_HANDLE"

# 执行CREATE CATALOG语句（静默模式）
echo "🔧 执行 CREATE CATALOG 语句..."
if curl -s -X POST "http://sql-gateway:8083/v1/sessions/$SESSION_HANDLE/statements" \
  -H "Content-Type: application/json" \
  -d '{"statement": "CREATE CATALOG IF NOT EXISTS paimon_catalog WITH (\"type\" = \"paimon\", \"warehouse\" = \"file:/warehouse\");"}' \
  > /tmp/create_result.json; then
    
    # 检查是否有错误
    if grep -q '"status": "ERROR"' /tmp/create_result.json; then
        echo "❌ CREATE CATALOG 执行失败"
        cat /tmp/create_result.json
        exit 1
    else
        echo "✅ CREATE CATALOG 执行成功"
    fi
else
    echo "❌ CREATE CATALOG 请求失败"
    exit 1
fi

# 验证 SHOW CATALOGS（静默模式）
echo "🔍 验证 SHOW CATALOGS..."
if curl -s -X POST "http://sql-gateway:8083/v1/sessions/$SESSION_HANDLE/statements" \
  -H "Content-Type: application/json" \
  -d '{"statement": "SHOW CATALOGS;"}' \
  > /tmp/show_result.json; then
    
    # 检查是否有错误
    if grep -q '"status": "ERROR"' /tmp/show_result.json; then
        echo "❌ SHOW CATALOGS 执行失败"
        cat /tmp/show_result.json
        exit 1
    else
        echo "✅ SHOW CATALOGS 验证成功"
    fi
else
    echo "❌ SHOW CATALOGS 请求失败"
    exit 1
fi

# 清理临时文件
rm -f /tmp/session.json /tmp/create_result.json /tmp/show_result.json

echo "🎉 Catalog 初始化完成！"
echo "💡 现在可以直接使用 'USE CATALOG paimon_catalog' 而无需重新创建"
echo "✅ 初始化脚本执行完成！" 
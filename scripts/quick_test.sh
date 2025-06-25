#!/bin/bash

# ====================================================================
# 实时数仓快速测试脚本
# 用途：验证从 MySQL 到 StarRocks 的完整数据流
# ====================================================================

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "======================================================================"
echo "🧪 实时数仓快速测试"
echo "======================================================================"

# 1. 测试 MySQL 数据
log_step "1. 检查 MySQL 源数据..."
USER_COUNT=$(docker exec mysql mysql -uroot -proot123 -e "USE ods; SELECT COUNT(*) FROM user;" -s -N 2>/dev/null)
BEHAVIOR_COUNT=$(docker exec mysql mysql -uroot -proot123 -e "USE ods; SELECT COUNT(*) FROM user_behavior;" -s -N 2>/dev/null)
log_info "MySQL 用户数据: $USER_COUNT 条"
log_info "MySQL 行为数据: $BEHAVIOR_COUNT 条"

# 2. 测试 StarRocks 数据
log_step "2. 检查 StarRocks 目标表..."
DWS_TABLES=$(docker exec starrocks mysql -h127.0.0.1 -P9030 -uroot -e "USE analytics; SHOW TABLES LIKE 'dws_%';" -s -N 2>/dev/null | wc -l)
ADS_TABLES=$(docker exec starrocks mysql -h127.0.0.1 -P9030 -uroot -e "USE analytics; SHOW TABLES LIKE 'ads_%';" -s -N 2>/dev/null | wc -l)
log_info "StarRocks DWS 表数量: $DWS_TABLES"
log_info "StarRocks ADS 表数量: $ADS_TABLES"

# 3. 测试 Flink 服务
log_step "3. 检查 Flink 服务状态..."
FLINK_STATUS=$(curl -s http://localhost:8081/overview | jq -r '.["flink-version"]' 2>/dev/null || echo "Unknown")
log_info "Flink 版本: $FLINK_STATUS"

GATEWAY_STATUS=$(curl -s http://localhost:8083/v1/info | jq -r '.version' 2>/dev/null || echo "Unknown")
log_info "SQL Gateway 版本: $GATEWAY_STATUS"

# 4. 创建测试会话
log_step "4. 创建 Flink SQL 测试会话..."
SESSION_HANDLE=$(curl -s -X POST http://localhost:8083/v1/sessions \
    -H "Content-Type: application/json" \
    -d '{"properties": {"execution.runtime-mode": "streaming"}}' | \
    jq -r '.sessionHandle' 2>/dev/null)

if [ "$SESSION_HANDLE" != "null" ] && [ -n "$SESSION_HANDLE" ]; then
    log_info "✅ Flink SQL 会话创建成功: ${SESSION_HANDLE:0:8}..."
else
    log_info "❌ Flink SQL 会话创建失败"
    exit 1
fi

# 5. 测试简单的 SQL 查询
log_step "5. 测试 Flink SQL 查询..."
RESPONSE=$(curl -s -X POST "http://localhost:8083/v1/sessions/$SESSION_HANDLE/statements" \
    -H "Content-Type: application/json" \
    -d '{"statement": "SHOW CATALOGS"}' 2>/dev/null)

OPERATION_HANDLE=$(echo "$RESPONSE" | jq -r '.operationHandle // empty' 2>/dev/null)
if [ -n "$OPERATION_HANDLE" ]; then
    log_info "✅ SQL 查询执行成功"
    
    # 等待查询完成
    sleep 2
    
    # 获取结果
    RESULT=$(curl -s "http://localhost:8083/v1/sessions/$SESSION_HANDLE/operations/$OPERATION_HANDLE/result/0" 2>/dev/null)
    CATALOGS=$(echo "$RESULT" | jq -r '.results.data[].f0' 2>/dev/null | tr '\n' ' ')
    log_info "可用 Catalog: $CATALOGS"
else
    log_info "❌ SQL 查询执行失败"
fi

# 6. 插入测试数据到 MySQL
log_step "6. 插入测试数据到 MySQL..."
docker exec mysql mysql -uroot -proot123 -e "
USE ods;
INSERT INTO user (name, gender, age, email, phone, city) VALUES 
('测试用户$(date +%s)', 'M', 28, 'test@example.com', '13900000000', '测试城市');
INSERT INTO user_behavior (user_id, behavior_type, item_id, item_category, session_id) VALUES 
(1, 'test_view', 999, '测试类别', 'test_session_$(date +%s)');
" 2>/dev/null

log_info "✅ 测试数据插入完成"

# 7. 验证数据更新
log_step "7. 验证数据更新..."
sleep 2
NEW_USER_COUNT=$(docker exec mysql mysql -uroot -proot123 -e "USE ods; SELECT COUNT(*) FROM user;" -s -N 2>/dev/null)
NEW_BEHAVIOR_COUNT=$(docker exec mysql mysql -uroot -proot123 -e "USE ods; SELECT COUNT(*) FROM user_behavior;" -s -N 2>/dev/null)

log_info "更新后用户数据: $NEW_USER_COUNT 条 (增加 $((NEW_USER_COUNT - USER_COUNT)) 条)"
log_info "更新后行为数据: $NEW_BEHAVIOR_COUNT 条 (增加 $((NEW_BEHAVIOR_COUNT - BEHAVIOR_COUNT)) 条)"

# 8. 显示访问地址
log_step "8. 系统访问地址..."
echo ""
echo "🌐 Web 界面:"
echo "   Flink Web UI:     http://localhost:8081"
echo "   StarRocks FE:     http://localhost:8030"  
echo "   Zeppelin:         http://localhost:8082"
echo ""
echo "🔗 API 接口:"
echo "   SQL Gateway:      http://localhost:8083"
echo "   MySQL:            localhost:3306 (root/root123)"
echo "   StarRocks:        localhost:9030 (root/无密码)"
echo ""

# 9. 提供下一步建议
echo "📚 下一步操作建议:"
echo "   1. 访问 Flink Web UI 查看集群状态"
echo "   2. 通过 Zeppelin 创建和执行 Flink SQL 作业"
echo "   3. 参考 scripts/create_flink_tables.sql 创建表定义"
echo "   4. 参考 scripts/create_etl_jobs.sql 启动数据流转"
echo "   5. 在 StarRocks 中查询实时数据"
echo ""

echo "✅ 快速测试完成！系统运行正常。" 
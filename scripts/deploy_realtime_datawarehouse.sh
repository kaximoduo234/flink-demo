#!/bin/bash

# ====================================================================
# 实时数仓自动化部署脚本
# 用途：一键部署 MySQL → Kafka → Paimon → StarRocks 实时数仓
# 作者：系统架构师
# 版本：v1.0
# ====================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_step "检查系统依赖..."
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    # 检查 Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    log_info "依赖检查通过"
}

# 启动基础服务
start_infrastructure() {
    log_step "启动基础设施服务..."
    
    # 清理可能存在的网络冲突
    log_info "清理网络配置..."
    docker-compose down 2>/dev/null || true
    docker network prune -f 2>/dev/null || true
    
    # 启动所有服务
    log_info "启动服务容器..."
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动 (60秒)..."
    sleep 60
    
    # 检查服务状态
    log_info "检查服务状态..."
    docker-compose ps
}

# 初始化 MySQL 数据
init_mysql_data() {
    log_step "初始化 MySQL 数据..."
    
    # 等待 MySQL 启动
    log_info "等待 MySQL 启动..."
    until docker exec mysql mysqladmin ping -h"localhost" --silent; do
        sleep 5
    done
    
    # 执行建表脚本
    log_info "执行 MySQL 建表脚本..."
    docker exec -i mysql mysql -uroot -proot123 < scripts/create_mysql_tables.sql
    
    log_info "MySQL 数据初始化完成"
}

# 初始化 StarRocks 数据
init_starrocks_data() {
    log_step "初始化 StarRocks 数据..."
    
    # 等待 StarRocks 启动
    log_info "等待 StarRocks 启动..."
    until docker exec starrocks mysql -h127.0.0.1 -P9030 -uroot -e "SELECT 1" &> /dev/null; do
        sleep 5
    done
    
    # 执行建表脚本
    log_info "执行 StarRocks 建表脚本..."
    docker exec -i starrocks mysql -h127.0.0.1 -P9030 -uroot < scripts/create_starrocks_tables.sql
    
    log_info "StarRocks 数据初始化完成"
}

# 创建 Flink 表
create_flink_tables() {
    log_step "创建 Flink 表定义..."
    
    # 等待 SQL Gateway 启动
    log_info "等待 Flink SQL Gateway 启动..."
    until curl -s http://localhost:8083/v1/info &> /dev/null; do
        sleep 5
    done
    
    # 创建会话
    log_info "创建 Flink SQL 会话..."
    SESSION_HANDLE=$(curl -s -X POST http://localhost:8083/v1/sessions \
        -H "Content-Type: application/json" \
        -d '{"properties": {"execution.runtime-mode": "streaming"}}' | \
        jq -r '.sessionHandle')
    
    if [ "$SESSION_HANDLE" = "null" ] || [ -z "$SESSION_HANDLE" ]; then
        log_error "创建 Flink 会话失败"
        exit 1
    fi
    
    log_info "Flink 会话创建成功: $SESSION_HANDLE"
    
    # 执行建表脚本
    log_info "执行 Flink 建表脚本..."
    
    # 分批执行 SQL 语句
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*-- ]] || [[ -z "${line// }" ]]; then
            continue  # 跳过注释和空行
        fi
        
        if [[ $line == *";" ]]; then
            SQL_STATEMENT+="$line"
            
            # 执行 SQL
            RESPONSE=$(curl -s -X POST "http://localhost:8083/v1/sessions/$SESSION_HANDLE/statements" \
                -H "Content-Type: application/json" \
                -d "{\"statement\": \"$SQL_STATEMENT\"}")
            
            OPERATION_HANDLE=$(echo "$RESPONSE" | jq -r '.operationHandle // empty')
            
            if [ -n "$OPERATION_HANDLE" ]; then
                log_info "执行 SQL: ${SQL_STATEMENT:0:50}..."
                # 等待执行完成
                sleep 2
            else
                log_warn "SQL 执行可能失败: ${SQL_STATEMENT:0:50}..."
            fi
            
            SQL_STATEMENT=""
        else
            SQL_STATEMENT+="$line "
        fi
    done < scripts/create_flink_tables.sql
    
    log_info "Flink 表创建完成"
}

# 启动 ETL 作业
start_etl_jobs() {
    log_step "启动 ETL 数据流转作业..."
    
    log_warn "ETL 作业需要手动启动，请参考 scripts/create_etl_jobs.sql"
    log_info "您可以通过以下方式启动 ETL 作业："
    log_info "1. 访问 Flink Web UI: http://localhost:8081"
    log_info "2. 使用 SQL Gateway: http://localhost:8083"
    log_info "3. 使用 Zeppelin Notebook: http://localhost:8082"
}

# 验证部署
verify_deployment() {
    log_step "验证部署状态..."
    
    # 检查服务端口
    SERVICES=(
        "MySQL:3306"
        "Kafka:9092"
        "Flink Web UI:8081"
        "SQL Gateway:8083"
        "StarRocks FE:9030"
        "StarRocks BE:8040"
        "Zeppelin:8082"
    )
    
    for service in "${SERVICES[@]}"; do
        name=$(echo $service | cut -d: -f1)
        port=$(echo $service | cut -d: -f2)
        
        if nc -z localhost $port; then
            log_info "✅ $name 服务正常 (端口 $port)"
        else
            log_warn "⚠️  $name 服务异常 (端口 $port)"
        fi
    done
    
    # 检查数据
    log_info "检查 MySQL 数据..."
    USER_COUNT=$(docker exec mysql mysql -uroot -proot123 -e "USE ods; SELECT COUNT(*) FROM user;" -s -N 2>/dev/null || echo "0")
    log_info "MySQL 用户表记录数: $USER_COUNT"
    
    log_info "检查 StarRocks 数据..."
    TABLE_COUNT=$(docker exec starrocks mysql -h127.0.0.1 -P9030 -uroot -e "USE analytics; SHOW TABLES;" -s -N 2>/dev/null | wc -l || echo "0")
    log_info "StarRocks 表数量: $TABLE_COUNT"
}

# 显示访问信息
show_access_info() {
    log_step "部署完成！访问信息如下："
    
    echo ""
    echo "🌐 Web 界面访问地址:"
    echo "   Flink Web UI:     http://localhost:8081"
    echo "   StarRocks FE:     http://localhost:8030"
    echo "   StarRocks BE:     http://localhost:8040"
    echo "   Zeppelin:         http://localhost:8082"
    echo "   Adminer (MySQL):  http://localhost:8080"
    echo ""
    echo "🔗 API 访问地址:"
    echo "   SQL Gateway:      http://localhost:8083"
    echo "   MySQL:            localhost:3306"
    echo "   Kafka:            localhost:9092"
    echo "   StarRocks:        localhost:9030"
    echo ""
    echo "📚 快速开始:"
    echo "   1. 访问 Flink Web UI 查看作业状态"
    echo "   2. 使用 Zeppelin 执行 SQL 查询"
    echo "   3. 查看 StarRocks 实时数据"
    echo "   4. 参考 scripts/create_etl_jobs.sql 启动数据流转"
    echo ""
    echo "📖 文档参考:"
    echo "   - 架构分析: REALTIME_DATAWAREHOUSE_ARCHITECTURE_ANALYSIS.md"
    echo "   - MySQL 建表: scripts/create_mysql_tables.sql"
    echo "   - StarRocks 建表: scripts/create_starrocks_tables.sql"
    echo "   - Flink 表定义: scripts/create_flink_tables.sql"
    echo "   - ETL 作业: scripts/create_etl_jobs.sql"
    echo ""
}

# 清理函数
cleanup() {
    log_step "清理部署环境..."
    docker-compose down -v
    log_info "清理完成"
}

# 主函数
main() {
    echo "======================================================================"
    echo "🚀 实时数仓自动化部署脚本 v1.0"
    echo "======================================================================"
    echo ""
    
    case "${1:-deploy}" in
        "deploy")
            check_dependencies
            start_infrastructure
            init_mysql_data
            init_starrocks_data
            create_flink_tables
            start_etl_jobs
            verify_deployment
            show_access_info
            ;;
        "clean")
            cleanup
            ;;
        "verify")
            verify_deployment
            ;;
        "help"|"-h"|"--help")
            echo "用法: $0 [command]"
            echo ""
            echo "命令:"
            echo "  deploy    部署实时数仓 (默认)"
            echo "  clean     清理部署环境"
            echo "  verify    验证部署状态"
            echo "  help      显示帮助信息"
            echo ""
            ;;
        *)
            log_error "未知命令: $1"
            echo "使用 '$0 help' 查看帮助信息"
            exit 1
            ;;
    esac
}

# 捕获中断信号
trap 'log_error "部署被中断"; exit 1' INT TERM

# 执行主函数
main "$@" 
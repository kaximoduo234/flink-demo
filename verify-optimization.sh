#!/bin/bash

# Docker优化验证脚本
# 验证所有优化后的功能是否正常工作

set -e

echo "🚀 Docker优化验证开始..."
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查函数
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 已安装${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 未安装${NC}"
        return 1
    fi
}

check_port() {
    if nc -z localhost $1 2>/dev/null; then
        echo -e "${GREEN}✅ 端口 $1 可访问${NC}"
        return 0
    else
        echo -e "${RED}❌ 端口 $1 不可访问${NC}"
        return 1
    fi
}

# 1. 环境检查
echo -e "\n${BLUE}📋 1. 环境检查${NC}"
echo "--------------------------------"

check_command docker
check_command docker-compose
check_command curl

# 检查Docker版本
DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+')
echo "Docker版本: $DOCKER_VERSION"

# 检查系统资源
echo "系统内存: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "磁盘空间: $(df -h . | tail -1 | awk '{print $4}') 可用"

# 2. 镜像检查
echo -e "\n${BLUE}📦 2. Docker镜像检查${NC}"
echo "--------------------------------"

if docker images | grep -q "custom-flink.*optimized"; then
    echo -e "${GREEN}✅ 优化镜像存在${NC}"
    docker images | grep "custom-flink.*optimized"
else
    echo -e "${YELLOW}⚠️ 优化镜像不存在，开始构建...${NC}"
    docker-compose build --no-cache
fi

# 3. 服务状态检查
echo -e "\n${BLUE}🔧 3. 服务状态检查${NC}"
echo "--------------------------------"

# 检查容器状态
echo "检查容器状态:"
docker-compose ps

# 检查健康状态
echo -e "\n检查服务健康状态:"
HEALTHY_COUNT=$(docker-compose ps --filter "status=healthy" | wc -l)
echo "健康服务数量: $((HEALTHY_COUNT-1))"  # 减去标题行

# 4. 端口连通性测试
echo -e "\n${BLUE}🌐 4. 端口连通性测试${NC}"
echo "--------------------------------"

# 主要服务端口
PORTS=(8081 8083 9092 3306 6379)
PORT_NAMES=("Flink WebUI" "SQL Gateway" "Kafka" "MySQL" "Redis")

for i in "${!PORTS[@]}"; do
    echo -n "检查 ${PORT_NAMES[$i]} (${PORTS[$i]}): "
    if check_port ${PORTS[$i]}; then
        :
    else
        echo -e "${YELLOW}⚠️ 服务可能未启动${NC}"
    fi
done

# 5. API功能测试
echo -e "\n${BLUE}📡 5. API功能测试${NC}"
echo "--------------------------------"

# Flink JobManager API
echo -n "Flink JobManager API: "
if curl -s http://localhost:8081/overview > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 正常${NC}"
else
    echo -e "${RED}❌ 异常${NC}"
fi

# SQL Gateway API  
echo -n "SQL Gateway API: "
if curl -s http://localhost:8083/v1/info > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 正常${NC}"
else
    echo -e "${RED}❌ 异常${NC}"
fi

# 6. 性能检查
echo -e "\n${BLUE}⚡ 6. 性能检查${NC}"
echo "--------------------------------"

# 检查容器资源使用
echo "容器资源使用情况:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -5

# 7. 日志检查
echo -e "\n${BLUE}📋 7. 日志检查${NC}"
echo "--------------------------------"

echo "JobManager 最新日志:"
docker-compose logs --tail=3 jobmanager 2>/dev/null || echo "日志获取失败"

echo -e "\nTaskManager 最新日志:"
docker-compose logs --tail=3 taskmanager 2>/dev/null || echo "日志获取失败"

# 8. 配置验证
echo -e "\n${BLUE}⚙️ 8. 配置验证${NC}"
echo "--------------------------------"

# 检查关键配置文件
if [ -f "flink/Dockerfile" ]; then
    echo -e "${GREEN}✅ 优化 Dockerfile 存在${NC}"
    if grep -q "AS base" flink/Dockerfile; then
        echo -e "${GREEN}✅ 多阶段构建已启用${NC}"
    fi
fi

if [ -f ".dockerignore" ]; then
    echo -e "${GREEN}✅ .dockerignore 已配置${NC}"
fi

# 9. 清理验证
echo -e "\n${BLUE}🧹 9. 清理验证${NC}"
echo "--------------------------------"

# 检查是否存在已清理的文件
CLEANED_FILES=(
    "docker-compose.yml.backup"
    "flink-1.20.1-bin-scala_2.12.tgz"
    "test-flink-connection.sh"
    "final-verification.sh"
)

for file in "${CLEANED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${GREEN}✅ $file 已清理${NC}"
    else
        echo -e "${YELLOW}⚠️ $file 仍存在${NC}"
    fi
done

# 10. 总结报告
echo -e "\n${BLUE}📊 10. 验证总结${NC}"
echo "========================================"

# 获取项目统计信息
echo "项目统计信息:"
echo "- 总文件数: $(find . -type f | wc -l)"
echo "- 总目录数: $(find . -type d | wc -l)"
echo "- 项目大小: $(du -sh . | cut -f1)"
echo "- Markdown文档: $(find . -name "*.md" -type f | wc -l) 个"

# 验证完成
echo -e "\n${GREEN}🎉 Docker优化验证完成！${NC}"
echo -e "\n${BLUE}📚 查看完整文档: DOCKER_OPTIMIZATION_UPGRADE_GUIDE.md${NC}"

# 提供快速访问链接
echo -e "\n${YELLOW}🔗 快速访问链接:${NC}"
echo "- Flink Web UI: http://localhost:8081"
echo "- SQL Gateway: http://localhost:8083/v1/info"
echo "- StreamPark: http://localhost:10000"

echo -e "\n${BLUE}💡 下一步操作建议:${NC}"
echo "1. 访问 Flink Web UI 检查集群状态"
echo "2. 运行 SQL 测试验证连接器功能"
echo "3. 查看性能监控数据"
echo "4. 配置生产环境监控" 
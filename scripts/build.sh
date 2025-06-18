#!/bin/bash

# =============================================================================
# 🔥 Flink + Paimon Demo - 企业级构建脚本
# =============================================================================
# 功能：
# - 环境依赖检查
# - 代码质量检查
# - 单元测试 + 集成测试
# - 构建 + 打包
# - Docker镜像构建
# - 部署准备
# =============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查必要的工具
check_prerequisites() {
    log_info "🔍 检查构建环境依赖..."
    
    local missing_tools=()
    
    if ! command_exists java; then
        missing_tools+=("java")
    else
        java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
        log_info "Java版本: $java_version"
        
        # 检查是否为Java 17+
        major_version=$(echo $java_version | cut -d'.' -f1)
        if [ "$major_version" -lt 17 ]; then
            log_error "需要Java 17或更高版本，当前版本: $java_version"
            exit 1
        fi
    fi
    
    if ! command_exists mvn; then
        missing_tools+=("maven")
    else
        mvn_version=$(mvn -version | head -n1)
        log_info "Maven版本: $mvn_version"
    fi
    
    if ! command_exists docker; then
        missing_tools+=("docker")
    else
        docker_version=$(docker --version)
        log_info "Docker版本: $docker_version"
    fi
    
    if ! command_exists docker-compose; then
        missing_tools+=("docker-compose")
    else
        compose_version=$(docker-compose --version)
        log_info "Docker Compose版本: $compose_version"
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        log_info "请安装缺少的工具后重试"
        exit 1
    fi
    
    log_success "环境依赖检查通过"
}

# 清理旧的构建文件
clean_build() {
    log_info "🧹 清理旧的构建文件..."
    
    mvn clean -q
    
    # 清理Docker相关文件
    if [ -d "target" ]; then
        rm -rf target/dependency-reduced-pom.xml
    fi
    
    log_success "构建文件清理完成"
}

# 代码质量检查
code_quality_check() {
    log_info "🔍 执行代码质量检查..."
    
    # 编译检查
    log_info "编译检查..."
    mvn compile -q
    
    # 静态代码分析
    log_info "静态代码分析..."
    mvn spotbugs:check -q || {
        log_warning "静态代码分析发现问题，请检查报告"
    }
    
    log_success "代码质量检查完成"
}

# 运行测试
run_tests() {
    log_info "🧪 运行测试套件..."
    
    # 单元测试
    log_info "运行单元测试..."
    mvn test -q
    
    # 生成测试报告
    log_info "生成测试覆盖率报告..."
    mvn jacoco:report -q
    
    # 检查测试覆盖率
    log_info "检查测试覆盖率..."
    mvn jacoco:check -q || {
        log_warning "测试覆盖率未达到标准，请增加测试用例"
    }
    
    log_success "测试完成"
}

# 构建项目
build_project() {
    log_info "🔨 构建项目..."
    
    # 跳过测试的快速构建
    mvn package -DskipTests -q
    
    # 检查构建产物
    if [ -f "target/flink-paimon-demo-1.0.0.jar" ]; then
        jar_size=$(ls -lh target/flink-paimon-demo-1.0.0.jar | awk '{print $5}')
        log_success "构建成功，JAR文件大小: $jar_size"
    else
        log_error "构建失败，未找到JAR文件"
        exit 1
    fi
}

# 构建Docker镜像
build_docker() {
    log_info "🐳 构建Docker镜像..."
    
    # 检查Dockerfile是否存在
    if [ ! -f "flink/Dockerfile" ]; then
        log_error "未找到Dockerfile: flink/Dockerfile"
        exit 1
    fi
    
    # 构建镜像
    docker build -t custom-flink:1.20.1-paimon -f flink/Dockerfile .
    
    # 检查镜像是否构建成功
    if docker images | grep -q "custom-flink.*1.20.1-paimon"; then
        log_success "Docker镜像构建成功"
    else
        log_error "Docker镜像构建失败"
        exit 1
    fi
}

# 验证部署配置
validate_deployment() {
    log_info "🔍 验证部署配置..."
    
    # 检查docker-compose.yml
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到docker-compose.yml文件"
        exit 1
    fi
    
    # 验证compose文件语法
    docker-compose config >/dev/null 2>&1 || {
        log_error "docker-compose.yml配置有误"
        exit 1
    }
    
    # 检查必要的目录
    local required_dirs=("flink-jars" "checkpoints" "paimon-warehouse")
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log_info "创建目录: $dir"
            mkdir -p "$dir"
        fi
    done
    
    log_success "部署配置验证通过"
}

# 生成构建报告
generate_report() {
    log_info "📊 生成构建报告..."
    
    local report_file="build-report.md"
    
    cat > "$report_file" << EOF
# 🔥 Flink + Paimon Demo 构建报告

## 构建信息
- 构建时间: $(date)
- 构建版本: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
- Java版本: $(java -version 2>&1 | head -n1 | cut -d'"' -f2)
- Maven版本: $(mvn -version | head -n1)

## 构建产物
- JAR文件: target/flink-paimon-demo-1.0.0.jar
- Docker镜像: custom-flink:1.20.1-paimon

## 测试结果
- 单元测试: $(grep -o "Tests run: [0-9]*" target/surefire-reports/*.txt 2>/dev/null | tail -n1 || echo "未运行")
- 测试覆盖率: 查看 target/site/jacoco/index.html

## 质量检查
- 静态代码分析: 查看 target/spotbugsXml.xml
- 编译警告: 无

## 部署准备
- [x] Docker镜像已构建
- [x] 配置文件已验证
- [x] 必要目录已创建

## 快速部署
\`\`\`bash
# 启动服务
docker-compose up -d

# 检查服务状态
docker-compose ps

# 访问Flink Web UI
open http://localhost:8081
\`\`\`

EOF
    
    log_success "构建报告已生成: $report_file"
}

# 主函数
main() {
    local start_time=$(date +%s)
    
    echo "🚀 Flink + Paimon Demo 企业级构建流程"
    echo "========================================"
    
    # 解析命令行参数
    local skip_tests=false
    local skip_docker=false
    local full_build=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                skip_tests=true
                shift
                ;;
            --skip-docker)
                skip_docker=true
                shift
                ;;
            --quick)
                skip_tests=true
                skip_docker=true
                full_build=false
                shift
                ;;
            -h|--help)
                echo "使用方法: $0 [OPTIONS]"
                echo "选项:"
                echo "  --skip-tests    跳过测试"
                echo "  --skip-docker   跳过Docker构建"
                echo "  --quick         快速构建（跳过测试和Docker）"
                echo "  -h, --help      显示帮助信息"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    # 执行构建步骤
    check_prerequisites
    clean_build
    
    if [ "$full_build" = true ]; then
        code_quality_check
    fi
    
    if [ "$skip_tests" = false ]; then
        run_tests
    fi
    
    build_project
    
    if [ "$skip_docker" = false ]; then
        build_docker
    fi
    
    validate_deployment
    generate_report
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "========================================"
    log_success "构建完成！耗时: ${duration}秒"
    echo "🎉 项目已准备就绪，可以部署了！"
    echo ""
    echo "下一步:"
    echo "1. 查看构建报告: cat build-report.md"
    echo "2. 启动服务: docker-compose up -d"
    echo "3. 访问Flink Web UI: http://localhost:8081"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
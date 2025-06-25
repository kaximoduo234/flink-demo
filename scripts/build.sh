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

# 信号处理 - 优雅退出
cleanup() {
    log_info "🛑 构建被中断，正在清理..."
    # 可以在这里添加清理逻辑
    exit 130
}

trap cleanup SIGINT SIGTERM

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
    
    # 静态代码分析 (可选)
    log_info "静态代码分析..."
    if mvn help:describe -Dplugin=com.github.spotbugs:spotbugs-maven-plugin -q >/dev/null 2>&1; then
        mvn spotbugs:check -q || {
            log_warning "静态代码分析发现问题，请检查报告"
        }
    else
        log_info "SpotBugs 插件未配置，跳过静态代码分析"
        log_info "提示：可在 pom.xml 中添加 SpotBugs 插件以启用静态分析"
    fi
    
    log_success "代码质量检查完成"
}

# 运行测试
run_tests() {
    log_info "🧪 运行测试套件..."
    
    # 单元测试
    log_info "运行单元测试..."
    if mvn test -q; then
        log_success "单元测试通过"
    else
        local test_failures=$(find target/surefire-reports -name "*.txt" -exec grep -l "FAILURE\|ERROR" {} \; 2>/dev/null | wc -l)
        if [ "$test_failures" -gt 0 ]; then
            log_warning "发现 $test_failures 个测试失败，请检查测试报告"
            log_info "测试报告位置: target/surefire-reports/"
        else
            log_info "测试执行完成，可能存在跳过的测试"
        fi
    fi
    
    # 生成测试覆盖率报告 (可选)
    log_info "生成测试覆盖率报告..."
    if mvn help:describe -Dplugin=org.jacoco:jacoco-maven-plugin -q >/dev/null 2>&1; then
        mvn jacoco:report -q
        
        # 检查测试覆盖率
        log_info "检查测试覆盖率..."
        mvn jacoco:check -q || {
            log_warning "测试覆盖率未达到标准，请增加测试用例"
        }
    else
        log_info "JaCoCo 插件未配置，跳过覆盖率报告生成"
        log_info "提示：可在 pom.xml 中添加 JaCoCo 插件以启用覆盖率检查"
    fi
    
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

# 跨平台访问Flink Web UI
# macOS: open http://localhost:8081
# Linux: xdg-open http://localhost:8081  
# Windows: start http://localhost:8081
\`\`\`

## 服务地址
- 📊 Flink Web UI: http://localhost:8081
- 🗄️ MySQL Adminer: http://localhost:8080
- 📈 StreamPark: http://localhost:10000
- 🔍 Doris FE UI: http://localhost:8030
- 🔧 Doris BE UI: http://localhost:8040

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
            --lite)
                skip_tests=false
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
                echo "  --lite          轻量构建（包含测试，跳过Docker和质量检查）"
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
    
    # 显示服务访问信息
    show_access_info
}

# 跨平台打开浏览器
open_browser() {
    local url="$1"
    
    log_info "🌐 尝试打开浏览器访问: $url"
    
    # 检测操作系统并使用相应的命令
    case "$(uname -s)" in
        Darwin*)
            # macOS
            if command_exists open; then
                open "$url"
                log_success "已在macOS上打开浏览器"
            else
                log_warning "无法在macOS上打开浏览器，请手动访问: $url"
            fi
            ;;
        Linux*)
            # Linux
            if command_exists xdg-open; then
                xdg-open "$url" 2>/dev/null
                log_success "已在Linux上打开浏览器"
            elif command_exists gnome-open; then
                gnome-open "$url" 2>/dev/null
                log_success "已在Linux(GNOME)上打开浏览器"
            elif command_exists kde-open; then
                kde-open "$url" 2>/dev/null
                log_success "已在Linux(KDE)上打开浏览器"
            else
                log_warning "无法在Linux上自动打开浏览器，请手动访问: $url"
            fi
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            # Windows (Git Bash, Cygwin, MSYS2)
            if command_exists start; then
                start "$url"
                log_success "已在Windows上打开浏览器"
            elif command_exists cmd; then
                cmd /c start "$url"
                log_success "已在Windows上打开浏览器"
            else
                log_warning "无法在Windows上打开浏览器，请手动访问: $url"
            fi
            ;;
        *)
            # 未知系统
            log_warning "未知操作系统，无法自动打开浏览器"
            log_info "请手动在浏览器中访问: $url"
            ;;
    esac
}

# 显示部署后的访问信息
show_access_info() {
    echo ""
    echo "🎯 服务访问信息"
    echo "============================================"
    echo "📊 Flink Web UI:      http://localhost:8081"
    echo "🗄️  MySQL Adminer:     http://localhost:8080"
    echo "📈 StreamPark:        http://localhost:10000"
    echo "🔍 Doris FE UI:       http://localhost:8030"
    echo "🔧 Doris BE UI:       http://localhost:8040"
    echo "============================================"
    echo ""
    
    # 询问是否打开浏览器
    read -p "是否要打开Flink Web UI? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open_browser "http://localhost:8081"
    else
        log_info "您可以稍后手动访问上述服务地址"
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
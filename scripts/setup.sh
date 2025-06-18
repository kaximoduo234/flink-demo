#!/bin/bash

# =============================================================================
# 🔥 Flink + Paimon Demo - 环境设置脚本
# =============================================================================
# 自动安装和配置开发环境所需的所有依赖
# 支持 Ubuntu/Debian, CentOS/RHEL, macOS
# =============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
        elif [ -f /etc/redhat-release ]; then
            OS="rhel"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
    log_info "检测到操作系统: $OS"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 安装 Java 17
install_java() {
    log_info "🔍 检查Java安装..."
    
    if command_exists java; then
        java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
                 major_version=$(echo $java_version | cut -d'.' -f1)
        
        if [ "$major_version" -ge 17 ]; then
            log_success "Java $java_version 已安装（开发环境）"
            return 0
        elif [ "$major_version" -ge 11 ]; then
            log_success "Java $java_version 已安装（满足运行要求，建议升级到17用于开发）"
            return 0
        else
            log_warning "Java版本过低: $java_version，需要升级到11+（推荐17）"
        fi
    fi
    
    log_info "📦 安装Java 17..."
    
    case $OS in
        "debian")
            sudo apt update
            sudo apt install -y openjdk-17-jdk
            ;;
        "rhel")
            sudo yum update -y
            sudo yum install -y java-17-openjdk-devel
            ;;
        "macos")
            if command_exists brew; then
                brew install openjdk@17
                echo 'export PATH="/usr/local/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
            else
                log_error "请先安装Homebrew: https://brew.sh"
                exit 1
            fi
            ;;
    esac
    
    log_success "Java 17 安装完成"
}

# 安装 Maven
install_maven() {
    log_info "🔍 检查Maven安装..."
    
    if command_exists mvn; then
        mvn_version=$(mvn -version | head -n1)
        log_success "Maven已安装: $mvn_version"
        return 0
    fi
    
    log_info "📦 安装Maven..."
    
    case $OS in
        "debian")
            sudo apt install -y maven
            ;;
        "rhel")
            sudo yum install -y maven
            ;;
        "macos")
            brew install maven
            ;;
    esac
    
    log_success "Maven 安装完成"
}

# 安装 Docker
install_docker() {
    log_info "🔍 检查Docker安装..."
    
    if command_exists docker; then
        docker_version=$(docker --version)
        log_success "Docker已安装: $docker_version"
    else
        log_info "📦 安装Docker..."
        
        case $OS in
            "debian")
                sudo apt update
                sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt update
                sudo apt install -y docker-ce docker-ce-cli containerd.io
                ;;
            "rhel")
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io
                sudo systemctl start docker
                sudo systemctl enable docker
                ;;
            "macos")
                log_info "请手动安装Docker Desktop for Mac: https://docs.docker.com/docker-for-mac/install/"
                ;;
        esac
        
        # 添加用户到docker组
        if [ "$OS" != "macos" ]; then
            sudo usermod -aG docker $USER
            log_warning "请重新登录以使Docker组权限生效，或运行: newgrp docker"
        fi
        
        log_success "Docker 安装完成"
    fi
}

# 安装 Docker Compose
install_docker_compose() {
    log_info "🔍 检查Docker Compose安装..."
    
    if command_exists docker-compose; then
        compose_version=$(docker-compose --version)
        log_success "Docker Compose已安装: $compose_version"
        return 0
    fi
    
    log_info "📦 安装Docker Compose..."
    
    case $OS in
        "debian"|"rhel")
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "macos")
            # Docker Desktop for Mac 已经包含了 Docker Compose
            log_info "Docker Compose 应该已随Docker Desktop安装"
            ;;
    esac
    
    log_success "Docker Compose 安装完成"
}

# 安装 Git
install_git() {
    log_info "🔍 检查Git安装..."
    
    if command_exists git; then
        git_version=$(git --version)
        log_success "Git已安装: $git_version"
        return 0
    fi
    
    log_info "📦 安装Git..."
    
    case $OS in
        "debian")
            sudo apt install -y git
            ;;
        "rhel")
            sudo yum install -y git
            ;;
        "macos")
            # macOS 通常预装了Git，但可以通过brew升级
            if command_exists brew; then
                brew install git
            fi
            ;;
    esac
    
    log_success "Git 安装完成"
}

# 配置项目环境
setup_project_env() {
    log_info "🔧 配置项目环境..."
    
    # 创建必要的目录
    local dirs=("flink-jars" "checkpoints" "paimon-warehouse" "mysql-data" "kafka-data")
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "创建目录: $dir"
        fi
    done
    
    # 创建环境变量文件
    if [ ! -f ".env" ] && [ -f "env.template" ]; then
        cp env.template .env
        log_info "创建环境变量文件: .env"
        log_warning "请根据需要修改 .env 文件中的配置"
    fi
    
    # 设置文件权限
    if [ -f "scripts/build.sh" ]; then
        chmod +x scripts/build.sh
    fi
    
    log_success "项目环境配置完成"
}

# 验证安装
verify_installation() {
    log_info "🔍 验证安装..."
    
    local missing=()
    
    if ! command_exists java; then
        missing+=("java")
    else
        java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
        major_version=$(echo $java_version | cut -d'.' -f1)
        if [ "$major_version" -lt 17 ]; then
            missing+=("java-17+")
        fi
    fi
    
    if ! command_exists mvn; then missing+=("maven"); fi
    if ! command_exists docker; then missing+=("docker"); fi
    if ! command_exists docker-compose; then missing+=("docker-compose"); fi
    if ! command_exists git; then missing+=("git"); fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "以下工具安装失败或未满足要求: ${missing[*]}"
        return 1
    fi
    
    log_success "所有依赖安装验证通过"
    return 0
}

# 主函数
main() {
    echo "🚀 Flink + Paimon Demo 环境设置"
    echo "================================="
    
    detect_os
    
    # 安装依赖
    install_java
    install_maven
    install_docker
    install_docker_compose
    install_git
    
    # 配置项目环境
    setup_project_env
    
    # 验证安装
    if verify_installation; then
        echo "================================="
        log_success "环境设置完成！"
        echo ""
        echo "下一步:"
        echo "1. 运行构建: ./scripts/build.sh"
        echo "2. 启动服务: docker-compose up -d"
        echo "3. 访问Flink Web UI: http://localhost:8081"
        echo ""
        echo "📖 更多信息请查看: README.md"
    else
        log_error "环境设置失败，请检查错误信息并重试"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
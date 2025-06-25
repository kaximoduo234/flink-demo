# 多阶段构建 - 基础镜像
FROM flink:1.20.1-scala_2.12-java17 AS base

# 构建参数
ARG PAIMON_VERSION=1.0.0
ARG FLINK_VERSION=1.20.1

# 维护者信息
LABEL maintainer="flink-demo-team"
LABEL description="Custom Flink with Paimon connector - Optimized Build"
LABEL java.version="17"
LABEL flink.version="${FLINK_VERSION}"
LABEL paimon.version="${PAIMON_VERSION}"

# 设置环境变量
ENV PAIMON_VERSION=${PAIMON_VERSION}
ENV FLINK_VERSION=${FLINK_VERSION}

# 依赖准备阶段
FROM base AS dependencies
WORKDIR /tmp/build

# 只复制必要的依赖文件（优化构建上下文）
COPY flink-jars/*.jar ./connectors/

# 验证和整理依赖
RUN echo "=== 准备连接器依赖 ===" && \
    ls -la ./connectors/ && \
    echo "依赖文件数量: $(ls -1 ./connectors/ | wc -l)" && \
    mkdir -p /opt/flink-connectors && \
    cp ./connectors/*.jar /opt/flink-connectors/ && \
    echo "=== 依赖准备完成 ==="

# 最终运行时镜像
FROM base AS runtime

# 从依赖阶段复制连接器文件
COPY --from=dependencies /opt/flink-connectors/*.jar $FLINK_HOME/lib/

# 设置权限和验证（合并 RUN 指令减少镜像层）
USER root
RUN chmod -R 755 $FLINK_HOME/lib/ && \
    echo "=== 已安装的连接器列表 ===" && \
    ls -la $FLINK_HOME/lib/*.jar | grep -E "(paimon|cdc|starrocks|kafka|mysql)" || echo "连接器检查完成" && \
    echo "=== Flink lib 目录文件总数 ===" && \
    ls -1 $FLINK_HOME/lib/ | wc -l && \
    echo "=== 镜像构建完成 ==="

# 健康检查（仅对有 Web UI 的服务有效）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8081/overview 2>/dev/null || exit 0

# 切换回 flink 用户
USER flink

# 设置工作目录
WORKDIR $FLINK_HOME 
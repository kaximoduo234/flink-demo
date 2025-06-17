FROM flink:1.20.1-scala_2.12-java17

# 维护者信息
LABEL maintainer="flink-demo-team"
LABEL description="Custom Flink with Paimon connector - Java 17 Runtime"
LABEL java.version="17"
LABEL flink.version="1.20.1"

# 复制额外的 JAR 文件到 Flink lib 目录
COPY flink-jars/*.jar $FLINK_HOME/lib/

# 验证文件是否复制成功
RUN echo "=== 已安装的额外 JAR 文件 ===" && \
    ls -la $FLINK_HOME/lib/paimon-* || echo "未找到 Paimon JAR 文件" && \
    echo "=== Flink lib 目录总文件数量 ===" && \
    ls -1 $FLINK_HOME/lib/ | wc -l

# 设置环境变量（可选）
ENV PAIMON_VERSION="1.0.0"

# 确保脚本具有执行权限
USER root
RUN chmod -R 755 $FLINK_HOME/lib/

# 切换回 flink 用户
USER flink 
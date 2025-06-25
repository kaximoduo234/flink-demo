#!/bin/bash

# 设置 Zeppelin 环境变量

# Java 环境
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Zeppelin 配置
export ZEPPELIN_PORT=8080
export ZEPPELIN_MEM="-Xmx2g -XX:MaxMetaspaceSize=512m"
export ZEPPELIN_NOTEBOOK_DIR=/opt/zeppelin/notebook

# 禁用 Hadoop 集成（如果不需要）
export HADOOP_CONF_DIR=""
export USE_HADOOP=false

# Flink 配置
export FLINK_HOME=/opt/flink
export FLINK_REST_URL=http://jobmanager:8081

# SQL Gateway 配置
export FLINK_SQL_GATEWAY_URL=http://sql-gateway:8083

# Python 环境 (可选)
export PYSPARK_PYTHON=python3

# 其他配置
export ZEPPELIN_SPARK_USEHIVECONTEXT=false

# Scala 兼容性修复 - 强制使用 Scala 2.12.11
export SCALA_HOME=/opt/flink/lib
export SCALA_BINARY_VERSION=2.12
export ZEPPELIN_JAVA_OPTS="-Dfile.encoding=UTF-8 -Xms1g -Xmx2g -XX:MaxMetaspaceSize=512m -Dscala.usejavacp=true"

# Flink 解释器特定配置 - 确保使用正确的 Scala 版本
export FLINK_INTERPRETER_OPTS="-Dscala.usejavacp=true -Dscala.version=2.12.11"

# 设置解释器
export ZEPPELIN_INTERPRETER_OUTPUT_LIMIT=102400

# 日志配置
export ZEPPELIN_LOG_DIR=/opt/zeppelin/logs
export ZEPPELIN_PID_DIR=/opt/zeppelin/run

# 创建必要的目录
mkdir -p $ZEPPELIN_LOG_DIR
mkdir -p $ZEPPELIN_PID_DIR 
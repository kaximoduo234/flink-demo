#!/bin/bash

echo "🚀 构建Doris自定义镜像..."

# 构建FE镜像
echo "📦 构建Doris FE镜像..."
docker build -f fe-dockerfile -t doris-fe-custom:2.1.9 .

# 构建BE镜像  
echo "📦 构建Doris BE镜像..."
docker build -f be-dockerfile -t doris-be-custom:2.1.9 .

echo "✅ 镜像构建完成！"
echo ""
echo "可用镜像："
docker images | grep doris 
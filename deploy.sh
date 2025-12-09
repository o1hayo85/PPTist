#!/bin/bash

# PPTist 部署脚本
# 实现完整的"拉取代码->打包镜像->启动容器"部署流程

# 配置参数
GIT_REPO="https://github.com/o1hayo85/PPTist.git"  # Git仓库地址
GIT_BRANCH="master"                    # 分支名称
PROJECT_DIR="/opt/pptist"              # 项目目录
DOCKER_IMAGE="pptist"                  # 镜像名称
DOCKER_CONTAINER="pptist"              # 容器名称
DOCKER_PORT=8001                       # 宿主机端口
LOG_DIR="/var/log/pptist"              # 日志目录
MEMORY_LIMIT="128m"                    # 内存限制

# 打印脚本信息
echo "========================================"
echo "PPTist 部署脚本"
echo "========================================"
echo "Git仓库: $GIT_REPO"
echo "分支名称: $GIT_BRANCH"
echo "项目目录: $PROJECT_DIR"
echo "镜像名称: $DOCKER_IMAGE"
echo "容器名称: $DOCKER_CONTAINER"
echo "宿主机端口: $DOCKER_PORT"
echo "日志目录: $LOG_DIR"
echo "内存限制: $MEMORY_LIMIT"
echo "========================================"

# 创建日志目录
echo "1. 创建日志目录..."
sudo mkdir -p $LOG_DIR
sudo chmod 755 $LOG_DIR
if [ $? -eq 0 ]; then
    echo "   ✅ 日志目录创建成功: $LOG_DIR"
else
    echo "   ❌ 日志目录创建失败"
    exit 1
fi

# 拉取最新代码
echo "2. 拉取最新代码..."
if [ -d "$PROJECT_DIR" ]; then
    echo "   ⏳ 更新现有代码库..."
    cd $PROJECT_DIR
    git pull origin $GIT_BRANCH
    if [ $? -eq 0 ]; then
        echo "   ✅ 代码更新成功"
    else
        echo "   ❌ 代码更新失败"
        exit 1
    fi
else
    echo "   ⏳ 克隆新代码库..."
    git clone -b $GIT_BRANCH $GIT_REPO $PROJECT_DIR
    if [ $? -eq 0 ]; then
        echo "   ✅ 代码克隆成功: $PROJECT_DIR"
    else
        echo "   ❌ 代码克隆失败"
        exit 1
    fi
fi

# 构建Docker镜像
echo "3. 构建Docker镜像..."
cd $PROJECT_DIR
docker build -t $DOCKER_IMAGE:latest .
if [ $? -eq 0 ]; then
    echo "   ✅ 镜像构建成功: $DOCKER_IMAGE:latest"
else
    echo "   ❌ 镜像构建失败"
    exit 1
fi

# 停止旧容器
echo "3. 停止旧容器..."
docker stop $DOCKER_CONTAINER 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ 容器已停止: $DOCKER_CONTAINER"
else
    echo "   ⚠️  容器未运行或停止失败: $DOCKER_CONTAINER"
fi

# 删除旧容器
echo "4. 删除旧容器..."
docker rm $DOCKER_CONTAINER 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ 容器已删除: $DOCKER_CONTAINER"
else
    echo "   ⚠️  容器不存在或删除失败: $DOCKER_CONTAINER"
fi

# 启动新容器
echo "5. 启动新容器..."
docker run -d \
    --name $DOCKER_CONTAINER \
    --restart unless-stopped \
    -p $DOCKER_PORT:80 \
    -m $MEMORY_LIMIT \
    -v $LOG_DIR:/var/log/nginx \
    $DOCKER_IMAGE:latest

if [ $? -eq 0 ]; then
    echo "   ✅ 容器启动成功: $DOCKER_CONTAINER"
    echo "   📦 容器ID: $(docker inspect -f '{{.Id}}' $DOCKER_CONTAINER | cut -c 1-12)"
    echo "   🌐 访问地址: http://$(hostname -I | awk '{print $1}'):$DOCKER_PORT"
else
    echo "   ❌ 容器启动失败"
    exit 1
fi

# 测试Nginx配置
echo "6. 测试Nginx配置..."
docker exec $DOCKER_CONTAINER nginx -t
if [ $? -eq 0 ]; then
    echo "   ✅ Nginx配置测试通过"
    # 重新加载Nginx配置
    docker exec $DOCKER_CONTAINER nginx -s reload
    echo "   ✅ Nginx配置已重新加载"
else
    echo "   ⚠️  Nginx配置测试失败，请检查配置文件"
fi

# 清理未使用的镜像
echo "7. 清理未使用的镜像..."
docker image prune -f
if [ $? -eq 0 ]; then
    echo "   ✅ 未使用镜像清理完成"
else
    echo "   ⚠️  镜像清理失败或无镜像可清理"
fi

# 显示容器状态
echo "8. 容器状态..."
docker ps -a --filter "name=$DOCKER_CONTAINER"

# 完成信息
echo "========================================"
echo "🎉 PPTist 部署完成！"
echo "部署流程: 代码拉取 -> 镜像构建 -> 容器启动"
echo "访问地址: http://$(hostname -I | awk '{print $1}'):$DOCKER_PORT"
echo "项目目录: $PROJECT_DIR"
echo "查看日志: docker logs -f $DOCKER_CONTAINER"
echo "停止容器: docker stop $DOCKER_CONTAINER"
echo "删除容器: docker rm $DOCKER_CONTAINER"
echo "========================================"
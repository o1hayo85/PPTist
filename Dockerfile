# 第一阶段：构建项目
FROM node:20.11.1-alpine AS build-stage

# 设置工作目录
WORKDIR /app

# 复制package.json和package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm install --registry=https://mirrors.cloud.tencent.com/npm/

# 复制项目文件
COPY . .

# 构建项目
RUN npm run build

# 第二阶段：Nginx部署
FROM nginx:alpine AS production-stage

# 复制构建好的文件到Nginx的html目录
COPY --from=build-stage /app/dist /usr/share/nginx/html

# 复制自定义Nginx配置文件
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露80端口
EXPOSE 80

# 启动Nginx
CMD ["nginx", "-g", "daemon off;"]
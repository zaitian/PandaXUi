FROM node:16-alpine AS builder
WORKDIR /app
COPY . .
# 安装依赖
RUN npm install --registry=https://registry.npmmirror.com

# 打包发布
RUN npm run build

FROM nginx:1.25-alpine
LABEL MAINTAINER="PandaX"

COPY deploy/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder  /app/deploy/dist /usr/share/nginx/html/

#暴露容器8001端口
EXPOSE 7789
---
title: "Docker快速入门（五）docker-compose安装与基础用法"
date: 2017-12-20T13:12:35+08:00
categories: ["docker"]
tags: [ "docker", "Docker快速入门" ]
---

# 简介
docker-compose 可以用来定义和运行复杂应用的Docker工具，比如你的web应用需要用到好几个容器，mysql、redis和你自己的应用容器，它们之间需要相互协作、通信，一般都是同时启动和关闭的。如果手工一个一个启动、link，这样很麻烦，通常如果它们运行在同一台机器上，我们可以用docker-compose来管理，非常方便。

# 安装
如果你用的mac或windows桌面版docker，那么docker-compose已经自带了，如果是linux，可以在官方的github release页面下载最新版: [https://github.com/docker/compose/releases](https://github.com/docker/compose/releases)  
通常选择`docker-compose-Linux-x86_64`，下载下来重命名为`docker-compose`，并增加可执行权限：
```sh 
chmod +x docker-compose
```
然后将其移到`PATH`下，比如：
``` sh
mv docker-compose /usr/local/bin/
```
最后检验一下是否安装成功：
``` sh
docker-compose --version
```

# 编写docker-compose.yml
要使用docker-compose，就必须定义`docker-compose.yml`配置文件，然后在配置文件所在目录执行docker-compose相关命令，配置文件示例：
``` yaml
version: "3" # 配置文件格式版本号
services:
  web:
    image: yourname/web # 镜像名
    container_name: web # 给容器起别名
    ports:
      - 8080:80 # 容器内80端口映射到宿主机8080端口
    volumes: # 挂载目录或文件
      - ./conf.toml:/etc/web/conf.toml
      - ./data:/data/web
    working_dir: /web # 改变当前工作目录
    command: python app.py # 改变默认启动命令
    depends_on: 
      - db # 依赖db这个service
      - redis # 依赖redis这个service
  db:
    image: mysql:5.6
  redis:
    image: redis
```

# docker-compose 命令
执行docker-compose命令首先确保你的当前目录跟`docker-compose.yml`在同一目录下
### 启动
通常都是后台启动，加`-d`参数：
``` sh
docker-compose up -d
```
![docker compose up -d](https://res.cloudinary.com/imroc/image/upload/v1513753125/blog/docker/docker-compose-up.png)

### 查看运行状态
``` sh
docker-compose ps
```
![docker compose ps](https://res.cloudinary.com/imroc/image/upload/v1513752292/blog/docker/docker-compose-ps.png)

### 停止
``` sh
docker-compose down
```
![docker compose down](https://res.cloudinary.com/imroc/image/upload/v1513753125/blog/docker/docker-compose-down.png)

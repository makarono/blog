---
title: "Docker快速入门（三）常用命令与技巧"
date: 2017-12-19T16:27:07+08:00
categories: ["docker"]
tags: [ "docker", "Docker快速入门" ]
---

# 常用命令
### 列出机器上的镜像
``` sh
docker images
```
![docker images](https://res.cloudinary.com/imroc/image/upload/v1513675136/blog/docker/docker-images.png)

### 拉取镜像
``` sh
docker pull openjdk # 等同于 docker pull openjdk:latest

docker pull openjdk:jre-slim # 指定了tag

docker pull hub.imroc.io:5000/imroc/myapp:1.2 # 拉取私有仓库的镜像
```
### 上传镜像
``` sh
docker push imroc/myapp:1atest # 上传到Docker Hub公有仓库

docker push hub.imroc.io:5000/imroc/myqpp:1.2 # 上传到私有仓库
```

### 删除镜像
``` sh
# 删除指定名称的镜像
docker rmi imroc/myapp:latest

# 删除没有tag的镜像（比如每次编译新镜像都会打latest这个tag，导致旧的latest镜像没了tag）
docker rmi `docker images -f "dangling=true" -q`

# 删除所有镜像
docker rmi `docker images -q`
```


### 列出机器上的容器
##### 1. 查看正在运行的
  
``` sh
docker ps
```
![docker ps](https://res.cloudinary.com/imroc/image/upload/v1513687714/blog/docker/docker-ps.png)
  
##### 2. 查看所有的 (包含已经停止并且没有删除的容器)

``` sh
docker ps -a
```
![docker ps -a](https://res.cloudinary.com/imroc/image/upload/v1513688020/blog/docker/docker-ps-a.png)
  
### 启动容器
``` sh
# 前台运行，指定镜像为ubuntu，并指定要运行的是bash命令行
docker run -it ubuntu /bin/bash 

# 后台运行
docker run -d imroc/myapp:1.2 

# 给容器起别名
docker run --name app imroc/myapp:1.2 

# 映射宿主机5000端口到容器的80端口，即访问机器的5000端口相当于访问容器的80端口
docker run -p 5000:80 imroc/myapp:1.2 

# 挂载当前目录的配置文件到容器里
docker run -v $PWD:/config.yaml:/app/config.yaml imroc/myapp:1.2 

# 当容器停止就将其删除
docker run --rm imroc/myapp:1.2
```

### 删除容器
``` sh
# 通过别名删除
docker rm app

# 通过id删除
docker rm 4a19c300e0c0

# 删除全部容器
docker rm $(docker ps -a -q)

# 删除已停止的容器
docker rm $(docker ps -f status=exited -q)
```

### 进入已运行的容器内部 (进入容器内的命令行操作)
``` sh
# 进入别名为app的容器，终端为/bin/sh
docker exec -it app /bin/sh

# 进入id为c62874e3750a的容器，终端为/bin/bash（有些容器可能只有/bin/sh）
docker exec -it c62874e3750a /bin/bash
```

### 容器与宿主机之间文件拷贝
``` sh
# 将当前目录的配置文件拷贝到别名为app的容器里
docker cp ./config.toml app:/app/config.toml

# 将id为c62874e3750a的容器中的配置文件拷贝到当前目录
docker cp c62874e3750a:/app/config.toml ./config.toml
```

### 查看容器或镜像详细信息
``` sh
# name可以为镜像id或名称，也可以为容器id或别名
docker inspect name
```

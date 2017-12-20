---
title: "Docker快速入门（四）常用命令与技巧"
date: 2017-12-20T09:05:17+08:00
categories: ["docker"]
tags: [ "docker", "Docker快速入门" ]
---

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

### 镜像tar包保存与载入
在有些情况下，我们无法拉取镜像，比如网络原因或者没有私有仓库，这时可以将镜像保存为tar包文件，拷到其它机器上然后载入到docker里，然后就能愉快的使用镜像了
``` sh
# 保存
docker save –o ./myapp.tar myapp:latest

# 载入
docker load —i myapp.tar
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

### 停止容器
``` sh
# 通过容器别名
docker stop app

# 通过容器id
docker stop c62874e3750a

# 限定停止超时时间(单位：秒)
# 默认的stop是发送SIGTERM信号等待程序停止，
# 如果超过10秒还没停止才发送SIGKILL信号强制kill进程，
# 通过 -t 参数可以改变默认超时时间
docker stop -t 20 app

# 强制停止容器(直接发送SIGKILL信号)
docker kill app
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

### 查看后台运行容器的标准输出
``` sh
# 查看全部输出
docker logs c62874e3750a

# 查看全部输出并实时追加最新输出
docker logs c62874e3750a

# 限制最后N行
docker logs --tail 10 -f app
```

### 查看容器内运行的进程
``` sh
docker top c62874e3750a
```
![docker top](https://res.cloudinary.com/imroc/image/upload/v1513738482/blog/docker/docker-top.png)

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

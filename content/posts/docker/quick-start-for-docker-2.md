---
title: "Docker快速入门（二）容器、镜像与镜像仓库"
date: 2017-12-19T11:00:42+08:00
categories: ["docker"]
tags: [ "docker", "Docker快速入门" ]
---

# 镜像与容器的关系
镜像就是把你程序以及依赖的运行时打包在一起的一个东东，运行一个镜像就成了容器。镜像与容器的关系有点类似程序与进程的关系，比如windows上的exe可执行文件是程序，双击运行它就有了进程，镜像可以看成程序，容器可以看成进程。

# 镜像仓库
镜像仓库的作用是存放镜像的地方，官方术语叫 Registry，默认的仓库是 [Docker Hub](https://hub.docker.com/)，它属于公有仓库，很多常用的镜像都来源于这里，有官方的，有个人的。  
  
除了公有仓库之外，还有私有仓库，主要企业内部用，一方面可以加快镜像拉取速度，另一方面可以提高安全性，避免将企业内部的程序泄露出去。Docker官方有开源docker-registry，不过功能比较简陋，连web ui都没有，通常搭建企业级docker私有仓库会选择 [Harbor](https://github.com/vmware/harbor)

# 标签
镜像可以打标签，拉取镜像不加标签的化默认用的是latest，用来标识版本，比如我的程序要发布新的版本到镜像仓库，版本号为1.2.3，那么我可以给这个新版本镜像打上几个tag，分别是：1.2.3, 1.2, latest。 这样别人拉取镜像的时候如果不加tag，默认会拉取这个最新版，如果拉取的时候加1.2或1.2.3的tag，也会拉取到这个版本的镜像。

# 制作镜像

### 1. docker commit
这种方式类似 git commit，通过某个镜像运行一个容器，做些修改操作，然后提交成一个新的镜像。  
  
比如你拉取一个ubuntu镜像，通过它启动一个容器，进入容器，然后安装java和ruby环境，装好后使用docker commit命令来将这个容器保存成一个新的镜像，这个镜像同时具有java和ruby环境。  
  
语法：
``` sh
docker commit <container> [repo:tag]
```
这种做法的优点是方便快速，缺点是不规范、无法自动化，也就不方便在一个团队中分享，所以通常我们会采用下面Dockerfile这种方式。

### 2. Dockerfile
这种方式是编写一个 Dockerfile 文件，然后使用 docker build 命令来编译出镜像，文件格式就不赘述了，直接举个栗子：
``` Dockerfile
# 这里是注释

# 设置继承自哪个镜像
FROM ubuntu:16.04

# 下面是一些创建者的基本信息
MAINTAINER roc<imrocchan@gmail.com>

# 在终端需要执行的命令
RUN apt-get install -y openjdk

# 将当前目录的jar包拷到镜像里
COPY app.jar /root/app.jar

# 设置默认运行命令
CMD ["java", "-jar", "/root/app.jar"]
```
写好Dockerfile之后就可以编译镜像了，比如：
``` sh
docker build . -t imroc/myapp:latest
```
# 上传镜像
上传前事先确保你已经登录了，利用docker login 命令进行登录，如果是Docker Hub，直接执行docker login 即可登录，如果是私有仓库，需要在后面加上私有仓库的地址，比如：
```sh
docker login hub.imroc.io
```
然后输入你所在仓库的用户名密码即可，一般登录了只要没有重启docker daemon就能一直保持登录，不需要重复登录。  
上传镜像需要用到`docker push`命令，前提是你的镜像名符合规范。如果你想上传到私有仓库，那么你的镜像名前面需要加私有仓库地址，例如：`hub.imroc.io/imroc/myapp:1.2`，那么执行下面的命令就能上传镜像到私有仓库:
```sh
docker push hub.imroc.io/imroc/myqpp:1.2
```
如果是上传到 Docker Hub，你就不需要将仓库地址写出来了，因为默认就是Docker Hub，比如我的镜像名叫`imroc/myqpp:latest`，那么执行下面的命令就能上传到Docker Hub，所有人都可以拉取下来使用：
```sh
docker push imroc/myapp:latest
```
  

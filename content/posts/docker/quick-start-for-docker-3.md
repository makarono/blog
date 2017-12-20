---
title: "Docker快速入门（三）在国内如何快速安装Docker与镜像加速器配置"
date: 2017-12-19T16:27:07+08:00
categories: ["docker"]
tags: [ "docker", "Docker快速入门" ]
---

# 快速安装Docker
Docker官方文档给出的安装方式会比较慢，因为提供软件源的服务器在国外，下载速度有时慢的像蜗牛，简直不能忍，现在就给大家介绍如何在国内愉快的安装Docker

### 通用安装
适用于Ubuntu，Debian, Centos等大部分Linux
``` sh
curl -sSL https://get.daocloud.io/docker | sh
```
### Ubuntu 14.04/16.04
#### 一键安装
``` sh
curl -sSL http://acs-public-mirror.oss-cn-hangzhou.aliyuncs.com/docker-engine/internet | sh -
```
#### 分步骤安装
``` sh
# step 1: 安装必要的一些系统工具
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
# step 2: 安装GPG证书
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
# Step 3: 写入软件源信息
sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
# Step 4: 更新并安装 Docker-CE
sudo apt-get -y update
sudo apt-get -y install docker-ce

# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
# apt-cache madison docker-ce
#   docker-ce | 17.03.1~ce-0~ubuntu-xenial | http://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
#   docker-ce | 17.03.0~ce-0~ubuntu-xenial | http://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
# Step 2: 安装指定版本的Docker-CE: (VERSION 例如上面的 17.03.1~ce-0~ubuntu-xenial)
# sudo apt-get -y install docker-ce=[VERSION]
```


### CentOS 7
``` sh
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3: 更新并安装 Docker-CE
sudo yum makecache fast
sudo yum -y install docker-ce
# Step 4: 开启Docker服务
sudo service docker start

# 注意：
# 官方软件源默认启用了最新的软件，您可以通过编辑软件源的方式获取各个版本的软件包。例如官方并没有将测试版本的软件源置为可用，你可以通过以下方式开启。同理可以开启各种测试版本等。
# vim /etc/yum.repos.d/docker-ee.repo
#   将 [docker-ce-test] 下方的 enabled=0 修改为 enabled=1
#
# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
# yum list docker-ce.x86_64 --showduplicates | sort -r
#   Loading mirror speeds from cached hostfile
#   Loaded plugins: branch, fastestmirror, langpacks
#   docker-ce.x86_64            17.03.1.ce-1.el7.centos            docker-ce-stable
#   docker-ce.x86_64            17.03.1.ce-1.el7.centos            @docker-ce-stable
#   docker-ce.x86_64            17.03.0.ce-1.el7.centos            docker-ce-stable
#   Available Packages
# Step2 : 安装指定版本的Docker-CE: (VERSION 例如上面的 17.03.0.ce.1-1.el7.centos)
# sudo yum -y install docker-ce-[VERSION]
```

### CentOS 6
``` sh
yum install –y http://mirrors.yun-idc.com/epel/6/i386/epel-release-6-8.noarch.rpm
yum install –y docker-io
```

# 配置加速器
比较常用的镜像加速器是阿里云和Daocloud的，都是免费的，不过加速器地址并不是公有的，每个人不一样，要获取你自己的加速地址前提是需要登录。

## 阿里云
登录后进入 [https://cr.console.aliyun.com/#/accelerator](https://cr.console.aliyun.com/#/accelerator)
  
![aliyun](https://res.cloudinary.com/imroc/image/upload/v1513735608/blog/docker/aliyun-accelerator.png)

## Daocloud
登录后进入 [https://www.daocloud.io/mirror#accelerator-doc](https://www.daocloud.io/mirror#accelerator-doc)
  
![daocloud](https://res.cloudinary.com/imroc/image/upload/v1513734634/blog/docker/daocloud-accelerator.png)

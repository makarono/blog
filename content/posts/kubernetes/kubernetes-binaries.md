---
title: "Kubernetes程序二进制下载集合"
date: 2018-01-05T13:43:15+08:00
subtitle: "Kubernetes Binaries"
categories: ["kubernetes"]
tags: ["docker", "kubernetes"]
---

# 前言
由于国内网络的特殊性，安装Kubernetes很多时候会采用二进制方式部署，我将涉及到的二进制传到百度云，方便大家下载。  
  
Kubernetes在Github的[Release](https://github.com/kubernetes/kubernetes/releases)页面其实已经有压缩包下载，但是在国内下载很慢，而且里面并不包含安装所需的程序二进制文件，需要执行里面的`./kubernetes/cluster/get-kube-binaries.sh`这个脚本去下载得到文件`./kubernetes/server/kubernetes-server-linux-amd64.tar.gz`，然而这在国内并不能直接下载。

# 下载链接
下载地址为百度云，根据版本号组织的目录，文件名保持从官方下载下来时的名字不变：

- `kubernetes.tar.gz`: Github Release 页面的压缩包（不含程序二进制）  
- `kubernetes-server-linux-amd64.tar.gz`: Kubernetes所需的程序二进制压缩包   

链接：[https://pan.baidu.com/s/1dFrVjHZ](https://pan.baidu.com/s/1dFrVjHZ)

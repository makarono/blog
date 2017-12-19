---
title: "Docker快速入门（一）认识Docker"
date: 2017-12-18T15:36:35+08:00
categories: ["docker"]
tags: [ "docker", "Docker快速入门" ]
---

# 前言
Docker现在可以说是火的一塌糊涂，做技术的几乎都听过这个名词，只是有些小伙伴还没理解Docker到底是个什么东西，能够用来做些什么，解决什么问题以及到底怎么用。  
  
现在就来给大家介绍下，不用怕，我会去除不重要的细节，用最简洁直白的语言表述，也不会深入复杂的底层原理，不准确，但能让你快速理解。

# 什么是 Docker
Docker其实就是容器，那什么是容器？很多回答和定义都太复杂了，通俗的讲，容器就是可以把你的程序以及所需要的运行时环境打包成镜像，只要机器上装了docker，那你的程序就一定能运行，不会因为环境不同导致程序运行不了这种常见又让人头疼的问题。就像它的logo一样，它就是一个集装箱，把你程序所需要的东西都打包在一起，实现 "一次封装，到处运行" 。  
![logo](https://www.docker.com/sites/default/files/Whale%20Logo332%402x_5.png)
  

## Docker vs VM
容器技术与虚拟机技术都属于虚拟化技术，但又不同。通俗来讲，容器很轻，虚拟机很重。秒秒钟就能轻松启动一个容器，并且资源占用很低，主要取决于你的程序本身，而虚拟机除开你的程序还需要运行一大堆其它东西，启动慢并且资源占用很高。  
  
容器相比虚拟机，去除了硬件与内核的高成本虚拟化，利用容器引擎让你的程序直接跑在宿主机的硬件与内核之上，运行成本大大降低。  
  
<img src="http://img3.tbcdn.cn/L1/461/1/75b502be6bc8585968f9895bf086cf7b7cdab9c8" width="80%">

# Docker 的历史（精简版）
2010年，几个大胡子年轻人在旧金山成立了一家做PaaS平台的公司，起名为「dotCloud」，dotCloud主要是基于PaaS平台为开发者或开发商提供技术服务。  
  
2013年3月， Docker正式作为公开项目发布。  
  
2013年10月， DotCloud公司改名为Docker Inc，转型专注于Docker引擎和Docker生态系统。  
  
2015年6月， DockerCon 2015大会上，Docker与CoreOS联合推出Open Container Project，目标是实现容器镜像格式与运行时的标准化。

2017年4月， DockerCon 2017大会宣布Docker项目更名为Moby，产品名保持Docker不变，同时开源LinuxKit。旨在更加开放，开发者可利用它们做出类似Docker的东西。

2017年10月， DockerCon Europe大会宣布Docker官方将支持Kubernetes，容器编排大战Kubernetes胜出，成为事实标准。

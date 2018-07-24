---
title: "利用Helm一键部署Kubernetes Dashboard并启用免费HTTPS"
date: 2018-07-23T21:49:54+08:00
bigimg: [{src: "https://res.cloudinary.com/imroc/image/upload/v1532442991/blog/banner/dashboard.jpg", desc: "Dashboard"}]
categories: ["kubernetes"]
tags: ["kubernetes"]
---

## 概述

Kubernetes Dashboard 是一个可以可视化查看和操作 Kubernetes 集群的一个插件

- 本文利用 Helm 部署它，所以请确保 Helm 已安装，安装方法参考：https://imroc.io/posts/kubernetes/install-helm
- 本文使用 Nginx Ingress Controller 暴露 Kubernetes Dashboard 服务到外部，Nginx Ingress Controller 安装参考：https://imroc.io/posts/kubernetes/use-nginx-ingress-controller-to-expose-service
- 有域名，并且配置 DNS，IP 指向 Ingress Controller 对外暴露的地址
- 本文使用 cert-manager 生成免费证书，安装和使用参考：https://imroc.io/posts/kubernetes/let-ingress-enable-free-https-with-cert-manager

## 安装

先自定义 helm 的 chart 配置:

``` bash
vi values.yaml
```
``` yaml
#Default values for kubernetes-dashboard
# This is a YAML-formatted file.
# Declare name/value pairs to be passed into your templates.
# name: value

image:
  repository: k8s.gcr.io/kubernetes-dashboard-amd64
  tag: v1.8.3
  pullPolicy: IfNotPresent

replicaCount: 1

## Here labels can be added to the kubernetes dashboard deployment
##
labels: {}
# kubernetes.io/cluster-service: "true"
# kubernetes.io/name: "Kubernetes Dashboard"

## Additional container arguments
##
#extraArgs:
#  - --enable-insecure-login
#  - --system-banner="Welcome to Kubernetes"
#  - --port=8444 # By default, https uses 8443 so we move it away to something else
#  - --insecure-port=8443 # The chart has 8443 hard coded as a containerPort in the deployment spec so we must use this internally for the http service
#  - --insecure-bind-address=0.0.0.0

## Node labels for pod assignment
## Ref: https://kubernetes.io/docs/user-guide/node-selection/
##
nodeSelector: {}

## List of node taints to tolerate (requires Kubernetes >= 1.6)
tolerations: []
#  - key: "key"
#    operator: "Equal|Exists"
#    value: "value"
#    effect: "NoSchedule|PreferNoSchedule|NoExecute"

service:
  type: ClusterIP
  externalPort: 443

  ## This allows an override of the heapster service name
  ## Default: {{ .Chart.Name }}
  ##
  # nameOverride:

  ## Kubernetes Dashboard Service annotations
  ##
  annotations: {}
  # foo.io/bar: "true"

  ## Here labels can be added to the Kubernetes Dashboard service
  ##
  labels: {}
  # kubernetes.io/name: "Kubernetes Dashboard"

resources:
  limits:
    cpu: 100m
    memory: 50Mi
  requests:
    cpu: 100m
    memory: 50Mi

ingress:
  ## If true, Kubernetes Dashboard Ingress will be created.
  ##
  enabled: true

  ## Kubernetes Dashboard Ingress annotations
  ##
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/secure-backends: "true"
    #nginx.ingress.kubernetes.io/configuration-snippet: |
    #  proxy_set_header "Host: 127.0.0.1";
    #kubernetes.io/tls-acme: 'true'

  ## Kubernetes Dashboard Ingress path
  ##
  path: /

  ## Kubernetes Dashboard Ingress hostnames
  ## Must be provided if Ingress is enabled
  ##
  hosts:
    - dashboard.imroc.io

  ## Kubernetes Dashboard Ingress TLS configuration
  ## Secrets must be manually created in the namespace
  ##
  tls:
   - secretName: dashboard-imroc-io-tls
     hosts:
       - dashboard.imroc.io

rbac:
  # Specifies whether RBAC resources should be created
  create: true

  # Specifies whether cluster-admin ClusterRole will be used for dashboard
  # ServiceAccount (NOT RECOMMENDED).
  clusterAdminRole: true

serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name:
```

相比默认配置，修改了以下配置项：

- ingress.enabled - 置为 true 开启 Ingress，用 Ingress 将 Kubernetes Dashboard 服务暴露出来，以便让我们浏览器能够访问
- ingress.annotations - 指定 `ingress.class` 为 nginx，让我们安装 Nginx Ingress Controller 来反向代理 Kubernetes Dashboard 服务；由于 Kubernetes Dashboard 后端服务是以 https 方式监听的，而 Nginx Ingress Controller 默认会以 HTTP 协议将请求转发给后端服务，用`secure-backends`这个 annotation 来指示 Nginx Ingress Controller 以 HTTPS 协议将请求转发给后端服务
- ingress.hosts - 这里替换为证书配置的域名
- Ingress.tls - secretName 配置为 cert-manager 生成的免费证书所在的 Secret 资源名称，hosts 替换为证书配置的域名
- rbac.clusterAdminRole - 置为 true 让 dashboard 的权限够大，这样我们可以方便操作多个 namespace

安装：

``` bash
helm install stable/kubernetes-dashboard \
  --name dashboard \
  --namespace dashboard \
  -f values.yaml
```

安装完成后在浏览器通过域名就能访问 Kubernetes Dashboard 啦，而且是有信任的证书，不需要手动点击信任该站点 ~~

![kubernetes-dashboard](https://res.cloudinary.com/imroc/image/upload/v1532357376/blog/k8s/kubernetes-dashboard.png)

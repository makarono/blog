---
title: "国内使用kubeadm安装kubenetes"
date: 2017-12-26T15:41:42+08:00
draft: true
categories: ["kubernetes"]
tags: ["docker", "kubernetes", "kubeadm"]
---

# 集群详情
1. OS: CentOS Linux release 7.4.1708 (Core) 3.10.0-693.2.1.el7.x86_64
2. Kubernetes 1.9
3. Docker 17.03.2-ce


# 所有机器上的准备操作

### 修改系统配置
开启`bridge-nf-call-iptables`:
``` sh
echo "1" > /proc/sys/net/bridge/bridge-nf-call-iptables
```
关闭SELinux:
``` sh
vi /etc/selinux/config
```
确保`SELINUX=disabled`，修改后重启一下，如果本身就是`disabled`就不用管。

### 安装docker
**注意：**不要安装`docker-ce`，kubeadm初始化时会作一些检查，centos的docker软件包不推荐`docker-ce`，直接是`docker`:
``` sh
sudo yum install -y docker
systemctl enable docker && systemctl start docker
```

### 安装kubelet kubeadm kubectl
添加阿里云镜像：
``` sh
sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```
安装：
``` sh
sudo yum install -y kubelet kubeadm kubectl
sudo systemctl enable kubelet && sudo systemctl start kubelet
```

# Master上的操作

### 使用kubeadm初始化master
编写kubeadm初始化所需的配置文件:
``` sh
vi kubeadm.yml
```
内容如下：
``` yaml
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
imageRepository: gcrio
kubernetesVersion: v1.9.0
networking:
  podSubnet: 10.10.0.0/16
```
执行初始化命令：
``` sh
kubeadm init --config kubeadm.yml --pod-network-cidr=10.10.0.0/16
```

## 安装 kubeadm
## 依赖
ebtables kubernetes-cni socat

``` sh
# 安装二进制
sudo cp kubelet kubeadm kubectl /usr/bin/

# kubelet 服务配置
sudo cat <<EOF > /lib/systemd/system/kubelet.service
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=http://kubernetes.io/docs/

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 建立符号链接
systemctl enable kubelet.service



# kubeadm 配置
mkdir -p /etc/systemd/system/kubelet.service.d
sudo cat <<EOF > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf [Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_CADVISOR_ARGS $KUBELET_CERTIFICATE_ARGS $KUBELET_EXTRA_ARGS
EOF


# k8s配置目录
mkdir -p /etc/kubernetes/manifests
```

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni

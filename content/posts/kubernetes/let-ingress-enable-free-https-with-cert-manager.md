---
title: "利用cert-manager让Ingress启用免费的HTTPS证书"
date: 2018-07-23T20:08:01+08:00
bigimg: [{src: "https://res.cloudinary.com/imroc/image/upload/v1532442989/blog/banner/blue-number.jpg", desc: "cert"}]
categories: ["kubernetes"]
tags: ["kubernetes"]
---

## 概述

cert-manager 是替代 kube-lego 的一个开源项目，用于在 Kubernetes 集群中自动提供 HTTPS 证书，支持 [Let’s Encrypt](https://letsencrypt.org/), [HashiCorp Vault](https://www.vaultproject.io/) 这些免费证书的签发。

- 本文使用 Helm 安装，所以请确保 Helm 已安装，安装方法参考：https://imroc.io/posts/kubernetes/install-helm
- 你的集群必须已经装有 Ingress Controller，如果还没有，参考：https://imroc.io/posts/kubernetes/use-nginx-ingress-controller-to-expose-service
- 需要颁发免费证书的域名配置DNS记录，IP 指向 Ingress Controller 对外暴露的地址
- 开源地址：https://github.com/jetstack/cert-manager
- 文档地址：https://cert-manager.readthedocs.io

## 安装 cert-manager

``` bash
helm install \
    --name cert-manager \
    --namespace kube-system \
    stable/cert-manager
```

一键安装，非常简单。

## 生成免费证书

我们需要先创建一个签发机构，cert-manager 给我们提供了 Issuer 和 ClusterIssuer 这两种用于创建签发机构的自定义资源对象，Issuer 只能用来签发自己所在 namespace 下的证书，ClusterIssuer 可以签发任意 namespace 下的证书，这里以 ClusterIssuer 为例创建一个签发机构：

``` bash
vi issuer.yaml
```

``` yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: roc@imroc.io
    privateKeySecretRef:
      name: letsencrypt-prod
    http01: {}
```

- metadata.name 是我们创建的签发机构的名称，后面我们创建证书的时候会引用它
- spec.acme.email 是你自己的邮箱，证书快过期的时候会有邮件提醒，不过 cert-manager 会利用 acme 协议自动给我们重新颁发证书来续期
- spec.acme.server 是 acme 协议的服务端，我们这里用 Let’s Encrypt，这个地址就写死成这样就行
- spec.acme.privateKeySecretRef 指示此签发机构的私钥将要存储到哪个 Secret 对象中，名称不重要
- spec.acme.http01 这里指示签发机构使用 HTTP-01 的方式进行 acme 协议 (还可以用 DNS 方式，acme 协议的目的是证明这台机器和域名都是属于你的，然后才准许给你颁发证书)

创建：

``` bash
kubectl apply -f issuer.yaml
```



有了签发机构，接下来我们就可以生成免费证书了，cert-manager 给我们提供了 Certificate 这个用于生成证书的自定义资源对象，它必须局限在某一个 namespace 下，证书最终会在这个 namespace 下以 Secret 的资源对象存储，假如我想在 `dashboard` 这个 namespace 下生成免费证书（这个 namespace 已存在)，创建一个 Certificate 对象：

``` bash
vi cert.yaml
```

``` yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: dashboard-imroc-io
  namespace: dashboard
spec:
  secretName: dashboard-imroc-io-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - dashboard.imroc.io
  acme:
    config:
    - http01:
        ingressClass: nginx
      domains:
      - dashboard.imroc.io
```

- spec.secretName 指示证书最终存到哪个 Secret 中
- spec.issuerRef.kind 值为 ClusterIssuer 说明签发机构不在本 namespace 下，而是在全局
- spec.issuerRef.name 我们创建的签发机构的名称 (ClusterIssuer.metadata.name)
- spec.dnsNames 指示该证书的可以用于哪些域名
- spec.acme.config.http01.ingressClass 使用 HTTP-01 方式校验该域名和机器时，cert-manager 会尝试创建Ingress 对象来实现该校验，如果指定该值，会给创建的 Ingress 加上 `kubernetes.io/ingress.class` 这个 annotation，如果我们的 Ingress Controller 是 Nginx Ingress Controller，指定这个字段可以让创建的 Ingress 被 Nginx Ingress Controller 处理。
- spec.acme.config.http01.domains 指示该证书的可以用于哪些域名

创建：

``` bash
kubectl apply -f cert.yaml
```

通过这些可以查看我们所创建的 Certificate 和 ClusterIssuer 对象:

``` bash
$ kubectl get certificate -n dashboard
NAME                 AGE
dashboard-imroc-io   9h

$ kubectl describe -n dashboard certificate/dashboard-imroc-io
Name:         dashboard-imroc-io
Namespace:    dashboard
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"certmanager.k8s.io/v1alpha1","kind":"Certificate","metadata":{"annotations":{},"name":"dashboard-imroc-io","namespace":"dashboard"},"spe...
API Version:  certmanager.k8s.io/v1alpha1
Kind:         Certificate
Metadata:
  Cluster Name:
  Creation Timestamp:  2018-07-23T03:57:06Z
  Generation:          0
  Initializers:        <nil>
  Resource Version:    2305547834
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/dashboard/certificates/dashboard-imroc-io
  UID:                 7761c129-8e2c-11e8-bf16-525400319744
Spec:
  Acme:
    Config:
      Domains:
        dashboard.imroc.io
      Http 01:
        Ingress:
        Ingress Class:  nginx
  Common Name:
  Dns Names:
    dashboard.imroc.io
  Issuer Ref:
    Kind:       ClusterIssuer
    Name:       letsencrypt-prod
  Secret Name:  dashboard-imroc-io-tls
Status:
  Acme:
    Order:
      URL:  https://acme-v02.api.letsencrypt.org/acme/order/38817431/21090610
  Conditions:
    Last Transition Time:  2018-07-23T03:57:56Z
    Message:               Certificate issued successfully
    Reason:                CertIssued
    Status:                True
    Type:                  Ready
    Last Transition Time:  <nil>
    Message:               Order validated
    Reason:                OrderValidated
    Status:                False
    Type:                  ValidateFailed
Events:                    <none>

$ kubectl get clusterissuer -n dashboard
NAME               AGE
letsencrypt-prod   9h

$ kubectl describe clusterissuer/letsencrypt-prod
Name:         letsencrypt-prod
Namespace:
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"certmanager.k8s.io/v1alpha1","kind":"ClusterIssuer","metadata":{"annotations":{},"name":"letsencrypt-prod","namespace":""},"spec":{"acme...
API Version:  certmanager.k8s.io/v1alpha1
Kind:         ClusterIssuer
Metadata:
  Cluster Name:
  Creation Timestamp:  2018-07-23T03:41:18Z
  Generation:          0
  Initializers:        <nil>
  Resource Version:    2305474410
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/letsencrypt-prod
  UID:                 427459c2-8e2a-11e8-bf16-525400319744
Spec:
  Acme:
    Email:  roc@imroc.io
    Http 01:
    Private Key Secret Ref:
      Key:
      Name:  letsencrypt-prod
    Server:  https://acme-v02.api.letsencrypt.org/directory
Status:
  Acme:
    Uri:  https://acme-v02.api.letsencrypt.org/acme/acct/38817431
  Conditions:
    Last Transition Time:  2018-07-23T03:41:25Z
    Message:               The ACME account was registered with the ACME server
    Reason:                ACMEAccountRegistered
    Status:                True
    Type:                  Ready
Events:                    <none>
```

生成的证书被存到 Secret 了，可以看下在不在：

``` bash
$ kubectl get secret -n dashboard
NAME                                         TYPE                                  DATA      AGE
dashboard-imroc-io-tls                       kubernetes.io/tls                     2         9h
```

这个 Secret 可以被我们创建的 Ingress 使用来启用免费 HTTPS，来测试一下吧：

``` bash
vi my-nginx.yaml
```

``` yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 443
---
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  labels:
    app: my-nginx
spec:
  ports:
  - port: 443
    protocol: TCP
    name: https
  selector:
    run: my-nginx
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: my-nginx
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: dashboard.imroc.io
    http:
      paths:
      - backend:
          serviceName: my-nginx
          servicePort: 443
        path: /
  tls:
   - secretName: dashboard-imroc-io-tls
     hosts:
       - dashboard.imroc.io
```

- 在 Ingress 定义的 spec.tls.secretName 引用生成的证书所在的 Secret 名称即可实现使用免费证书
- 将 Ingress 定义的 spec.rules.host 和 spec.tls.hosts 里的域名都替换为你自己的域名

创建：

``` bash
kubectl apply -f my-nginx.yaml
```

现在通过域名访问，是不是就能看到 `Welcome to nginx!` 主页里呢？

---
title: "对比Kubernetes的Nodeport、Loadbalancer和Ingress，什么时候该用哪种"
bigimg: [{src: "https://res.cloudinary.com/imroc/image/upload/v1520952425/blog/k8s/scifi-banner.jpg", desc: "ingress"}]
date: 2018-03-13T22:45:26+08:00
categories: ["kubernetes"]
tags: ["kubernetes"]
---
> 本文翻译自：[https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0)

最近，有人问我 NodePort，LoadBalancer 和 Ingress 之间的区别是什么。 它们是将外部流量引入群集的不同方式，并且实现方式不一样。 我们来看看它们是如何工作的，以及什么时候该用哪种。  
  
**注意：**本文适用于 [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)。 如果你在其他公有云、混合云、minikube 等上运行，可能会略有不同。 例如，您不能在 minikube 上使用 LoadBalancer。 我也没有深入技术细节。 如果您有兴趣了解更多，[官方文档](https://kubernetes.io/docs/concepts/services-networking/service/)是一个很好的资源！

## ClusterIP
ClusterIP 服务是默认的 Kubernetes 服务。 它为您提供集群内部其他应用程序可以访问的服务， 外部无法访问。  
  
ClusterIP 服务的 YAML 类似这样：
``` yaml
apiVersion: v1
kind: Service
metadata:  
  name: my-internal-service
selector:    
  app: my-app
spec:
  type: ClusterIP
  ports:  
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
```

如果你不能从集群外部上访问一个 ClusterIP 服务，我为什么要谈论它？ 因为你可以使用 Kubernetes Proxy 来访问它！
<img src="https://res.cloudinary.com/imroc/image/upload/v1520947097/blog/k8s/kubernetes-proxy.png">
启动 Kubernetes Proxy:
``` bash
$ kubectl proxy --port=8080
```
现在，你可以使用如下的 Kubernetes API 访问服务：
``` bash
http://localhost:8080/api/v1/proxy/namespaces/<NAMESPACE>/services/<SERVICE-NAME>:<PORT-NAME>/
```
所以，如果要访问我们刚刚定义的服务，可以使用下面的地址：
``` bash
http://localhost:8080/api/v1/proxy/namespaces/default/services/my-internal-service:http/
```

### 什么时候用？
有几种情况可以使用 Kubernetes Proxy 来访问您的服务：

- 调试您的服务，或由于某种原因直接从你笔记本电脑连接到它们
- 允许内部流量，显示内部仪表盘等

由于此方法要求您用已授权用户运行 kubectl ，因此您不应该使用此方法将您的服务公开到公网上或将其用于生产。

## NodePort
NodePort 服务是暴露服务的最原始方式。 顾名思义，NodePort 会在所有节点（VM）上打开一个特定的端口，并且发送到此端口的任何流量都将转发到该服务。
<img src="https://res.cloudinary.com/imroc/image/upload/v1520948622/blog/k8s/kubernetes-nodeport.png">
NodePort 服务的 YAML 类似这样：
``` yaml
apiVersion: v1
kind: Service
metadata:  
  name: my-nodeport-service
selector:    
  app: my-app
spec:
  type: NodePort
  ports:  
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30036
    protocol: TCP
```
基本上，NodePort 服务与普通的 “ClusterIP” 服务 YAML 定义有两点区别。 首先，type 是 “NodePort”。还有一个称为 nodePort 的附加端口，指定在节点上打开哪个端口。 如果你不指定这个端口，它会选择一个随机端口。
### 什么时候用？
这种方法有许多缺点：

- 每个端口只能有一个服务
- 默认您只能使用端口30000-32767
- 如果您的 节点/虚拟机 IP 地址发生更改，则需要处理该问题

由于这些原因，我不建议在生产中使用这种方法。 如果您运行的服务不必始终可用，或者您非常关注成本，则此方法适用于您，比如演示程序或临时应用。

## LoadBalancer
LoadBalancer 服务暴露服务的标准方式。 在 GKE 上，这将启动一个[网络负载平衡器](https://cloud.google.com/compute/docs/load-balancing/network/)，它将为您提供一个将所有流量转发到您的服务的IP地址。
<img src="https://res.cloudinary.com/imroc/image/upload/v1520949676/blog/k8s/kubernetes-loadbalancer.png">
### 什么时候用？
如果你想直接暴露一个服务，这是默认的方法(GKE上)。 您指定的端口上的所有流量都将被转发到该服务， 没有过滤、路由等。这意味着您可以发送几乎任何类型的流量，如 HTTP，TCP，UDP，Websockets，gRPC 或其他。

最大的缺点是，您使用 LoadBalancer 公开的每项服务都将获得自己的 IP 地址，并且您必须为每个暴露的服务使用一个 LoadBalancer，这可能会付出比较大的代价！

## Ingress
与以上所有例子不同，Ingress 实际上不是一种服务。相反，它位于多个服务之前，充当集群中的“智能路由器”或入口点。

您可以使用 Ingress 做很多不同的事情，并且有许多类型的 Ingress 控制器，具有不同的功能。

GKE 默认的 Ingress 控制器将为您启动一个 [HTTP（S）负载均衡器](https://cloud.google.com/compute/docs/load-balancing/http/)。 这将使您可以执行基于路径和基于子域名的路由到后端服务。 例如，您可以将 foo.yourdomain.com 上的所有内容发送到 foo 服务，并将 yourdomain.com/bar/ 路径下所有内容发送到 bar 服务的。
<img src="https://res.cloudinary.com/imroc/image/upload/v1520951161/blog/k8s/kubernetes-ingress.png">
在 GKE 上的 [七层 HTTP 负载均衡器](https://cloud.google.com/compute/docs/load-balancing/http/) 的 Ingress 对象 YAML 定义类似这样：
``` yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: my-ingress
spec:
  backend:
    serviceName: other
    servicePort: 8080
  rules:
  - host: foo.mydomain.com
    http:
      paths:
      - backend:
          serviceName: foo
          servicePort: 8080
  - host: mydomain.com
    http:
      paths:
      - path: /bar/*
        backend:
          serviceName: bar
          servicePort: 8080
```
### 什么时候用？
Ingress 可能是暴露服务最强大的方式了，但也可能是最复杂的。 来自 [Google Cloud Load Balancer](https://cloud.google.com/kubernetes-engine/docs/tutorials/http-balancer), [Nginx](https://github.com/kubernetes/ingress-nginx), [Contour](https://github.com/heptio/contour), [Istio](https://istio.io/docs/tasks/traffic-management/ingress.html) 等的 Ingress 控制器类型很多。 还有用于 Ingress 控制器的插件，如 [cert-manager](https://github.com/jetstack/cert-manager)，可以为您的服务自动提供 SSL 证书。

如果您希望在相同的 IP 地址下暴露多个服务，并且这些服务都使用相同的L7协议（通常是HTTP），则 Ingress 是最有用的。 如果您使用原生 GCP 集成，您只需支付一个负载平衡器，由于 Ingress 很“智能”，您可以获得许多开箱即用的功能（如 SSL，Auth，路由等）

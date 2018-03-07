# 使用bootkube安装自托管的kubernetes

## 自托管kubernetes

简单来说，就是将kubernetes运行在kubernetes上，不管 master 还是 worker 节点，都只需要安装 kubelet 和 容器运行时（通常是docker）这两个必要的组件，其它组件都运行在容器中，并由 kubelet 管理。
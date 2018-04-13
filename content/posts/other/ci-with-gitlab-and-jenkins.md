---
title: "利用Gitlab和Jenkins做CI(持续集成)"
date: 2018-04-13T22:23:22+08:00
tags: ["CI"]
---

# 利用Gitlab和Jenkins做CI(持续集成)

最近用到持续集成顺便总结在这里，都是用的最新版。搭建过程中还有一个demo，提交代码到 gitlab 自动触发 jenkins 任务，自动编译代码和 docker 镜像并上传。

## 安装运行 Gitlab

> gitlab 国内安装很麻烦，用官方的源装不了，因为在国外，太慢，链接会断掉。国内清华有 gitlab 的 apt 和 yum 源，但是我试过安装 CentOS 7 的 gitlab ，到最后都会一直卡住结束不了。直接下载清华 gitlab 的 rpm mirror 安装也是一样，所以我还是选择用 docker 启动 gitlab（提前配好 docker hub 加速器）



准备镜像

``` bash
docker pull gitlab/gitlab-ee:latest
```

准备 gitlab 所需目录

``` bash
mkdir gitlab
cd gitlab
mkdir config logs data
```

准备启动脚本 （替换想要的启动端口，ip 地址替换为访问你的 gitlab 的地址，也可以替换想要的挂载目录）

``` bash
cat << EOF > run
#! /bin/bash

sudo docker run -d --rm \
    -p 8088:8088 \
    --name gitlab \
    --env GITLAB_OMNIBUS_CONFIG="external_url 'http://118.24.64.246:8088/'; gitlab_rails['lfs_enabled'] = true;" \
    -v $PWD/config:/etc/gitlab \
    -v $PWD/logs:/var/log/gitlab \
    -v $PWD/data:/var/opt/gitlab \
    gitlab/gitlab-ee:latest
EOF

chmod +x run
```

启动 gitlab

``` bash
./run
```

查看 gitlab 控制台输出

``` bash
docker logs -f gitlab
```

访问 gitlab，打开脚本中配置的 external_url 地址，设置管理员密码和注册 gitlab 账号，登录并添加自己的 SSH key 。创建 repo ，git clone 到本地，后面我们提交代码到这个 repo ，触发 jenkins 的持续集成。

## 安装运行 Jenkins

jenkins 建议直接安装在宿主机，不用 docker 方式，因为持续集成需要安装各种我们用到的工具，这些工具可能后面根据需要才安装，重启不能让这些工具丢失。比如编译 java 源码需要装 jdk 环境，编译和上传 docker 镜像需要安装 docker 环境，并且还需要提前 docker login 好，不然上传不了。

因为 jenkins 用 java 写的，所以确保机器上装有 jdk 或 openjdk 环境，准备一个 jenkins 用的目录，下载 war 包

``` bash
mkdir jenkins 
wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war
```

运行

``` bash
nohup java -jar jenkins.war --httpPort=8080 &> jenkins.log &
```

查看 jenkins 输出

``` bash
tail -f jenkins.log
```

第一次打开 jenkins web 界面，要求输出管理员初始密码，生成在服务器上，界面上提示有路径

<img src="https://res.cloudinary.com/imroc/image/upload/v1523432610/blog/ci/jenkins-initial.png">

查看密码

``` bash
cat /root/.jenkins/secrets/initialAdminPassword
```

粘贴密码并继续，安装推荐的插件，等待安装完成

<img src="https://res.cloudinary.com/imroc/image/upload/v1523433013/blog/ci/xsrm.png">

创建管理员，保存并完成

<img src="https://res.cloudinary.com/imroc/image/upload/v1523440941/blog/ci/create-admin.png">

至此，jenkins 安装完成

## Jenkins 安装需要的插件 

打开 Jenkins-系统设置-管理插件

<img src="https://res.cloudinary.com/imroc/image/upload/v1523440424/blog/ci/manage-plugin.png">

在可选插件里选择并安装需要的插件：Git 、 GitLab 、Build Authentication Token Root （Git插件在默认推荐插件里已安装，在可选插件列表里可能没有）

<img src="https://res.cloudinary.com/imroc/image/upload/v1523443519/blog/ci/install-plugin.png">

点击 “直接安装”，勾选 “安装完成后重启Jenkins(空闲时)“，等待安装完成自动重启 jenkins

<img src="https://res.cloudinary.com/imroc/image/upload/v1523443587/blog/ci/jenkins-plugin-install-and-restrart.png">

由于后面 Jenkins 的机器上需要用到 docker，所以保证 jenkins 所在机器安装好 docker 并 配好 docker hub 的加速器，并且 `docker login` 登录镜像要上传的仓库。

## Gitlab 创建 repo

我们这里就以一个简单的 golang 程序做实例，实现提交代码自动编译代码，然后 docker 编译镜像并上传至 CCR （腾讯云的 docker 镜像仓库)

在 gitlab 上创建空 repo，clone 到本地，添加三个文件

- main.go （源码）

  ``` bash
  package main

  func main() {
  	println("hello world")
  }
  ```

- Dockerfile （编译镜像用的 Dockerfile）

  ``` bash
  FROM alpine:latest

  MAINTAINER roc<rockerchen@tencent.com>

  COPY bd-ci-test /bin/bd-ci-test

  CMD ["bd-ci-test"]
  ```

- build （编译源码、镜像和上传镜像的脚本，替换 IMAGE 地址为要上传的地址）

  ```bash
  #! /bin/bash

  # 编译代码
  docker run --rm \
    -v $PWD:/go/src/bd-ci-test \
    -w /go/src/bd-ci-test \
    golang:alpine go build

  IMAGE="imroc/bd-ci-test:latest"

  # 编译镜像
  docker build -t $IMAGE .

  # 上传镜像 (请提前登录好,docker login 只需登录一次)
  docker push $IMAGE

  # 清理
  docker rmi $IMAGE
  rm bd-ci-test
  ```

给 build 脚本执行权限

``` bash
chmod +x build
```

至此，我们的代码准备好了，先不忙提交，接下来配置 jenkins  来做持续集成

## 配置 Jenkins

新建 jenkins 项目，选择 “构建一个自由风格的软件项目”

<img src="https://res.cloudinary.com/imroc/image/upload/v1523444143/blog/ci/jenkins-new-project.png">

源代码管理选 Git，Repository URL 填写你 gitlab 上源码 repo 的地址，Credentials 是拉取代码时需要用到的身份认证（如果你的repo不是公有的，没有身份认证就会报错）

<img src="https://res.cloudinary.com/imroc/image/upload/v1523451253/blog/ci/jenkins-git.png">

点击 Add 添加一个， Kind 选择 “Username with password"，输入 gitlab 账号密码

<img src="https://res.cloudinary.com/imroc/image/upload/v1523451426/blog/ci/jenkins-credentials.png">

然后 Credentials 选择我们刚刚添加的（检测到账号密码正确就不会报错了），我们准备对 master 分支的代码做持续集成，所以 "Branches to build" 填 "*/master"

<img src="https://res.cloudinary.com/imroc/image/upload/v1523451601/blog/ci/jenkins-git-after.png">

构建触发器选择 “Build when a change is pushed to GitLab” （后面的  URL 是我们需要在 gitlab 上配的 webhook 地址），按照下面勾选

<img src="https://res.cloudinary.com/imroc/image/upload/v1523452134/blog/ci/jenkins-construct-trigger.png">

点开高级，“Allowd branches" 勾选 "Filter branches by regex"，填写 "master"。点 "Generate" 生成 token，这个 token 用于填写到 gitlab 的 webhook 里，gitlab 检测到代码提交，会通知 webhook 里填写的 Jenkins 生成的回掉 URL，并带上这个 token，防止其它人触发 jenkins 的持续集成

<img src="https://res.cloudinary.com/imroc/image/upload/v1523452257/blog/ci/jenkins-advanced-trigger.png">

> **注:** 复制出 URL 和 token，我们后面配置 gitlab 的 webhook 会用到

增加构建步骤 “execute shell"

<img src="https://res.cloudinary.com/imroc/image/upload/v1523452676/blog/ci/jenkins-construct.png">

由于我们把持续集成的操作都写到 build 脚本了，所以直接填写执行 ./build 就可以了

<img src="https://res.cloudinary.com/imroc/image/upload/v1523453127/blog/ci/jenkins-build.png">

最后点击保存，至此，jenkins 的持续集成配置好了，还需要配置 gitlab 的 webhook，用于代码提交通知 jenkins。

## 配置 Gitlab Webhook

打开 gitlab 的 repo 的 Settings-Integrations

<img src="https://res.cloudinary.com/imroc/image/upload/v1523453629/blog/ci/gitlab-webhook.png">

URL 和 Secret Token 填写 jenkins 项目中构建触发器部分生成的，点击 "Add webhook"，搞定！

## 测试

现在我们可以提交代码测试一下

``` bash
git add .
git commit -m "test"
git push
```

我们可以看 jenkins 的输出来看是否触发任务，由于我使用了一些 docker hub 的镜像来编译代码和镜像，如果没有提前 pull 下来，第一次运行任务可能会比较久，等待运行结束，刷新 jenkins 主页

如果运行成功，从 “上次成功” 下拉选择 “控制台输出” 

<img src="https://res.cloudinary.com/imroc/image/upload/v1523453513/blog/ci/jenkins-console-tab.png">

可以看到运行任务过程的输出

<img src="https://res.cloudinary.com/imroc/image/upload/v1523453516/blog/ci/jenkins-console.png">

如果都没问题，你可以看看你的镜像仓库，镜像已经成功上传，至此，这个简单的持续集成搭建完毕。

## 附录

#### Git Submodule

如果你的项目里面还引用了其它项目，也就是 git 的 submodules，怎么办？甚至 submodule 里面还要指定分支呢？

在创建 jenkins 项目的时候，在 源码管理-Git-Additional Behaviours-Add 选择 Advanced sub-modules behaviours

<img src="https://res.cloudinary.com/imroc/image/upload/v1523628768/blog/ci/jekins-advanced-sub-modules.png">

勾选下面两个选项

<img src="https://res.cloudinary.com/imroc/image/upload/v1523628769/blog/ci/jenkins-additional-behaviours.png">

submodules 的分支靠 git 本来支持的 `.gitmodules` 文件来控制，用法举例：

``` bash
git submodule add -b v1 https://github.com/imroc/req.git ref/req
```

查看 `.gitmodules` 文件格式：

``` bash
$ cat .gitmodules
[submodule "ref/req"]
	path = ref/req
	url = https://github.com/imroc/req.git
	branch = v1
```

可以自己手动编辑或用 `git submodule add` 命令生成

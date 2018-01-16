---
title: "利用Hugo和Github Pages免费创建并永久托管网站"
description: "教你如何免费建立自己的网站"
bigimg: [{src: "https://imroc.io/static/blog/hugo/hugo-github.png", desc: "Hugo + Github Pages"}]
date: 2018-01-16T20:35:06+08:00
categories: ["hugo"]
tags: ["hugo"]
draft: false
---
## 概述
Hugo可以让你轻松生成静态网站，比如个人博客、API文档、公司主页等，你只需要提供markdown格式的文本，它就能帮你渲染成各种你想要的样式，只需要安装想要的主题，写好对应的markdown内容，就能快速编译出一个静态网站。

## 安装hugo
参考官方：http://gohugo.io/getting-started/installing/

## 创建网站
首先初始化你的网站，假如 mysite 是存放网站相关文件的目录：
``` sh
hugo new site mysite
```
这会在当前路径创建一个 mysite 目录，进入该路径：
``` sh
cd mysite
```
目录如下：

``` bash
 ▸ archetypes/
 ▸ content/
 ▸ layouts/
 ▸ static/
 ▸ themes/
   config.toml
```

`config.toml` 是网站的配置文件，包含一些基本配置和主题特有的配置。  
这几个文件夹的作用分别是：

- archetypes：包括内容类型，在创建新内容时自动生成内容的配置
- content：包括网站内容，全部使用markdown格式
- layouts：包括了网站的模版，决定内容如何呈现
- static：包括了css, js, fonts, media等，决定网站的外观
- themes：用于存放主题

在创建页面之前需要安装想要的主题，官方有收集一些：[https://themes.gohugo.io/](https://themes.gohugo.io/)  
  
在这里我用我博客的主题`xhugo`作示例，下载到themes目录：
``` bash
git clone https://github.com/imroc/xhugo.git themes/xhugo
```
在配置文件`config.toml`里加一行，配置本网站的主题：
``` toml
theme = "xhugo"
```
**注：** `config.toml` 中配置的主题名字应和主题目录名称一致

新建页面：
``` bash
hugo new posts/hello.md
```
此时会在 `content` 路径下创建文件，由于参数中还带有 posts 路径，所以最终创建的文件路径是 `content/posts/hello.md`， 每次创建的文件都根据 `archetypes/default.md` 生成的，包含一些页面的特定配置，比如标题、分类等，不同的主题还有自己支持的一些配置，需要看主题的说明。  
  
## 效果预览
写好 mardown 之后可以本地预览：
``` bash
hugo server
```
在浏览器打开 [http://localhost:1313](http://localhost:1313) 就能看到效果，并且改内容页面也能实时自动更新。  
**注：** markdown 用什么编写就取决于你自己了，我自己有时用vim，有时用 vscode（装 markdown 的插件）  

## 生成静态页面
在生成之前先确定你想将此网站发布在哪儿，在 `config.toml` 里面配置 `baseURL` 为访问此网站的基本URL路径：
``` toml
baseURL = "https://imroc.io/"
```
然后
``` bash  
hugo
```
对，你没看出，直接执行 `hugo` 就可以了，它编译并生成网站所需的静态页面和文件，输出到当前目录的 `public` 目录下，当然你也可以改变输出目的地，如：
``` bash
hugo -d docs
```
你可以将生成的目录放到 nginx 或 tomcat 等服务器下对外提供服务，不过这需要自己有服务器，接下来我教大家如何利用 Github Pages 来做到永久免费。

## Github Pages
Github Pages 是 Github 推出的一项功能，可以免费托管静态网站，将你的静态文件放在仓库里，然后在仓库的 `Settings` 里面，翻到下面的 `GitHub Pages` 部分，可以将此仓库设置为你的静态网站文件的存放仓库。  
  
其实 `Github Pages` 仓库分为两种。
- 一种是主仓库，它里面存放的文件可以直接映射到你网站的根路径，而且只能有一个仓库名固定为：`<github账号名>.github.io`，比如我的 github 账号为 `imroc`,那么我的 `Github Pages` 主仓库就为 `imroc.github.io`，这个仓库的名字其实也就是访问你网站的域名。
- 其它的仓库只能映射到网站的子路径，子路径名称和仓库名一致，比如我新建一个 `static` 仓库并设置为 `Github Pages` 仓库，那么我可以通过 `imroc.github.io/static/` 访问到里面的页面和文件

## 设置 Github Pages
静态文件存放位置有三种：  

- master 分支
- master 分支下 docs 目录 
- gh-pages 分支(前提是这个分支存在才会显示)

**注：** `Github Pages` 主仓库除外，必须是 master 分支。

一般都会先新建第一种 `Github Pages` 主仓库作为网站主要托管，根据你的账号名创建仓库，如: `imroc.github.io`， 提交静态文件后在仓库的 `Settings` 里面，翻到下面的 `Github Pages` 部分，根据自己需要设置 `Github Pages` 文件存放位置：
![github pages 设置](https://imroc.io/static/blog/hugo/github-pages-setting.png)
  
**注：** `gh-pages` 分支选项需要在此分支存在的情况下才会显示次选项  

### 源文件与编译结果在同一仓库
如果你想要将你网站的 `hugo` 源文件和编译后的静态文件目录放在一个仓库，那可以选择 `master` 下的 `docs` 目录作为 `Github Pages` 目录，编译的时候执行：
``` bash
hugo -d docs
```
建议写个脚本，每次更新内容执行下脚本网站就可以更新，如(`deploy.sh`)：
``` bash
#! /bin/bash

set -eux 

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

msg="rebuilding site `date`"

if [ $# -eq 1  ]
    then msg="$1"
fi

# Build the project. 
hugo -d docs

# Add changes to git.
git add .

# Commit changes.

git commit -m "$msg"

# Push source and build repos.
git push origin master
```
这样，每次运行：
``` bash
./deploy.sh
```
或
``` bash
./deploy.sh "本次更新描述"
```
就可以更新网站了。  
  
另外，别忘了给脚本可执行权限哦
``` bash
chmod +x deploy.sh
```

### 源文件与编译结果在不同仓库
新建一个仓库存放源文件（此仓库不需要设置 `Github Pages`)，如 `blog` 仓库，编译结果放在主仓库里，如 `imroc.github.io` 仓库。  
  
进入hugo创建的网站目录并设置 git 的远程地址：
``` bash
cd mysite
git remote add origin https://github.com/imroc/blog.git
```
将 `Github Pages` 的仓库下载到当前目录并命名 `public`：
``` bash
git clone https://github.com/imroc/imroc.github.io.git
mv imroc.github.io public
```
新增脚本 (`deploy.sh`):
``` bash
#! /bin/bash

set -eux 

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

msg="rebuilding site `date`"
if [ $# -eq 1  ]
    then msg="$1"
fi

# Build the project. 
hugo # if using a theme, replace by `hugo -t <yourtheme>`

# Go To Public folder
cd public

# Add changes to git.
git add .

# Commit changes.
git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..

git add .
git commit -m "$msg"
git push origin master
```
这样执行脚本也可以更新网站，只不过分成了两个仓库，我也是用的这种做法，因为 `Github Pages` 主仓库只允许 master 分支作为网站内容，所以源文件就存在了另一个仓库 `blog`
  
## 自定义域名
github 给我们提供了免费域名，但是我们还可以绑定自己的域名。  
  
很简单，在仓库的 `Settings` 里的 `Github Pages` 部分，有个 `Custom domain` 的设置，将其设置为你需要绑定的域名（它会新建一个 commit，就是创建一个 `CNAME` 文件，内容是你填的域名），你也可以自己手动创建一个 CNAME 文件，效果是一样的。  
  
下一步就是登录你的域名提供商的后台管理，设置DNS解析：
### 绑定根域名
如果你想要绑定自己域名的根域名（如：[imroc.io](imroc.io)），新建两个A记录，分别指向下面两个IP：
  
> 192.30.252.153  
> 192.30.252.154  

### 绑定二级域名
如果你想要绑定自己域名的二级域名（如：[blog.imroc.io](blog.imroc.io)），新建一个 `CNAME` 记录，值为你的 github 域名，如： `imroc.github.io`

## 自定义域名开启https
如果绑定了自定义域名，github pages 原则上是不能启用https的，但是可以借助 cloudflare  
  
- 在[cloudflare](https://www.cloudflare.com/)上注册并获得 `nameserver`
- 在域名注册机构的后台管理页面将  `nameservers` 设置为 `cloudflare` 上的（即让 `cloudflare` 来管理 dns） 
- 确保 `Crypto`-`SSL` 为 `Full`  

<img src="https://imroc.io/static/blog/hugo/cloudflare-crypto-full.png" />  
  
- 配置 Page Rules：加入一条规则，举例： `http://imroc.io/*` 设置为 `Always Use HTTPS`  
  
<img src="https://imroc.io/static/blog/hugo/cloudflare-always-https.png" />

> 最后等待一段时间生效
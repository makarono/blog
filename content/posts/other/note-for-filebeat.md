---
title: "filebeat源码阅读笔记"
date: 2018-01-03T15:48:33+08:00
tags: ["filebeat"]
---

# 前言
最近在阅读filebeat源码，将所学到的记录总结在本文，正在进行中，还不够完善，内容可能随时更新调整。

# 程序大致逻辑
1. 加载配置
2. `Filebeat.Run()` filebeat逻辑入口
3. `Registrar.Start()` 启动状态管理器
4. `Crawler.Start()` 启动数据爬虫，采集最新数据，封装格式并输出到指定地方


# 概念
### registrar
文件状态管理器，记录文件读取进度等信息，避免重复采集。

### crawler, prospector, harvester
`crawler` 是用来采集数据的爬虫，也是filebeat的关键，管理一个或多个 `prospector` ，一个 `prospector` 是一批文件的采集管理器，可管理某个文件或用通配符匹配的多个文件，它管理一个或多个 `harvester` ，每个 `harvester` 采集某个特定的文件。

注：  
1. `prospector` 是抽象成接口的，文件不仅仅可以是磁盘上的文件，还可以是标准输入、redis、docker。  
2. `github.com/elastic/beats/filebeat/prospector` 包提供接口和 `Register()` 函数来注册接口的实现，下面的子包就是 `prospector` 的实现。用的最多的就是下面的 `log` 包实现的 `prospector` 了，用来采集磁盘上的文件。


# Reader
`reader` 包，即 `github.com/elastic/beats/filebeat/harvester/reader` 这个包，定义了 `Reader` 接口，跟 `io.Reader` 接口不同，它需要返回 `Message` 结构体，除开所需的字节数组外还包含其它一些信息。 这个 `Reader` 用于采集数据，有多种实现，可根据需要嵌套组合着用。

### Reader的实现
`reader`包本身实现了一些公用的 `Reader` 接口实现，一些 `harvester`的实现根据自己需要会使用到，下面列几个比较关键的实现：

1. `reader.Encode`
这是一个很基础很核心的 `reader.Reader` 实现，它使用 `reader.Line` 这个辅助的结构体（封装 `io.Reader`，保证每次读一行），然后将每次读取的数据封装成 `reader.Message` 返回以实现 `reader.Reader` 接口。

2. `reader.JSON`
将现成的 `reader.Reader` 读取的数据根据配置转换成json格式的数据。

3. `log` 包的 `Reader` 实现
`log` 包中创建 `reader.Reader` 时先创建 `log.Log`（封装日志文件读取，实现 `io.Reader` 接口）然后调用 `reader.NewEncode()` 将创建好的 `log.Log` 实例传入，返回 `reader.Reader`；不过并没完，还会根据配置用其它 `reader.Reader` 再进行一次封装，比如 `reader.NewJSON()` 返回 `reader.JSON`，即将采集到的数据转换成json格式。

# 包结构
```
github.com
└── elastic
    └── beats # elastic旗下beats系列产品
        ├── libbeats # elastic旗下beats系列产品共用库
        └── filebeats # filebeats程序
            ├── crawler # 定义Crawler结构体，管理所有prospector
            ├── harvester # 定义Harvester接口
            │   └── reader # 定义Reader接口，采集数据的关键，并包含一些公用的Reader实现
            ├── prospector # 定义Prospector结构体及其用到的Prospectorer接口
            │   ├── log # 日志文件的Prospectorer实现
            │   └── stdin # 标准输出的Prospectorer实现
            └── registrar # 定义Registrar结构体，包含Registrar的所有逻辑

```

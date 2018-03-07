---
title: "go的channel是如何设计的"
date: 2018-01-24T08:57:24+08:00
subtitle: ""
categories: "golang"
tags: [ "golang" ]
---

## 概述
大部分情况下我们把 go 的 channel 当成黑盒工具来用，不知道它的原理，这是 OK 的，但是在一些高级的开发中，我们还是需要了解下它的底层实现原理。  
  
回顾一下 channel 的用法：
``` go
ch := make(chan int, 100) // 创建 channel
ch <- 1 // 发数据
data := <- ch // 取数据
```

在 go 的 runtime 源码里，channel 是一个名为 `hchan` 的结构体，make 返回其指针，所以多个 goroutine 用的 ch 变量指向同一个 `hchan` 的结构体，那么这个结构体里面需要哪些东西？下面我们结合源码片段来分析下。

## 缓冲区
channel 创建的时候可以设置缓冲区大小：
``` go
ch := make(chan int, 100) // 创建 channel
```
首先它需要一个缓冲区，存数据，make的时候缓冲区大小固定，就用数组做环形队列来存，发送和接收数据都有 index 标记，这样才知道下一个 pop 的数据是哪一个，最新 push 的数据应该放在哪儿。
``` go
type hchan struct {
    ...
    buf      unsafe.Pointer // 指向一个数组，结合下面的 index 实现环形队列
    ... 
    sendx    uint   // 发送 index
    recvx    uint   // 接收 index
    ...
}
```
源码在 [这里](https://github.com/golang/go/blob/master/src/runtime/chan.go#L31)


## 锁
为什么需要锁？ 一是发送和接收数据的时候要保证原子性，二是如果缓冲区满了或者没有缓冲区，并且没有其它 goroutine 接收数据，这时发送数据的 goroutine 就会挂起（睡眠），进入等待状态，等待 channel 可以再次被发送数据。同理，在没有
``` go
ch <- 1 // 发数据
```
要想 goroutine 挂起，就需要给 channel 一把锁，这锁并不是直接用标准库的 `sync.Mutex`，而是用的更底层的实现:
``` go
type hchan struct {
	// lock protects all fields in hchan, as well as several
	// fields in sudogs blocked on this channel.
	//
	// Do not change another G's status while holding this lock
	// (in particular, do not ready a G), as this can deadlock
	// with stack shrinking.
	lock mutex
}
```
不同操作系统不一样，不过大致原理都是通过**信号量**来实现的，关于信号量的学习可以参考麦子学院视频：[linux内核同步和互斥（一）：信号量](http://www.maiziedu.com/course/368-3774/)

go runtime 中的锁实现总体分两类：
- [lock_futex.go](https://github.com/golang/go/blob/master/src/runtime/lock_futex.go)

> 适用于 dragonfly freebsd linux

- [lock_sema.go](https://github.com/golang/go/blob/master/src/runtime/lock_sema.go)

> 适用于 darwin nacl netbsd openbsd plan9 solaris windows

runtime 源码将锁实现分为这两大类，它们有不同的依赖函数，而这些函数的实现根据操作系统的不同也是不一样的，要找对应函数实现可以根据源文件名后面系统标识来区分，比如： [`os_freebsd.go`](https://github.com/golang/go/blob/master/src/runtime/os_freebsd.go)  

#### 等待状态

其实当 goroutine 遇到锁进入等待状态，也并不会占用cpu时间，为什么？不如我们来探究一下 goroutine 如何做到如此轻量、高性能的。  
  
goroutine 并非直接由操作系统的 OS 线程来调度的，而是在 go 的 runtime ，go 程序进程可能有多个 OS 线程，它的调度器来决定哪个 goroutine 运行在哪个 OS 线程中，一个 OS 线程可以运行多个 goroutine 。runtime 还维护了所有 goroutine 及其上下文，如果某个 goroutine 处于等待(挂起)状态，它可以将此 goroutine 从 OS 线程中移除（不占用cpu时间片），等状态恢复再放到某个 OS 线程中运行。  
   
这样，goroutine 为何如此轻量高性能也就有了答案，它不是有 OS 调度的线程，而是 go 的 runtime 来调度的，也就是说，goroutine所以让 goroutine 很轻量，可以创建很多 goroutine ，被阻塞时也并不会占用 cpu 时间片。这样，goroutine 极大的提高了性能。

关于信号量的学习可以参考麦子学院视频：[linux内核同步和互斥（一）：信号量](http://www.maiziedu.com/course/368-3774/)

#### 拓展：标准库 sync.Mutex 的实现
标准库的锁并非完全用信号量实现，还使用了自旋。锁通常有两种实现，信号量和自旋。 
   
linux 内核本身有信号量相关的系统调用API，比如 down(sem) 用于获取信号量，将值减1，为负会将调用者挂起(睡眠)，直到信号量为非负才继续运行，用 up(sem) 可将信号量加1，而用信号量实现的锁实际上就是初始值置为1的信号量，因为锁本身就是为了只让一个线程对资源进行读写。  
  
自旋锁相当于是循环等待，比较适合锁保持时间较短的情况，长时间的话会占用很多cpu资源。  
  
信号量会使线程睡眠，有切换代价，而自旋锁不会让出cpu，属于忙等待，如果等待时间短，可以很快恢复。  
  
了解了下 go runtime 的源码，它的锁是结合了信号量和自旋两种方式自己实现的一套逻辑，有冲突时先尝试自旋，如果超时再用信号量让 goroutine 进入等待状态。因为大多时候要锁的代码片段都比较短，自旋一下就可以了，很快又可以恢复过来，提升了性能。

参考：[Golang 互斥锁内部实现](https://zhuanlan.zhihu.com/p/27608263)
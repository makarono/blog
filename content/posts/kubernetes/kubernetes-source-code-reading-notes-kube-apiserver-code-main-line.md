---
title: "kubernetes源码阅读笔记：理清 kube-apiserver 的源码主线"
bigimg: [{src: "https://res.cloudinary.com/imroc/image/upload/v1520826775/blog/k8s/Banner-Hacker.png", desc: "hacker"}]
date: 2018-03-12T11:47:19+08:00
subtitle: ""
categories: ["kubernetes"]
tags: ["kubernetes" ]
---

## 前言
我最近开始研究 kubernetes 源码，希望将阅读笔记记录下来，分享阅读思路和心得，更好的理解 kubernetes，这是第一篇，从 `kube-apiserver` 开始。

## 开始
k8s各组件main包在cmd目录下，即各个程序的入口处，来看看 `kube-apiserver` 的源码

**注：** 三点代表省略的代码，只关注主要的代码，让思路更清晰
`cmd/kube-apiserver/apiserver.go`
``` go
func main() {
	...

	command := app.NewAPIServerCommand()
	
	...

	if err := command.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

```
各组件程序都是用 `cobra` 来管理、解析命令行参数的，main 包下面还有 app 包，app 包才是包含创建 cobra 命令逻辑的地方，所以其实 main 包的逻辑特别简单，主要是调用执行函数就可以了。那么问题来了，为什么要这样设计？答案很简单，有没有注意到还有个 hyperkube 程序？它把很多组件的功能都综合在一起了，安装的时候我们就不需要准备那么多程序，比如执行 `hyperkube apiserver` 和直接执行`kube-apiserver` 效果是一样的。由于各组件程序把创建 cobra 命令的逻辑都提取到下面的 app 包了，hyperkube 就只可以直接调用这些，所以 hyperkube 的 main 包就仅仅需要一个 main 文件就可以了，各组件程序代码有更新，hyperkube 重新编译也能获取更新，所以提取 app 包是一种解耦的方法。  
  
`app.NewAPIServerCommand()` 返回 `*cobra.Command`,执行 `command.Execute()` 最终会调用 `*cobra.Command` 的 Run 字段的函数，我们来看看 `app.NewAPIServerCommand()` 是如何构造 `*cobra.Command` 的。
``` go
func NewAPIServerCommand() *cobra.Command {
	s := options.NewServerRunOptions()
	cmd := &cobra.Command{
		...
		Run: func(cmd *cobra.Command, args []string) {
			...
			stopCh := server.SetupSignalHandler()
			if err := Run(s, stopCh); err != nil {
				fmt.Fprintf(os.Stderr, "%v\n", err)
				os.Exit(1)
			}
		},
	}
	...

	return cmd
}
```
Run 字段是一个匿名函数，里面又调用了本包的 Run 函数
``` go
// Run runs the specified APIServer.  This should never exit.
func Run(runOptions *options.ServerRunOptions, stopCh <-chan struct{}) error {
	...

	server, err := CreateServerChain(runOptions, stopCh)
	if err != nil {
		return err
	}

	return server.PrepareRun().Run(stopCh)
}
```
这里面创建了一个 `server` ，经过 `PrepareRun()` 返回 `preparedGenericAPIServer` 并最终调用其方法 `Run()`
``` go
// Run spawns the secure http server. It only returns if stopCh is closed
// or the secure port cannot be listened on initially.
func (s preparedGenericAPIServer) Run(stopCh <-chan struct{}) error {
	...

	err := s.NonBlockingRun(stopCh)
	if err != nil {
		return err
	}

	<-stopCh

	...

	return nil
}
```
我们看到它又调用了 `s.NonBlockingRun()`，看方法名就知道是非阻塞运行即里面会创建新的 goroutine 最终运行 http 服务器，提供 http 接口给其它 kubernetes 组件调用，也是 kubernetes 集群控制的核心机制。然后到 `<-stopCh` 这里阻塞，如果这个 channel 被 close，这里就会停止阻塞并处理关闭逻辑最后函数执行结束，`s.NonBlockingRun()`这个函数也传入了 `stopCh`，同样也是出于类似的考虑，让程序优雅关闭，`stopCh` 最初是 `NewAPIServerCommand()` 中创建的：
``` go
stopCh := server.SetupSignalHandler()
```
很容易看出来这个 channel 跟系统信号量绑定了，即 `Ctrl+c` 或 `kill` 通知程序关闭的时候会 close 这个 channel ，然后下面的 `<-stopCh` 
``` go
// SetupSignalHandler registered for SIGTERM and SIGINT. A stop channel is returned
// which is closed on one of these signals. If a second signal is caught, the program
// is terminated with exit code 1.
func SetupSignalHandler() (stopCh <-chan struct{}) {
	close(onlyOneSignalHandler) // panics when called twice

	stop := make(chan struct{})
	c := make(chan os.Signal, 2)
	signal.Notify(c, shutdownSignals...)
	go func() {
		<-c
		close(stop)
		<-c
		os.Exit(1) // second signal. Exit directly.
	}()

	return stop
}
```
我们再来看看 `NonBlockingRun()` 这个函数的实现
``` go
// NonBlockingRun spawns the secure http server. An error is
// returned if the secure port cannot be listened on.
func (s preparedGenericAPIServer) NonBlockingRun(stopCh <-chan struct{}) error {
	...

	// Use an internal stop channel to allow cleanup of the listeners on error.
	internalStopCh := make(chan struct{})

	if s.SecureServingInfo != nil && s.Handler != nil {
		if err := s.SecureServingInfo.Serve(s.Handler, s.ShutdownTimeout, internalStopCh); err != nil {
			close(internalStopCh)
			return err
		}
	}

	...

	return nil
}
```
可以看到又调用了 `s.SecureServingInfo.Serve()` 来启动 http 服务器，继续深入进去
``` go
// serveSecurely runs the secure http server. It fails only if certificates cannot
// be loaded or the initial listen call fails. The actual server loop (stoppable by closing
// stopCh) runs in a go routine, i.e. serveSecurely does not block.
func (s *SecureServingInfo) Serve(handler http.Handler, shutdownTimeout time.Duration, stopCh <-chan struct{}) error {
	...

	secureServer := &http.Server{
		Addr:           s.Listener.Addr().String(),
		Handler:        handler,
		...
	}

	...
	
	return RunServer(secureServer, s.Listener, shutdownTimeout, stopCh)
}
```
它创建了 `http.Server`，里面包含处理 http 请求的 handler，又调用了 `RunServer()`
``` bash
// RunServer listens on the given port if listener is not given,
// then spawns a go-routine continuously serving
// until the stopCh is closed. This function does not block.
// TODO: make private when insecure serving is gone from the kube-apiserver
func RunServer(
	server *http.Server,
	ln net.Listener,
	shutDownTimeout time.Duration,
	stopCh <-chan struct{},
) error {
	...

	// Shutdown server gracefully.
	go func() {
		<-stopCh
		ctx, cancel := context.WithTimeout(context.Background(), shutDownTimeout)
		server.Shutdown(ctx)
		cancel()
	}()

	go func() {
		...

		err := server.Serve(listener)

		msg := fmt.Sprintf("Stopped listening on %s", ln.Addr().String())
		select {
		case <-stopCh:
			glog.Info(msg)
		default:
			panic(fmt.Sprintf("%s due to error: %v", msg, err))
		}
	}()

	return nil
}
```
最终看到在后面那个新的 goroutine 中，调用了 `server.Serve()` 来启动 http 服务器，正常启动的情况下会一直阻塞在这里。

## 总结
至此，我们初步把 `kube-apiserver` 源码的主线理清楚了，具体还有很多细节我们后面再继续深入。要理清思路我们就需要尽量先屏蔽细节，寻找我们想知道的逻辑路线。

---
layout: post
title: launchctl使用
---

{% highlight bash %}
 load LaunchDaemons下的plist名字(加载plist相应的程序.每次launchd启动后会自动遍历改目录并加载.)
 unload  LaunchDaemons下的plist名字(卸载plist相应的程序.不过只要在LaunchdDaemons目录下.下次还是会自动加载)
 list (显示已加载的Daemons程序)
 start/stop LaunchDaemons下的plist名字(开始/停止程序)
 submit (提交一段命令行去执行)
 remove LaunchDaemons下的plist名字(和unload一样的效果.但是不可以被load再次加载.不过下次开机启动launchd时还是会被加载的).
更多的还是自己去看help吧
{% endhighlight %}

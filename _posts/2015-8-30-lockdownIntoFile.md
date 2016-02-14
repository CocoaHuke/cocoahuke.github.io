---
layout: post
title: Lockdown进入iOS
---

{% highlight bash %}
通过lockdown进入iOS设备文件系统的两个入口点:
1.通过afcd可以访问/var/mobile/Media/下的内容 
2.通过挂接Developer镜像到/Developer可以添加Daemon,framework,bin等内容(但是挂接的镜像需要签名).
当然从桌面端的USBMuxd可以访问设备的lockdownd服务.lockdownd可以启动许多服务.
例如afc,backup,mount这些都是又lockdownd启动的.
lockdownd存在于/usr/libexec/lockdownd,就是USBMuxd于设备连接的一个进程,由lockdown启动其他服务.
启动的服务列表(相关服务的bundleID和实际执行文件)存在于/System/Library/Lockdown/Service.plist.
但是在iOS8这个文件没了,启动的服务列表被嵌入了lockdownd二进制里.
可以通过strings命令工具或者反编译提取出来.
使用lockdown启动服务用MobileDevice.framework私有框架或者libimobiledevice访问
{% endhighlight %}

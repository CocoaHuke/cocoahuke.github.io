---
layout: post
title: Developer镜像挂接服务
---

{% highlight bash %}
com.apple.mobile.mobile_image_mounter 实现在/usr/libexec/mobile_storage_proxy
通过libimobiledevice启动改服务后.
桌面端的Developer镜像会被上传设备的/var/run/mobile_image_mounter/下面,然后会进行验证签名.
如果签名通过就会尝试挂接.最后删除/var/run/mobile_image_mounter目录下的临时镜像.
因为过程很快,自己可以写一个脚本进行验证:
#!/bin/sh
while :
do
 ls /var/run/mobile_image_mounter/
done
如果镜像上传后在一个特定的时间替换该镜像(在效验完签名后,还没有来得及上传时替换/var/run/mobile_image_mounter下的这个镜像).
然后替换后的镜像都会被代替挂接道/Developer目录下.
这样可以启动些自定义的服务.因为Developer镜像可以自定义framework,bin,Daemon(设置些plist).
{% endhighlight %}

{% highlight bash %}
Taij的做法是通过afc漏洞用一个指向/var/mobile/Media(就是指向可以通过afc读写的文件夹)下的符号链接替换/var/run/mobile_image_mounter.
然后mobile_storage_proxy在上传镜像时就会上传到/var/mobile/Media下,也就是可以读写的区域,这样就可以通过afc替换那个镜像.
{% endhighlight %}

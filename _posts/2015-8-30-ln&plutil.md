---
layout: post
title: ln plutil命令
---

{% highlight bash %}
实用的shell命令:
ln 创建符号链接.
ln -f sys my //这样可以使my文件硬链接到sys目标文件.两者的修改都会同步.就是无论改哪个另个都会变化.但是需要在同一个文件系统中,不支持文件夹
ln -s sys my //这样可以使my文件(文件夹)软链接到sys目标文件(文件夹),就是符号链接,这样比较常用.
plutil 使plist文件在二进制和XML之间转换
plutil -convert xml1 -o xml.plist binary.plist //将二进制转为xml
plutil -convert binary1 -o binary.plist xml.plist //将xml转为二进制
{% endhighlight %}

---
layout: post
title: LC_DATA_IN_CODE
---

常用魔数

{% highlight bash %}

使用nm对一些mach-o文件查看符号时有时会报错.提示LC_DATA_IN_CODE或者有时好像为LC_CODE_SIGNATURE吧的dataoff超出文件范围.比如像这样:
(dataoff field of LC_DATA_IN_CODE command 15 extends past the end of the file);
这个时候便无法用nm查看符号,其实呢解决办法也很简单.打开hopper.里面可以看到LC_DATA_IN_CODE的加载位置在哪.查看hex值位置,并UltraEdit都修改为0就行了

{% endhighlight %}

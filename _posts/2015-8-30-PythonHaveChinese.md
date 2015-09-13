---
layout: post
title: Python的一个注意点
---

我把这篇放在blog的原因是lldb会用到python扩展.很实用.当时好坑.就因为我加了中文注释.....

import 和 import from 引入其他文件
代码中不能有中文,注释也不能有,不然就报错,有时甚至不知道哪里出错了.
{% highlight bash %}
在开头加上#coding=UTF-8
{% endhighlight %}
就可以写中文注释了.

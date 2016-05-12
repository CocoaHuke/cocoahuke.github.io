---
layout: post
title: Xcode7中对AppleWatch使用IOKit
---
   
Xcode7中对AppleWatch使用IOKit. 
IOKit for AppleWatch in Xcode7 
 
直接修改SDK对Xcode依然有效,但有些变化,不止是IOKit,其他的框架都适用. 
 
比如需要添加IOKit,在WatchOS的sdk中找不到IOKit.framework,这里顺便说下,watch架构的框架macho文件,dylib库在~/Library/Developer/Xcode/watchOS DeviceSupport下面,内部有函数实现,但却是错误格式的macho.我尝试过拷贝IOKit.tbd到watchos sdk,但并不管用.  
  
先将IOKit.framework的h文件从mac sdk中拷贝过来,处理完头文件的一些变化后(我拷贝已经处理完的头文件和macho文件的IOKit在ios sdk里),在watchos中使用iokit,头文件没问题,然后会报错找不到函数,会报错IOKit架构不适用于watchos(armv7k),这个时候直接修改IOKit二进制的machoH就行.  
 
Watchos架构的machoH
{% highlight bash %}
cputype is 0xc
cpusubtype is 0xc
filetype is 0x6
{% endhighlight %}
 
ios架构的machoH
{% highlight bash %}
cputype is 0xc
cpusubtype is 0x9
filetype is 0x9
{% endhighlight %}
 
然后还要修改下面的 
LC_VERSION_MIN_MACOSX macos的macho 
LC_VERSION_MIN_IPHONEOS ios的macho  
 
改成 
LC_VERSION_MIN_WATCHOS 注意后面是有数字的,也要改 
比如LC_VERSION_MIN_WATCHOS 2.0.0 具体参考watchos架构的macho文件,然后xcode就可以成功编译了.  

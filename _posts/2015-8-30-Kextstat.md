---
layout: post
title: 编写kextstat
---



编写kextstat,kextstat在mac平台是自带的,可以显示所有已加载到内核空间的内核扩展和驱动的信息.它所需要的函数OSKextCopyLoadedKextInfo(CFArrayRef,CFArrayRef).当然直接用dlfcn.h里的函数加载也可以.这个函数所在的头文件在Apple开源官网可以下载到.叫IOKitUser.就是用户空间那个IOKit.framework的开源实现.

就在kext.subproj/OSKext.h,里面有很多有用的C函数.可以自己去尝试.当然就包括OSKextCopyLoadedKextInfo.
我的做法直接把OSKext.h加到xcode的mac的sdk里去.以后用着方便,借xcode自动补全函数名

{% highlight bash %}
把OSKext.h复制到/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/ 下
这样项目中就可以#include<IOKit/OSKext.h>
然后会报错.一些#include <system/libkern/OSKextLib.h>这样的都改成#include <libkern/OSKextLib.h>
这里sdk里的libkern下OSKextLib.h会报错.这时chmod -R 777.把OSKextLib.h的一句头文件改了

OSKextLib:#include <system/libkern/OSReturn.h>改成#include <libkern/OSReturn.h>
{% endhighlight %}
{% highlight bash %}
然后最后差一个文件,就是OSKext.h引用的#include <libkern/OSKextLibPrivate.h>.这个文件里包含了许多健,在开源xnu下可以找到找到后.里面一句#include <system/mach/kmod.h>改成#include <mach/kmod.h>
弄到libkern(usr/include/libkern)目录下.
然后IOKit/OSKext.h就可以用了.
{% endhighlight %}
比如kextstat的实现
{% highlight bash %}
NSDictionary *dic = (__bridge NSDictionary*)OSKextCopyLoadedKextInfo(NULL,NULL);
NSLog(@"%@",dic);
{% endhighlight %}

系统自带的kextstat的参数比较复杂.有时不太方便.比如自己想过滤些信息.那么就自己实现一个吧.我写过iOS上的kextstat实现.还能显示内核相关信息(Index=0).项目名ios-kext_stat在mac上重新编译一样好用.

那么其他函数的功能就自己去尝试吧.当然,ios的sdk完全也可以这样做.自己修改吧

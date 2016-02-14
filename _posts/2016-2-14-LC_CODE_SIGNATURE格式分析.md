---
layout: post
title: LC_CODE_SIGNATURE格式分析
---
通常.LC_CODE_SIGNATURE为最后一个seg在macho中.

LC_CODE_SIGNATURE开头4字节为特点的数字
关于签名标示的数字定义在codesign.h中.(CSMAGIC开头)
程序的嵌入式签名标示通常为为0xfade0cc0
然后接着后面的顺序为:
{% highlight bash %}
1.全部Blob的总大小.
2.Blob的数量
3.第一个Blob的type(定义在codesign.h中,CSSLOT_开头,第一个Blob为0,因为CSSLOT_CODEDIRECTORY)
4.第一个Blob开头的偏移位置相对于LC_CODE_SIGNATURE开始的位置,Blob开头的四个字节也是特定的数字,定义在codesign.h
5.第二个Blob的type
6.第二个Blob开头的偏移位置相对于LC_CODE_SIGNATURE开始的位置
7.第三个Blob的type
8.第三个Blob开头的偏移位置相对于LC_CODE_SIGNATURE开始的位置
9.第四个Blob的type
10.第四个Blob开头的偏移位置相对于LC_CODE_SIGNATURE开始的位置
{% endhighlight %}
以此类推...
{% highlight bash %}
每个Blob开头也是为特定的4字节.
这里举例子,一个下载自Mac AppStore的应用.
顺序:
CSMAGIC_EMBEDDED_SIGNATURE //LC_CODE_SIGNATURE开头标示符

CSMAGIC_CODEDIRECTORY //通常为Blob0
CSMAGIC_REQUIREMENTS //通常为Blob1
CSMAGIC_REQUIREMENT //通常为Blob2

CSMAGIC_EMBEDDED_ENTITLEMENTS //授权plist的开头

CSMAGIC_BLOBWRAPPER //CMS签名,就是有签名机构信息的那段
{% endhighlight %}
不同种类的签名会有不同的格式.其他请自行参考codesign.h
---
layout: post
title: iokit底层函数的MIG调用
---
  
得到iokit底层函数的MIG调用.
这篇介绍的是,需要直接调用io_connect_method等iokit底层函数,然而找不到方法去直接调用
这里用io_connect_method为例子.
IOConnectCallMethod这样的函数是更为底层的io_connect_method的封装,接着就是mach_msg的封装,这里就不多说了.  
一开始在IOKit.framework通过nm可以看到io_connect_method等函数符号,想当然的就用dlsym去获取函数地址,但是dlsym不管用,网上查了下,nm导出的符号为t io_connect_method,t/T意都为__Text seg内的函数符号,大写T是最常见的,小写t意思为本地符号,即只给这个框架内使用的,外部用dlsym等dyld函数是看不到的,当然,因为可以获取到IOConnectCallMethod的函数地址,然后可以用反编译框架去读取汇编,再过滤指令,分析下规律,得到call，bl处的跳转地址就是被封装的底层iokit函数了,但这样过于麻烦.   
或者自己去重写函数,ida里还是蛮清楚的,这个不难,但同样麻烦,这些函数里面自己有对返回值的判断,各个函数有不同的结构体等. 
  
在finder中搜索io_connect_method,出来的结果除了IOKitLib.c还有device.defs这个东西,btw,device.defs在xnu开源代码的/osfmk/device/下面,defs文件是可以mig(Mach Interface Generator)命令生成写好的mach_msg函数调用的,可以试试mach_host.defs之类的,生成的文件非常清楚,稍加改动就可以自己用.
  
mig会生成2对文件,c和h文件,一对是在用户态mach_msg的调用函数,我们需要的就是这个,另一个是在内核态的实现.
但mig device.defs只会生成个几乎空的文件,除了自动生成的宏其他就没了,明明device.defs里面有完整的函数符号列表的.额.这里我认为是因为缺少其他文件和MIG参数吗?因为xnu的device.defs目录下其他几对文件里面定义了些东西.希望知道的朋友回复下,谢谢.  
  
回到前面finder里搜索io_connect_method,如果之前编译过xnu内核的朋友,会出现device_server.c/device_server.h这对文件,这才是正常device.defs的导出文件.但只有内核的实现端的.. 在这里我参考device_server.c的实现是可以自己重写函数的,因为每个函数所用到的结构体这个文件里都有. 
 
然后继续追寻到xnu的device.defs目录下的Makefile.然后里面有 
 
{% highlight bash %}
${DEVICE_FILES}: device.defs
	@echo MIG $@
	$(_v)${MIG} ${MIGFLAGS} ${MIGKSFLAGS}	\
	-header /dev/null			\
	-user /dev/null				\
	-sheader device_server.h		\
	-server device_server.c			\
	$<
{% endhighlight %}

看到那个/dev/null?! 在这里有正确的参数对MIG,然后这里只要把/dev/null去掉

{% highlight bash %}
${DEVICE_FILES}: device.defs
	@echo MIG $@
	$(_v)${MIG} ${MIGFLAGS} ${MIGKSFLAGS}	\
	-header device_user.h			\
	-user device_user.c	                \
	-sheader device_server.h		\
	-server device_server.c			\
	$<
{% endhighlight %}

这样就行了,重写编译一遍内核,中途报错没事,只要在在编译的时候可以看到MIG device_server.c这样的输出,编译就可以停了.然后再device_server.c/device_server.h目录下就可以看到device_user.c/device_user.h,里面就是需要的底层iokit函数对mach_msg封装的实现.然后拖进项目,稍微改下,就可以直接使用了 

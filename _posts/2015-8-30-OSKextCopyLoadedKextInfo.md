---
layout: post
title: OSKextCopyLoadedKextInfo
---

可以用dlfcn使用IOKit里的函数OSKextCopyLoadedKextInfo获得内核扩展kext相关信息.这些信息可以写出kextstat命令.并运行在iOS上.可以比kextstat得到更多信息.
因为该函数会返回一个字典.字典的keys就是各个内核扩展的bundleIdentifier.而values就是各个内核扩展信息的又一个字典.下面是这个包含该kext信息的字典的一些key.
注意下.这里的加载地址并不是真正在内存中的地址.需要加上偏移地址.而偏移地址可以通过内核的偏移(内核的内存地址可以通过查找特定大小的内存区域得到)来算各个内核扩展的真正位置.下面也给出了大小.所以可以利用这个在0号进程里得到很多内核扩展的代码.
```
OSBundleLoadTag kext的加载序数.
OSBundleRetainCount kext的被引用的次数.如果不为0,这个kext不能被卸载.
OSBundleLoadAddress 加载在内核空间的地址.注意需要偏移
OSBundleLoadSize 加载的大小.
OSBundleWiredSize 占有内核空间的大小.
CFBundleIdentifier CFBundle名.
CFBundleVersion Bundle的版本.
OSBundleMachOHeaders machO的Headers的十六进制.可以用来在内存中查找.
OSBundleUUID Bundle的UUID.
```



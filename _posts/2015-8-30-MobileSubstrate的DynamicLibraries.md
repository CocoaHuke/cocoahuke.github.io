---
layout: post
title: MobileSubstrate的DynamicLibraries.
---

{% highlight bash %}
用bundleID(比如app)过滤要加载的程序:
 <dict>
   <key>Filter</key>
   <dict>
     <key>Bundles</key>
     <array>
       <string>com.apple.springboard</string>
       <string>com.xxx.xxxx</string> //这里添加需要加载动态库的程序bundleID
     </array>
   </dict>
 </dict>
用程序名(比如适用于系统中的一些后台进程)过滤要加载的程序:
 <dict>
   <key>Filter</key>
   <dict>
     <key>Executables</key>
     <array>
       <string>installd</string>
       <string>xxxxx</string> //这里添加要加载动态哭的程序名
     </array>
   </dict>
 </dict>
{% endhighlight %}

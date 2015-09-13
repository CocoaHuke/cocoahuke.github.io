---
layout: post
title: getopt处理参数
---

{% highlight bash %}
getopt(main函数参数argc,main函数参数argv,定义参数的字符串);
定义参数的字符串:比如你有两个参数,-a和-i,-i参数后需要跟着一个参数,那么可以写成”ai:”,总之需要后跟参数的程序参数加冒号:
不想要错误参数提示,就把opterr设为0.
例子:
int ret;
if(argc==1)
    usage();//这是当没有参数的时候;
while((ret = getopt(argc,argv,"ai:"))!=-1){
        switch (ret) {
            case 'a':
                //当有参数-a的时候
                break;
            case 'i':
                //当有参数-i的时候.这是.optarg就是-i后跟的参数字符串.
                break;
            default:usage();
                break;
        }
     }
{% endhighlight %}

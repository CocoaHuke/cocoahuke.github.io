---
layout: post
title: deb包常用脚本
---

postinst:当deb包正常拷贝到文件系统后执行.负责安装完后的配置工作.

prerm:当deb删除关联文件前执行.负责停止与deb包内软件产生的程序等操作.

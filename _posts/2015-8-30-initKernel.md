---
layout: post
title: 内核初始化
---

这里的书指《深入解析Mac OS X & iOS 操作系统》

内核初始化大概流程图:(详见书282页,PDF 305页左右)

EFI/iBoot调用----->_pstart(_vstart)/start----->i386_init/arm_init----->kernel_bootstrap----->machine_startup----->kernel_bootstrap_thread(各种负责事务管理的线程)----->bsd_init(BSD系统线程)----->vm_pageout(PID1(launchd))

kernel_bootstrap函数:(详见书286页,PDF 310页左右)
 这个函数负责大量Mach底层的初始化工作,不会返回.最后会加载系统的第一个活动线程kernel_bootstrap_thread

kernel_bootstrap_thread函数:(详见书289页,PDF 314页左右)
 这个函数里调用了bsd_init(初始化BSD子系统,执行launchd),最后调用vm_pageout()

bsd_init函数:(详见书291页,PDF 316页左右)
 这个函数初始化BSD子系统.详见书.

介绍Mach线程(thread):(详见书351页,PDF 375页).struct thread定义在/osfmk/kern/thread.h中.
介绍Mach任务(task):(详见书356页,PDF 380页),struct task定义在/osfmk/kern/task.h中.

任务和线程相关的c函数:(详见书360页,PDF 384页).

AST常量:(详见书383页,PDF 407页),比如AST_BSD.
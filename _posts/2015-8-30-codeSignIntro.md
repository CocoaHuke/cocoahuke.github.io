---
layout: post
title: 启动时的代码签名(code-sign)
---

{% highlight bash %}
////kern_exec.c文件
int execve(proc_t p, struct execve_args *uap, int32_t *retval)
//执行文件时,会调用execve函数.
 
err = __mac_execve(p, &muap, retval);
//里面主要会调用__mac_execve函数.
 
int __mac_execve(proc_t p, struct __mac_execve_args *uap, int32_t *retval)
//这里我有点迷惑,按常理来说,在__mac_execve函数里应该会调用exec_mach_imgact函数.
可是我并没有发现调用的代码,也可能是我不小心删了代码,不过不用在意.这个函数还是比较表层的,总之会调用exec_mach_imgact函数.
 
static int exec_mach_imgact(struct image_params *imgp)
 
//在exec_mach_imgact函数里实现主要功能调用的函数就是load_machfile
lret = load_machfile(imgp, mach_header, thread, map, &load_result);
 
 
//mach_loader.c文件
load_return_t load_machfile(
              struct image_params	*imgp,
              struct mach_header	*header,
              thread_t 		thread,
              vm_map_t 		new_map,
              load_result_t		*result
              )
//在load_machfile函数里会调用parse_machfile函数,并传入参数
lret = parse_machfile(vp, map, thread, header, file_offset, macho_size,
                      0, (int64_t)aslr_offset, (int64_t)dyld_aslr_offset, result);
//在parse_machfile函数中,会将执行文件的有关信息传入这个函数
//先把文件头读取到header结构体变量中(header为mach_header类型(结构体))
//parse_machfile函数里的变量ncmds.记录执行文件头里面的指令数量.
//parse_machfile函数里会用ncmds循环(ncmds为uint32_t)
//循环里调用switch(lcp->cmd).cmd是lcp结构体里的.存着真正表示指令的内容
 
//在switch里的case LC_CODE_SIGNATURE:里会调用load_code_signature函数,传入有关参数
case LC_CODE_SIGNATURE:
/* CODE SIGNING */
if (pass != 1)
break;
/* pager -> uip ->
 load signatures & store in uip
 set VM object "signed_pages"
 */
ret = load_code_signature(
                          (struct linkedit_data_command *) lcp,
                          vp,
                          file_offset,
                          macho_size,
                          header->cputype,
                          result);
if (ret != LOAD_SUCCESS) {
    printf("proc %d: load code signature error %d "
           "for file \"%s\"\n",
           p->p_pid, ret, vp->v_name);
    ret = LOAD_SUCCESS; /* ignore error */
} else {
    got_code_signatures = TRUE;
}
break;
 
//load_code_signature里实际检查的操作是调用ubc_cs_blob_add,并把有关参数传入(详细部分自己看c文件)
ubc_cs_blob_add(vp,cputype,macho_offset,addr,lcp->datasize)
//传入的参数,部分参数可能已经在函数内改动过,不要直接对照着上面的参数
 
//ubc_subr.c文件
#if CONFIG_MACF
error = mac_vnode_check_signature(vp, base_offset, blob->csb_sha1, (const void*)cd, size, &is_platform_binary);
if (error) {
    if (cs_debug)
        printf("check_signature[pid: %d], error = %d\n", current_proc()->p_pid, error);
        goto out;
}
//ubc_cs_blob_add函数内实际检查部分在调用mac_vnode_check_signature函数,会传入有关参数
 
//mac_vfs.c文件
//在mac_vnode_check_signature函数内调用MAC_CHECK宏,并传入有关参数
MAC_CHECK(vnode_check_signature, vp, vp->v_label, macho_offset, sha1,
signature, size, is_platform_binary);
 
//mac_internal.h文件
//这里定义了MAC_CHECK宏
#define	MAC_CHECK(check, args...) do {					\
struct mac_policy_conf *mpc;					\
u_int i;                                               		\
\
error = 0;							\
for (i = 0; i < mac_policy_list.staticmax; i++) {		\
mpc = mac_policy_list.entries[i].mpc;              	\
if (mpc == NULL)                                	\
continue;                               	\
\
if (mpc->mpc_ops->mpo_ ## check != NULL)		\
error = mac_error_select(      			\
mpc->mpc_ops->mpo_ ## check (args),		\
error);					\
}								\
if (mac_policy_list_conditional_busy() != 0) {			\
for (; i <= mac_policy_list.maxindex; i++) {		\
mpc = mac_policy_list.entries[i].mpc;		\
if (mpc == NULL)                                \
continue;                               \
\
if (mpc->mpc_ops->mpo_ ## check != NULL)	\
error = mac_error_select(      		\
mpc->mpc_ops->mpo_ ## check (args),	\
error);				\
}							\
mac_policy_list_unbusy();				\
}								\
} while (0)
//MAC_CHECK宏的工作方法很好理解
//最开始的mpc是mac_policy_conf类型
//mac_policy_conf类型的定义在mac_policy.h里
struct mac_policy_conf {
    const char		*mpc_name;		/** policy name */
    const char		*mpc_fullname;		/** full name */
    const char		**mpc_labelnames;	/** managed label namespaces */
    unsigned int		 mpc_labelname_count;	/** number of managed label namespaces */
    struct mac_policy_ops	*mpc_ops;		/** operation vector */
    int			 mpc_loadtime_flags;	/** load time flags */
    int			*mpc_field_off;		/** label slot */
    int			 mpc_runtime_flags;	/** run time flags */
    mpc_t			 mpc_list;		/** List reference */
    void			*mpc_data;		/** module data */
};
//mac_policy_conf结构体里有个变量struct mac_policy_ops	*mpc_ops
//mac_policy_ops类型也定义在mac_policy.h里
struct mac_policy_ops{
//这个结构体里声明了非常多的mpo_xxxxxx的函数变量
//其中有个就是mpo_vnode_check_signature_t
mpo_vnode_check_signature_t		*mpo_vnode_check_signature;
}
//在policy_check.c里有policy_conf和mac_policy_ops的实现
//其中mac_policy_ops里的代码是
CHECK_SET_HOOK(vnode_check_signature)
//CHECK_SET_HOOK是一个宏,参数也就是上面调用MAC_CHECK宏的时候传进来的vnode_check_signature
//CHECK_SET_HOOK宏定义是这样的:
#define CHECK_SET_HOOK(x)	.mpo_##x = (mpo_##x##_t *)common_hook,
//也就是说CHECK_SET_HOOK(vnode_check_signature)可以变为:
.mpo_vnode_check_signature = (mpo_vnode_check_signature_t)common_hook
//common_hook的作用我还没了解.
//mpo_vnode_check_signature是mac_policy_ops结构体内声明的一个函数变量.
//这样通过(mpo_vnode_check_signature_t)common_hook可以赋值给这个函数变量,而其他没有赋值的函数变量都为NULL
//所以看懂了吧?
if (mpc->mpc_ops->mpo_ ## check != NULL) {	\
				if (mpc->mpc_ops->mpo_ ## check (args)	\
                    == 0)				\
                    error = 0;			\
                    }
//在MAC_CHECK宏里检查遍历结构体内的函数,检查是否为NULL,如果不是的话.会调用这个函数变量.会把先前接受到的参数传入.
MAC_CHECK(vnode_check_signature,vp,vp->v_label, macho_offset, sha1,
          signature, size, is_platform_binary);
//mpc->mpc_ops->mpo_ ## check (args),args是因为MAC_CHECK宏是多参数的.
 
实际执行时,会把mac_vnode_check_signature里调用MAC_CHECK宏的参数传入.
除去第一个参数,因为MAC_CHECK宏里是MAC_CHECK(check,args...)
//所以实际在MAC_CHECK宏里的调用是这样的:(返回一个int)
mpo_vnode_check_signature(vp,vp->v_label, macho_offset, sha1,signature, size, is_platform_binary)
//其他的通过MAC_CHECK的调用也是这么个流程.mpo_vnode_check_signature的执行代码在内核缓存二进制文件中.
{% endhighlight %}
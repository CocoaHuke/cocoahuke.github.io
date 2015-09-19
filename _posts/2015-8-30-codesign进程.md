---
layout: post
title: 进程上的代码签名验证(code-sign)
---

{% highlight bash %}
{% endhighlight %}
//vm_fault.c  
//当产生页错误时,vm_fault函数就会被调用.注意这里我觉得意思有些不对.其实只要分页被载入虚拟内存时,就会被调用.当然第一次也会被调用,所以这个函数调用是很频繁的.具体的东西去自己去查代码中的注释.比较详细.(关于这个自己去上网差虚拟内存和分页的原理.非常清楚,因为当第一次用次虚拟内存地址的时候发现没有映射到物理地址.便会产生页错误并映射到相应的物理内存地址等这样的操作.这不是个错误处理函数.这是个调用非常频繁的函数)  

//vm_fault就是vm_fault_internal的封装.直接调用了vm_fault_internal  
{% highlight bash %}
return vm_fault_internal(map, vaddr, fault_type, change_wiring,
                         interruptible, caller_pmap, caller_pmap_addr,
                         NULL);  
{% endhighlight %}
//vm_fault_internal函数很大.m是代表该页主要信息.是个struct    
vm_page_t		m;	/* Fast access to result_page */
 
//vm_fault_internal中检查m是否为空等很多操作.然后会调用vm_fault_enter,并把m传入参数.
{% highlight bash %}
kr = vm_fault_enter(m,
                    caller_pmap,
                    caller_pmap_addr,
                    prot,
                    fault_type,
                    wired,
                    change_wiring,
                    fault_info.no_cache,
                    fault_info.cs_bypass,
                    fault_info.user_tag,
                    fault_info.pmap_options,
                    need_retry_ptr,
                    &type_of_fault);
{% endhighlight %}  

//vm_fault_enter中会检查该页是否需要验证.  
/* Validate code signature if necessary. */
{% highlight bash %}
if (VM_FAULT_NEED_CS_VALIDATION(pmap, m)) {
    vm_object_lock_assert_exclusive(m->object);
    
    if (m->cs_validated) {
        vm_cs_revalidates++;
    }
    
    /* VM map is locked, so 1 ref will remain on VM object -
     * so no harm if vm_page_validate_cs drops the object lock */
    vm_page_validate_cs(m);//具体验证函数
}
{% endhighlight %}
//VM_FAULT_NEED_CS_VALIDATION是个宏,它的定义如下.  
{% highlight bash %}
    /*
     * CODE SIGNING:
     * When soft faulting a page, we have to validate the page if:
     * 1. the page is being mapped in user space
     * 2. the page hasn't already been found to be "tainted"
     * 3. the page belongs to a code-signed object
     * 4. the page has not been validated yet or has been mapped for write.
     当下面这些条件其中一个满足了,就会调用vm_page_validate_cs进行验证.m为参数
     该页映射在用户空间
     该页还尚未发现损坏
     该页属于进行过代码签名的对象
     该页尚未得到验证或有可写权限
     */
{% endhighlight %}
{% highlight bash %}
#define VM_FAULT_NEED_CS_VALIDATION(pmap, page)				\
((pmap) != kernel_pmap /*1*/ &&					\
!(page)->cs_tainted /*2*/ &&					\
(page)->object->code_signed /*3*/ &&				\
(!(page)->cs_validated || (page)->wpmapped /*4*/))
{% endhighlight %}
//vm_page_validate_cs开头是一些验证,详细可以自己去c文件里,比如会检查如果该页具有可写权限并且没有损坏,就会将该页设为已损坏,因为这样很危险,容易产生代码篡改.等一些验证自己去看.  

//vm_page_validate_cs会把m(vm_page_validate_cs里为page)的那份地址映射到内核虚拟空间  
{% highlight bash %}
kr = vm_paging_map_object(page,
                          object,
                          offset,
                          VM_PROT_READ,
                          FALSE, /* can't unlock object ! */
                          &ksize,
                          &koffset,
                          &need_unmap);
if (kr != KERN_SUCCESS) {
    panic("vm_page_validate_cs: could not map page: 0x%x\n", kr);
}
{% endhighlight %}
//关于映射地址空间的函数在vm_pageout.c中实现.详细了解去看文件源码.  
//然后会调用vm_page_validate_cs_mapped去验证.  
{% highlight bash %}
vm_page_validate_cs_mapped(page, (const void *) kaddr);//这个函数会验证并修改page的cs_tainted和cs_validated.
//vm_page_validate_cs_mapped中调用cs_validate_page进行具体验证.详细看源码
/* verify the SHA1 hash for this page */
validated = cs_validate_page(blobs,
                             pager,
                             offset + object->paging_offset,
                             (const void *)kaddr,
                             &tainted);
page->cs_validated = validated;
if (validated) {
    page->cs_tainted = tainted;
}
{% endhighlight %}
//cs_validate_page实现在ubc.subr.c文件.可以自己去参考.  
//然后会把验证结果给page的cs_validated和cs_tainted,再返回vm_page_validate_cs函数  

//vm_page_validate_cs经过些检查后(主要检查cs_validated和cs_tainted),会调用vm_paging_unmap_object撤销在内核地址空间的映射.该函数执行完后转回vm_fault_enter函数.  

{% highlight bash %}
if (need_unmap) {
    /* unmap the map from the kernel address space */
    vm_paging_unmap_object(object, koffset, koffset + ksize);
    koffset = 0;
    ksize = 0;
    kaddr = 0;
}
{% endhighlight %}
//在vm_fault_enter函数内,此时page的cs_validated和cs_tainted便是很重要的验证结果.
//然后用条件对m(page)结构体的这两个数据判断该页是否属于无效页.
{% highlight bash %}
/* A page could be tainted, or pose a risk of being tainted later.
 * Check whether the receiving process wants it, and make it feel
 * the consequences (that hapens in cs_invalid_page()).
 * For CS Enforcement, two other conditions will
 * cause that page to be tainted as well:
 * - pmapping an unsigned page executable - this means unsigned code;
 * - writeable mapping of a validated page - the content of that page
 *   can be changed without the kernel noticing, therefore unsigned
 *   code can be created
 */
/*
 下面的验证条件:
 1.改页已损坏.
 2.代码签名开启(cs_enforcement_enabled),该页未通过验证具有执行权限或者该页通过验证具有写权限(这应该是指该页曾经是代码页,代码页有hash可以通过验证,而代码页没有写权限,所以也要算入条件)
 */
{% endhighlight %}
{% highlight bash %}
if (m->cs_tainted ||
    ((cs_enforcement_enabled && !cs_bypass ) &&
     (/* The page is unsigned and wants to be executable */
      (!m->cs_validated && (prot & VM_PROT_EXECUTE))  ||
      /* The page should be immutable, but is in danger of being modified
       * This is the case where we want policy from the code directory -
       * is the page immutable or not? For now we have to assume that
       * code pages will be immutable, data pages not.
       * We'll assume a page is a code page if it has a code directory
       * and we fault for execution.
       * That is good enough since if we faulted the code page for
       * writing in another map before, it is wpmapped; if we fault
       * it for writing in this map later it will also be faulted for executing
       * at the same time; and if we fault for writing in another map
       * later, we will disconnect it from this pmap so we'll notice
       * the change.
       */
      (page_immutable(m, prot) && ((prot & VM_PROT_WRITE) || m->wpmapped))
      ))
    ) 
{
    //这里会有很多验证.主要会继续判断是否为无效页.并且会调用cs_invalid_page.该函数会对页设CS_KILL或CS_HARD标志.内核也会检查这两个标志进行不同的处理.
    ...
    reject_page = cs_invalid_page((addr64_t) vaddr);
    if(reject_page){...}
    else{...}
}
{% endhighlight %}
//主要检查就是这样的流程.详细请看源代码的实现,毕竟函数比较多,很难讲清楚.
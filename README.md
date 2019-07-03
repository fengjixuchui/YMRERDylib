
# 关于YMRERDylib
> iOS与Mac平台App的安全问题, 一直比较薄弱, 不是我们不会加固, 是因为苹果爸爸原则上不允许我们这样做, 他们坚信苹果能为我们的App保驾护航, 但现实总是啪啪打脸, 微信甚至支付宝都可以在很轻松的情况下被砸壳, 逆向, 分析最后修改
     
# ①反调试 
- check_debug
```
bool check_debug(){
    int sys_name[4];
    sys_name[0] = CTL_KERN;
    sys_name[1] = KERN_PROC;
    sys_name[2] = KERN_PROC_PID;
    sys_name[3] = getpid();
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    int error = sysctl(sys_name, sizeof(sys_name)/sizeof(*sys_name), &info, &info_size, 0, 0);
    assert(error == 0);
    
    return ((info.kp_proc.p_flag & P_TRACED) !=0);
}

```

# ②反反调试
```
int (*sysctl_p)(int *, u_int, void *, size_t *, void *, size_t);
int hook_sysctl_p(int *sys_name, u_int namelen, void *info, size_t *infosize, void *newinfo, size_t newinfosize){
    if (namelen == 4
        && sys_name[0] == CTL_KERN
        && sys_name[1] == KERN_PROC
        && sys_name[2] == KERN_PROC_PID
        && info
        && (int)*infosize == sizeof(struct kinfo_proc))
    {
        int err = sysctl_p(sys_name, namelen, info, infosize, newinfo, newinfosize);
        struct kinfo_proc * myInfo = (struct kinfo_proc *)info;
        if((myInfo->kp_proc.p_flag & P_TRACED) != 0){
            myInfo->kp_proc.p_flag ^= P_TRACED;
        }
        return err;
    }
    
    return sysctl_p(sys_name, namelen, info, infosize, newinfo, newinfosize);
}

```
- 通过hook_sysctl_p函数hook掉sysctl库的sysctl_p函数, 达到反反调试的目的
```
rebind_symbols((struct rebinding[1]){{"sysctl",hook_sysctl_p,(void *)&sysctl_p}}, 1);

```

# ③字符串反反编译 
> 逆向中的很多逻辑线索的寻找, 是通过字符串猜测到的, 而主流反编译工具可以很轻松的还原这些字符. 所以对关键字符的隐藏至关重要. 至关重要. 至关...
### 普通创建字符串方式
```
- (void)Test {
    NSString *hello_world = @"helloWorld";
}

```
- 反编译后一目了然
<p align="center">
<img src="https://github.com/MustangYM/YMRERDylib/blob/master/YMRERDylib/YMRERDylib/pics/WX20190703-180315.png" width="800px"/>
</p>

### YMRERDylib隐藏的创建方式
```
- (void)Test1 {
    NSString *hello_world1 = [YMRERDylib creatNSString];
}

```
- 反编译后的结果
<p align="center">
<img src="https://github.com/MustangYM/YMRERDylib/blob/master/YMRERDylib/YMRERDylib/pics/WX20190703-180558.png" width="800px"/>
</p>

- 即便黑客拿到了creatNSString这个方法, 追踪进来也不无法直接得出字符串
<p align="center">
<img src="https://github.com/MustangYM/YMRERDylib/blob/master/YMRERDylib/YMRERDylib/pics/WX20190703-180646.png" width="800px"/>
</p>

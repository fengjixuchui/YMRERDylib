//
//  YMRERDylib.m
//  YMRERDylib
//
//  Created by MustangYM on 2019/7/3.
//  Copyright © 2019 MustangYM. All rights reserved.
//

#define MEM_KEY 0xBB

#import "YMRERDylib.h"
#import <sys/sysctl.h>
#import "fishhook.h"

bool check_debug(){
    int name[4];
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    int error = sysctl(name, sizeof(name)/sizeof(*name), &info, &info_size, 0, 0);
    assert(error == 0);
    
    return ((info.kp_proc.p_flag & P_TRACED) !=0);
}

void FFyuzAZO(unsigned char *string, unsigned char key)
{
    unsigned char *p = string;
    while( ((*p) ^=  key) != '\0')  p++;
}


int (*sysctl_p)(int *, u_int, void *, size_t *, void *, size_t);
int hook_sysctl_p(int *name, u_int namelen, void *info, size_t *infosize, void *newinfo, size_t newinfosize){
    if (namelen == 4
        && name[0] == CTL_KERN
        && name[1] == KERN_PROC
        && name[2] == KERN_PROC_PID
        && info
        && (int)*infosize == sizeof(struct kinfo_proc))
    {
        int err = sysctl_p(name, namelen, info, infosize, newinfo, newinfosize);
        struct kinfo_proc * myInfo = (struct kinfo_proc *)info;
        if((myInfo->kp_proc.p_flag & P_TRACED) != 0){
            myInfo->kp_proc.p_flag ^= P_TRACED;
        }
        return err;
    }
    
    return sysctl_p(name, namelen, info, infosize, newinfo, newinfosize);
}


@implementation YMRERDylib

+ (void)load {
    rebind_symbols((struct rebinding[1]){{"sysctl",hook_sysctl_p,(void *)&sysctl_p}}, 1);
    if (check_debug()) {
        //检测到调试就退出
        asm("mov X0,#0\n"
            "mov w16,#1\n"
            "svc #0x80"
            );
    }
}

+ (NSString *)creatNSString {
    //hello world
    unsigned char str[] = {
        
        /// your string
        (MEM_KEY ^ 'h'),
        (MEM_KEY ^ 'e'),
        (MEM_KEY ^ 'l'),
        (MEM_KEY ^ 'l'),
        (MEM_KEY ^ 'o'),
        (MEM_KEY ^ 'w'),
        (MEM_KEY ^ 'o'),
        (MEM_KEY ^ 'r'),
        (MEM_KEY ^ 'l'),
        (MEM_KEY ^ 'd'),
        /// your string
        
        (MEM_KEY ^ '\0')};
    FFyuzAZO(str, MEM_KEY);
    static unsigned char result[10];
    memcpy(result, str, 10);
    return [NSString stringWithFormat:@"%s",result];
}
@end

//
//  proc.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include "proc.h"
#include "offsets.h"
#include "krw.h"
#include <stdbool.h>
#include <string.h>
#include <unistd.h>

uint64_t getProc(pid_t pid) {
    printf("get kernproc\n");
    uint64_t proc = get_kernproc();
    
    while (true) {
        if(kread32(proc + off_p_pid) == pid) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
    }
    
    return 0;
}

uint64_t getProcByName(char* nm) {
    uint64_t proc = get_kernproc();
    
    while (true) {
        uint64_t nameptr = proc + off_p_name;
        char name[32];
        do_kread(nameptr, &name, 32);
//        printf("[i] pid: %d, process name: %s\n", kread32(proc + off_p_pid), name);
        if(strcmp(name, nm) == 0) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
    }
    
    return 0;
}

int getPidByName(char* nm) {
    return kread32(getProcByName(nm) + off_p_pid);
}

int funProc(uint64_t proc) {
    int p_ppid = kread32(proc + off_p_ppid);
    printf("[i] self proc->p_ppid: %d\n", p_ppid);
    printf("[i] Patching proc->p_ppid %d -> 1 (for testing kwrite32, getppid)\n", p_ppid);
    kwrite32(proc + off_p_ppid, 0x1);
    printf("[+] Patched getppid(): %u\n", getppid());
    kwrite32(proc + off_p_ppid, p_ppid);
    printf("[+] Restored getppid(): %u\n", getppid());

    int p_original_ppid = kread32(proc + off_p_original_ppid);
    printf("[i] self proc->p_original_ppid: %d\n", p_original_ppid);
    
    int p_pgrpid = kread32(proc + off_p_pgrpid);
    printf("[i] self proc->p_pgrpid: %d\n", p_pgrpid);
    
    int p_uid = kread32(proc + off_p_uid);
    printf("[i] self proc->p_uid: %d\n", p_uid);
    
    int p_gid = kread32(proc + off_p_gid);
    printf("[i] self proc->p_gid: %d\n", p_gid);
    
    int p_ruid = kread32(proc + off_p_ruid);
    printf("[i] self proc->p_ruid: %d\n", p_ruid);
    
    int p_rgid = kread32(proc + off_p_rgid);
    printf("[i] self proc->p_rgid: %d\n", p_rgid);
    
    int p_svuid = kread32(proc + off_p_svuid);
    printf("[i] self proc->p_svuid: %d\n", p_svuid);
    
    int p_svgid = kread32(proc + off_p_svgid);
    printf("[i] self proc->p_svgid: %d\n", p_svgid);
    
    int p_sessionid = kread32(proc + off_p_sessionid);
    printf("[i] self proc->p_sessionid: %d\n", p_sessionid);
    
    uint64_t p_puniqueid = kread64(proc + off_p_puniqueid);
    printf("[i] self proc->p_puniqueid: 0x%llx\n", p_puniqueid);
    
    printf("[i] Patching proc->p_puniqueid 0x%llx -> 0x4142434445464748 (for testing kwrite64)\n", p_puniqueid);
    kwrite64(proc + off_p_puniqueid, 0x4142434445464748);
    printf("[+] Patched self proc->p_puniqueid: 0x%llx\n", kread64(proc + off_p_puniqueid));
    kwrite64(proc + off_p_puniqueid, p_puniqueid);
    printf("[+] Restored self proc->p_puniqueid: 0x%llx\n", kread64(proc + off_p_puniqueid));
    
    return 0;
}

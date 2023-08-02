//
//  offsets.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include "offsets.h"
#include <UIKit/UIKit.h>
#include <Foundation/Foundation.h>

uint32_t off_p_list_le_prev = 0;
uint32_t off_p_proc_ro = 0;
uint32_t off_p_ppid = 0;
uint32_t off_p_original_ppid = 0;
uint32_t off_p_pgrpid = 0;
uint32_t off_p_uid = 0;
uint32_t off_p_gid = 0;
uint32_t off_p_ruid = 0;
uint32_t off_p_rgid = 0;
uint32_t off_p_svuid = 0;
uint32_t off_p_svgid = 0;
uint32_t off_p_sessionid = 0;
uint32_t off_p_puniqueid = 0;
uint32_t off_p_pid = 0;
uint32_t off_p_pfd = 0;
uint32_t off_p_textvp = 0;
uint32_t off_p_name = 0;
uint32_t off_p_ro_p_csflags = 0;
uint32_t off_p_ro_p_ucred = 0;
uint32_t off_p_ro_pr_proc = 0;
uint32_t off_p_ro_pr_task = 0;
uint32_t off_p_ro_t_flags_ro = 0;
uint32_t off_u_cr_label = 0;
uint32_t off_u_cr_posix = 0;
uint32_t off_cr_uid = 0;
uint32_t off_cr_ruid = 0;
uint32_t off_cr_svuid = 0;
uint32_t off_cr_ngroups = 0;
uint32_t off_cr_groups = 0;
uint32_t off_cr_rgid = 0;
uint32_t off_cr_svgid = 0;
uint32_t off_cr_gmuid = 0;
uint32_t off_cr_flags = 0;
uint32_t off_task_t_flags = 0;
uint32_t off_fd_ofiles = 0;
uint32_t off_fp_glob = 0;
uint32_t off_fg_data = 0;
uint32_t off_fg_flag = 0;
uint32_t off_vnode_v_iocount = 0;
uint32_t off_vnode_v_usecount = 0;
uint32_t off_vnode_v_flag = 0;
uint32_t off_vnode_v_name = 0;
uint32_t off_vnode_v_mount = 0;
uint32_t off_vnode_v_data = 0;
uint32_t off_vnode_v_kusecount = 0;
uint32_t off_vnode_v_references = 0;
uint32_t off_vnode_v_parent = 0;
uint32_t off_vnode_v_label = 0;
uint32_t off_vnode_v_cred = 0;
uint32_t off_vnode_v_writecount = 0;
uint32_t off_vnode_v_type = 0;
uint32_t off_mount_mnt_data = 0;
uint32_t off_mount_mnt_fsowner = 0;
uint32_t off_mount_mnt_fsgroup = 0;
uint32_t off_mount_mnt_devvp = 0;
uint32_t off_mount_mnt_flag = 0;
uint32_t off_specinfo_si_flags = 0;

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)

void _offsets_init(void) {
//    if (SYSTEM_VERSION_EQUAL_TO(@"16.1.2")) {
//        printf("[i] offsets selected for iOS 16.1.2\n");
        //iPhone 14 Pro 16.1.2 offsets
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/proc_internal.h#L273
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/queue.h#L487
        off_p_list_le_prev = 0x8;
        off_p_proc_ro = 0x18;
        off_p_ppid = 0x20;
        off_p_original_ppid = 0x24;
        off_p_pgrpid = 0x28;
        off_p_uid = 0x2c;
        off_p_gid = 0x30;
        off_p_ruid = 0x34;
        off_p_rgid = 0x38;
        off_p_svuid = 0x3c;
        off_p_svgid = 0x40;
        off_p_sessionid = 0x44;
        off_p_puniqueid = 0x48;
        off_p_pid = 0x60;
        off_p_pfd = 0xf8;
        off_p_textvp = 0x350;
        off_p_name = 0x381;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/proc_ro.h#L59
        off_p_ro_p_csflags = 0x1c;
        off_p_ro_p_ucred = 0x20;
        off_p_ro_pr_proc = 0;
        off_p_ro_pr_task = 0x8;
        off_p_ro_t_flags_ro = 0x78;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/ucred.h#L91
        off_u_cr_label = 0x78;
        off_u_cr_posix = 0x18;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/ucred.h#L100
        off_cr_uid = 0;
        off_cr_ruid = 0x4;
        off_cr_svuid = 0x8;
        off_cr_ngroups = 0xc;
        off_cr_groups = 0x10;
        off_cr_rgid = 0x50;
        off_cr_svgid = 0x54;
        off_cr_gmuid = 0x58;
        off_cr_flags = 0x5c;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/osfmk/kern/task.h#L280
        off_task_t_flags = 0x3D0;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/filedesc.h#L138
        off_fd_ofiles = 0;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/file_internal.h#L125
        off_fp_glob = 0x10;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/file_internal.h#L179
        off_fg_data = 0x38;
        off_fg_flag = 0x10;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/vnode_internal.h#L158
        off_vnode_v_iocount = 0x64;
        off_vnode_v_usecount = 0x60;
        off_vnode_v_flag = 0x54;
        off_vnode_v_name = 0xb8;
        off_vnode_v_mount = 0xd8;
        off_vnode_v_data = 0xe0;
        off_vnode_v_kusecount = 0x5c;
        off_vnode_v_references = 0x5b;
        off_vnode_v_parent = 0xc0;
        off_vnode_v_label = 0xe8;
        off_vnode_v_cred = 0x98;
        off_vnode_v_writecount = 0xb0;
        off_vnode_v_type = 0x70;
        
        //https://github.com/apple-oss-distributions/xnu/blob/main/bsd/sys/mount_internal.h#L108
        off_mount_mnt_data = 0x11F;
        off_mount_mnt_fsowner = 0x9c0;
        off_mount_mnt_fsgroup = 0x9c4;
        off_mount_mnt_devvp = 0x980;
        off_mount_mnt_flag = 0x70;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/miscfs/specfs/specdev.h#L77
        off_specinfo_si_flags = 0x10;
        
//    } else {
//        printf("[-] No matching offsets.\n");
//        exit(EXIT_FAILURE);
    }
//}

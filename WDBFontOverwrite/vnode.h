//
//  vnode.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include <stdio.h>

#define MNT_RDONLY      0x00000001      /* read only filesystem */
#define VISSHADOW       0x008000        /* vnode is a shadow file */

uint64_t getVnodeAtPath(char* filename);
uint64_t findRootVnode(void);

/*
Description:
  Hide and reveal file or directory.
*/
uint64_t funVnodeHide(char* filename);

/*
Description:
  Perform chown to file or directory.
*/
uint64_t funVnodeChown(char* filename, uid_t uid, gid_t gid);

/*
Description:
  Perform chmod to file or directory.
*/
uint64_t funVnodeChmod(char* filename, mode_t mode);

/*
Description:
  Redirect directory to another directory.
  Only work when mount points of directories are same.
*/
uint64_t funVnodeRedirectFolder(char* to, char* from);

/*
Description:
  Perform overwrite file data to file.
  Only work when file size is 'lower or same' than original file size.
*/
uint64_t funVnodeOverwriteFile(char* to, char* from);

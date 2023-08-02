//
//  thanks_opa334dev_htrowii.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/30.
//
#import <Foundation/Foundation.h>

uint64_t funVnodeOverwrite2(char* tofile, char* fromfile);
uint64_t funVnodeOverwriteWithBytes(const char* filename, off_t file_offset, const void* overwrite_data, size_t overwrite_length, bool unmapAtEnd);

//
//  krw.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#ifndef krw_h
#define krw_h

#include <stdio.h>



uint64_t do_kopen(uint64_t puaf_pages, uint64_t puaf_method, uint64_t kread_method, uint64_t kwrite_method);
void do_kclose(uint64_t kfd);
void do_kread(uint64_t kaddr, void* uaddr, uint64_t size);
void do_kwrite(void* uaddr, uint64_t kaddr, uint64_t size);
uint64_t get_kslide(void);
uint64_t get_kernproc(void);
uint8_t kread8(uint64_t where);
uint32_t kread16(uint64_t where);
uint32_t kread32(uint64_t where);
uint64_t kread64(uint64_t where);
void kwrite8(uint64_t where, uint8_t what);
void kwrite16(uint64_t where, uint16_t what);
void kwrite32(uint64_t where, uint32_t what);
void kwrite64(uint64_t where, uint64_t what);

#endif /* krw_h */

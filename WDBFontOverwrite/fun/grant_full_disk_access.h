#import <Foundation/Foundation.h>

/// Uses kfd exploit to grant the current app read/write access outside the sandbox.
void grant_full_disk_access(void (^_Nonnull completion)(NSError* _Nullable));
bool patch_installd(void);

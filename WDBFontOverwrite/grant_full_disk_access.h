//
//  grant_full_disk_access.h
//  WDBFontOverwrite
//
//  Created by Noah Little on 29/1/2023.
//
@import Foundation;
#ifndef grant_full_disk_access_h
#define grant_full_disk_access_h

void grant_full_disk_access(void (^completion)(NSError* _Nullable));

#endif /* grant_full_disk_access_h */

//
//  _UIKeyboardCache.h
//  WDBFontOverwrite
//
//  Created by Noah Little on 6/1/2023.
//

#ifndef _UIKeyboardCache_h
#define _UIKeyboardCache_h

#import <Foundation/Foundation.h>

@interface UIKeyboardCache : NSObject
+ (instancetype)sharedInstance;
- (void)purge;
@end

@interface _UIKeyboardCache : NSObject
+ (void)purge;
@end

#endif /* _UIKeyboardCache_h */

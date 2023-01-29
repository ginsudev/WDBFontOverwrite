//
//  _UIKeyboardCache.m
//  WDBFontOverwrite
//
//  Created by Noah Little on 6/1/2023.
//

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import "_UIKeyboardCache.h"

@implementation _UIKeyboardCache

+ (void)purge {
    void *handle = dlopen("/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore", RTLD_NOW);
    if (handle) {
        NSObject *kbCache = [objc_getClass("UIKeyboardCache") performSelector:@selector(sharedInstance)];
        [kbCache performSelector:@selector(purge)];
    }
}

@end

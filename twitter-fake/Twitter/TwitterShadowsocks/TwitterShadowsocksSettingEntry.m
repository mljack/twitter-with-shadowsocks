//
//  TwitterShadowsocksSettingEntry.m
//  TwitterShadowsocks
//
//  Created by Ethan on 15/2/9.
//  Copyright (c) 2015年 com. All rights reserved.
//

#import "TwitterShadowsocksSettingEntry.h"
#import <objc/runtime.h>
#import "SSKeychain.h"
#import <dlfcn.h>
#import "fishhook.h"

static NSString * const kTwitterPasswordService = @"com.twitter.twitter-iphone";

@implementation TwitterShadowsocksSettingEntry

static IMP originalImplement_setting = NULL;
static IMP originalImplement_account = NULL;
static IMP originalImplement_account_save = NULL;
static IMP originalImplement_account_didAppear = NULL;

static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef *);
static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef *);

+(void)load
{
    [self disableSPDY];
    
    IMP newImplement = class_getMethodImplementation(self, @selector(viewWillAppear_xxx:));
    originalImplement_setting = method_setImplementation(class_getInstanceMethod(NSClassFromString(@"T1SettingsViewController"), @selector(viewWillAppear:)), newImplement);
    originalImplement_account = method_setImplementation(class_getInstanceMethod(NSClassFromString(@"T1AddAccountViewController"), @selector(viewWillAppear:)), newImplement);
    
//    IMP newImplement_save = class_getMethodImplementation(self, @selector(save:));
//    originalImplement_account_save = method_setImplementation(class_getInstanceMethod(NSClassFromString(@"T1AddAccountViewController"), @selector(save:)), newImplement_save);
    
//    IMP newImplement_didAppear = class_getMethodImplementation(self, @selector(viewDidAppear_xxx:));
//    originalImplement_account_didAppear = method_setImplementation(class_getInstanceMethod(NSClassFromString(@"T1AddAccountViewController"), @selector(viewDidAppear:)), newImplement_didAppear);
    
    // disable endableSPDY
    method_setImplementation(class_getInstanceMethod(NSClassFromString(@"T1SPDYConfigurationChangeListener"), NSSelectorFromString(@"_enableSPDY")), class_getMethodImplementation(self, @selector(enableSPDY)));
    
    // hook to remote keychain access group key
    orig_SecItemCopyMatching = dlsym(RTLD_DEFAULT, "SecItemCopyMatching");
    rebind_symbols((struct rebinding[1]){{"SecItemCopyMatching", SecItemCopyMatching_s}}, 1);
    orig_SecItemAdd = dlsym(RTLD_DEFAULT, "SecItemAdd");
    rebind_symbols((struct rebinding[1]){{"SecItemAdd", SecItemAdd_s}}, 1);
}

OSStatus SecItemCopyMatching_s ( CFDictionaryRef query, CFTypeRef *result )
{
    NSMutableDictionary *queryMutable = [NSMutableDictionary dictionaryWithDictionary:(__bridge NSDictionary *)(query)];
    [queryMutable removeObjectForKey:(__bridge id)(kSecAttrAccessGroup)];
    
    OSStatus status = orig_SecItemCopyMatching((__bridge CFDictionaryRef)queryMutable, result);
//    NSLog(@"%s: result=%d, %@, %@, %@", __FUNCTION__, (int)status, queryMutable, *result, [NSThread callStackSymbols]);
    return status;
}

OSStatus SecItemAdd_s ( CFDictionaryRef attributes, CFTypeRef *result )
{
    NSMutableDictionary *queryMutable = [NSMutableDictionary dictionaryWithDictionary:(__bridge NSDictionary *)(attributes)];
    [queryMutable removeObjectForKey:(__bridge id)(kSecAttrAccessGroup)];
    
    OSStatus status = orig_SecItemAdd((__bridge CFDictionaryRef)(queryMutable), result);
//    NSLog(@"%s: result=%d, %@, %@", __FUNCTION__, (int)status, queryMutable, *result);
    return status;
}

- (void)enableSPDY
{
    // just diable anywhere call this method
}

+ (void)disableSPDY
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // disable SPDY
    Class T1SPDYConfigurationChangeListener = NSClassFromString(@"T1SPDYConfigurationChangeListener");
    if (T1SPDYConfigurationChangeListener != NULL) {
        id defaultListener = [[T1SPDYConfigurationChangeListener class] performSelector:NSSelectorFromString(@"defaultListener")];
        [defaultListener performSelector:NSSelectorFromString(@"_disableSPDY")];
        
        NSLog(@"SPDY disabled.");
    }
#pragma clang diagnostic pop
}

__weak static UINavigationController *settingNavigation = nil;
-(void)viewWillAppear_xxx:(BOOL)animated
{
    NSString *className = NSStringFromClass([self class]);
    
    // add Shadowsocks setting entry
    settingNavigation = self.navigationController;
    UIBarButtonItem *shadowsocksItem = [[UIBarButtonItem alloc] initWithTitle:@"Shadowsocks" style:UIBarButtonItemStylePlain target:[TwitterShadowsocksSettingEntry class] action:@selector(pushShadowsocksConfiguration:)];
    
    if ([className isEqualToString:@"T1SettingsViewController"]) {
        self.navigationItem.leftBarButtonItem = shadowsocksItem;
        ((void(*)(id, SEL, BOOL))originalImplement_setting)(self, @selector(viewWillAppear:), animated);
    } else if ([className isEqualToString:@"T1AddAccountViewController"]) {
        self.navigationItem.rightBarButtonItem = shadowsocksItem;
        ((void(*)(id, SEL, BOOL))originalImplement_account)(self, @selector(viewWillAppear:), animated);
    }
}

-(void)viewDidAppear_xxx:(BOOL)animated
{
    ((void(*)(id, SEL, BOOL))originalImplement_account_didAppear)(self, @selector(viewDidAppear:), animated);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//    UITextField *passwordField = [self performSelector:NSSelectorFromString(@"passwordField")];
//    NSString *account = [[self performSelector:NSSelectorFromString(@"account")] performSelector:NSSelectorFromString(@"username")];
//    if (passwordField && account && account.length > 0) {
//        NSLog(@"load password from keychain: %@", kTwitterPasswordService);
//        NSString *password = [SSKeychain passwordForService:kTwitterPasswordService account:account];
//        if (password && password.length > 0) {
//            passwordField.text = password;
//        }
//    }
#pragma clang diagnostic pop
}

+(void)pushShadowsocksConfiguration:(UIBarButtonItem*)sender
{
    if (settingNavigation) {
        [settingNavigation pushViewController:[NSClassFromString(@"ShadowsocksableConfigurationViewController") new] animated:YES];
    }
}

- (void)save:(id)arg1
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    UITextField *passwordField = [self performSelector:NSSelectorFromString(@"passwordField")];
    NSString *account = [[self performSelector:NSSelectorFromString(@"account")] performSelector:NSSelectorFromString(@"username")];
    NSError *error = nil;
    [SSKeychain setPassword:passwordField.text forService:kTwitterPasswordService account:account error:&error];
    if (error) {
        NSLog(@"save error: %@", error);
    }
    NSLog(@"save password to keychain: %@", kTwitterPasswordService);
#pragma clang diagnostic pop
    
    ((void(*)(id, SEL, id))originalImplement_account_save)(self, @selector(save:), arg1);
}

@end

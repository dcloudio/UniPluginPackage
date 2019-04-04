//
//  AppDelegate.m
//  Pandora
//
//  Created by Mac Pro_C on 12-12-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "PDRCore.h"
#import "PDRCommonString.h"

@implementation AppDelegate

@synthesize window = _window;

#pragma mark -
#pragma mark app lifecycle
/*
 * @Summary:程序启动时收到push消息
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UINavigationController* pNavCon = [[UINavigationController alloc]
                                       initWithRootViewController:_window.rootViewController];
    _window.rootViewController = pNavCon;
    
    [pNavCon release];
    [self UniCoreEventWithApplication:application withMethod:@"application:didFinishLaunchingWithOptions:" :launchOptions :nil];
    // 设置当前SDK运行模式
    // 使用WebApp集成是使用的启动参数
    return [PDRCore initEngineWihtOptions:launchOptions withRunMode:PDRCoreRunModeAppClient];
    
    // 使用WebView集成时使用的启动参数
    return [PDRCore initEngineWihtOptions:launchOptions withRunMode:PDRCoreRunModeWebviewClient];
}

// IOS 9 以下这句会报错，请升级xcode到最新或者删除此代码
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
  completionHandler:(void(^)(BOOL succeeded))completionHandler{
    [PDRCore handleSysEvent:PDRCoreSysEventPeekQuickAction withObject:shortcutItem];
    completionHandler(true);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [PDRCore handleSysEvent:PDRCoreSysEventBecomeActive withObject:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [PDRCore handleSysEvent:PDRCoreSysEventResignActive withObject:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventEnterBackground withObject:nil];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventEnterForeGround withObject:nil];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[PDRCore Instance] unLoad];
}

#pragma mark -
#pragma mark URL

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    [self application:application handleOpenURL:url];
    return YES;
}

/*
 * @Summary:程序被第三方调用，传入参数启动
 *
 */
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventOpenURL withObject:url];
    [self UniCoreEventWithApplication:application withMethod:@"application:handleOpenURL:" :url :nil];
    return YES;
}


#pragma mark -
#pragma mark APNS
/*
 * @Summary:远程push注册成功收到DeviceToken回调
 *
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRevDeviceToken withObject:deviceToken];
    [self UniCoreEventWithApplication:application withMethod:@"application:didRegisterForRemoteNotificationsWithDeviceToken:" :deviceToken :nil];
}

/*
 * @Summary: 远程push注册失败
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRegRemoteNotificationsError withObject:error];
    [self UniCoreEventWithApplication:application withMethod:@"application:didFailToRegisterForRemoteNotificationsWithError:" :error :nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRevRemoteNotification withObject:userInfo];
    [self UniCoreEventWithApplication:application withMethod:@"application:didReceiveRemoteNotification:" :userInfo :nil];
}
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    [self application:application didReceiveRemoteNotification:userInfo];
    [self UniCoreEventWithApplication:application withMethod:@"application:didReceiveRemoteNotification:fetchCompletionHandler:" :userInfo :completionHandler];
    completionHandler(UIBackgroundFetchResultNewData);
}
/*
 * @Summary:程序收到本地消息
 */
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRevLocalNotification withObject:notification];
    [self UniCoreEventWithApplication:application withMethod:@"application:didReceiveLocalNotification:" :notification :nil];
}
/*
 * @Summary:通用链接
 */
-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler{
    [self UniCoreEventWithApplication:application withMethod:@"application:continueUserActivity:restorationHandler:" :userActivity :restorationHandler];
    return YES;
}

-(void)UniCoreEventWithApplication:(UIApplication*)app withMethod:(NSString*)method :(id)parameter1 :(id)parameter2{
    Class uniwxCore = NSClassFromString(@"UniWXCore");
    SEL sharedInstance = NSSelectorFromString(@"sharedInstance");
    if([uniwxCore respondsToSelector:sharedInstance]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        Class UniCore = [uniwxCore performSelector:sharedInstance];
#pragma clang diagnostic pop
        SEL selector = NSSelectorFromString(method);
        if([UniCore respondsToSelector:selector]){
            NSMethodSignature* methodSig = [UniCore methodSignatureForSelector:selector];
            if(methodSig == nil) return ;
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
            [invocation setTarget:UniCore];
            [invocation setSelector:selector];
            [invocation setArgument:&app atIndex:2];
            if(parameter1 != nil)[invocation setArgument:&parameter1 atIndex:3];
            if(parameter2 !=nil)[invocation setArgument:&parameter2 atIndex:4];
            [invocation invoke];
        }
    }
}
- (void)dealloc
{
    [super dealloc];
}

@end

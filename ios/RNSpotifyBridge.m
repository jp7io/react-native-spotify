
//
//  ComponentObjectiveC.m
//  MixedLanugageExample
//
//  Created by Gergely Orosz on 18/07/2015.
//  Copyright © 2015 GergelyOrosz. All rights reserved.
//

#import "RNSpotifyBridge.h"
#import <RNSpotify-Swift.h>

@implementation RNSpotifyBridge

+(NSString*) sayHello: (NSString*) name {
    return [[RNSpotifyHello new] sayHello:@"Swiftception"];
}

+ (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    [RNSpotify application:app url:url options:options];
    return true;
}

+(void)applicationDidBecomeActive:(UIApplication *)application {
    [RNSpotify applicationDidBecomeActive:application];
}

+(void) applicationWillResignActive:(UIApplication *)application {
    [RNSpotify applicationWillResignActive:application];
}

+(void) applicationWillTerminate:(UIApplication *)application {
    [RNSpotify applicationWillTerminate:application];
}

@end

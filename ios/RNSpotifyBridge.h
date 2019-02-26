//
//  ComponentObjectiveC.h
//  MixedLanugageExample
//
//  Created by Gergely Orosz on 18/07/2015.
//  Copyright © 2015 GergelyOrosz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RNSpotifyBridge : NSObject

+(NSString*) sayHello: (NSString*) name;

+(BOOL)application:(UIApplication *)app
           openURL:(NSURL *)url
           options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;

+(void)applicationDidBecomeActive:(UIApplication *)application;

+(void)applicationWillResignActive:(UIApplication *)application;

@end

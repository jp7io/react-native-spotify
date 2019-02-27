#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNSpotify, NSObject)

RCT_EXTERN_METHOD(initialize:(NSDictionary *)configurations resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(connect:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(disconnect)
RCT_EXTERN_METHOD(setPlayState:(BOOL)play)
RCT_EXTERN_METHOD(nextSong)
RCT_EXTERN_METHOD(previousSong)
RCT_EXTERN_METHOD(playURI:(NSString)identifier)
RCT_EXTERN_METHOD(updatePlayerState)
RCT_EXTERN_METHOD(isInitializedAsync:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(isLoggedInAsync:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)

@end

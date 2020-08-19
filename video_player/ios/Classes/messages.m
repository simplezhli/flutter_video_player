// Autogenerated from Pigeon (v0.1.4), do not edit directly.
// See also: https://pub.dev/packages/pigeon
#import "messages.h"
#import <Flutter/Flutter.h>

#if !__has_feature(objc_arc)
#error File requires ARC to be enabled.
#endif

static NSDictionary* wrapResult(NSDictionary *result, FlutterError *error) {
  NSDictionary *errorDict = (NSDictionary *)[NSNull null];
  if (error) {
    errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
        (error.code ? error.code : [NSNull null]), @"code",
        (error.message ? error.message : [NSNull null]), @"message",
        (error.details ? error.details : [NSNull null]), @"details",
        nil];
  }
  return [NSDictionary dictionaryWithObjectsAndKeys:
      (result ? result : [NSNull null]), @"result",
      errorDict, @"error",
      nil];
}

@interface FLTTextureMessage ()
+(FLTTextureMessage*)fromMap:(NSDictionary*)dict;
-(NSDictionary*)toMap;
@end
@interface FLTCreateMessage ()
+(FLTCreateMessage*)fromMap:(NSDictionary*)dict;
-(NSDictionary*)toMap;
@end
@interface FLTLoopingMessage ()
+(FLTLoopingMessage*)fromMap:(NSDictionary*)dict;
-(NSDictionary*)toMap;
@end
@interface FLTVolumeMessage ()
+(FLTVolumeMessage*)fromMap:(NSDictionary*)dict;
-(NSDictionary*)toMap;
@end
@interface FLTBrightnessMessage ()
+(FLTBrightnessMessage*)fromMap:(NSDictionary*)dict;
-(NSDictionary*)toMap;
@end
@interface FLTPositionMessage ()
+(FLTPositionMessage*)fromMap:(NSDictionary*)dict;
-(NSDictionary*)toMap;
@end

@implementation FLTTextureMessage
+(FLTTextureMessage*)fromMap:(NSDictionary*)dict {
  FLTTextureMessage* result = [[FLTTextureMessage alloc] init];
  result.textureId = dict[@"textureId"];
  if ((NSNull *)result.textureId == [NSNull null]) {
    result.textureId = nil;
  }
  return result;
}
-(NSDictionary*)toMap {
  return [NSDictionary dictionaryWithObjectsAndKeys:(self.textureId ? self.textureId : [NSNull null]), @"textureId", nil];
}
@end

@implementation FLTCreateMessage
+(FLTCreateMessage*)fromMap:(NSDictionary*)dict {
  FLTCreateMessage* result = [[FLTCreateMessage alloc] init];
  result.asset = dict[@"asset"];
  if ((NSNull *)result.asset == [NSNull null]) {
    result.asset = nil;
  }
  result.uri = dict[@"uri"];
  if ((NSNull *)result.uri == [NSNull null]) {
    result.uri = nil;
  }
  result.packageName = dict[@"packageName"];
  if ((NSNull *)result.packageName == [NSNull null]) {
    result.packageName = nil;
  }
  result.formatHint = dict[@"formatHint"];
  if ((NSNull *)result.formatHint == [NSNull null]) {
    result.formatHint = nil;
  }
  return result;
}
-(NSDictionary*)toMap {
  return [NSDictionary dictionaryWithObjectsAndKeys:(self.asset ? self.asset : [NSNull null]), @"asset", (self.uri ? self.uri : [NSNull null]), @"uri", (self.packageName ? self.packageName : [NSNull null]), @"packageName", (self.formatHint ? self.formatHint : [NSNull null]), @"formatHint", nil];
}
@end

@implementation FLTLoopingMessage
+(FLTLoopingMessage*)fromMap:(NSDictionary*)dict {
  FLTLoopingMessage* result = [[FLTLoopingMessage alloc] init];
  result.textureId = dict[@"textureId"];
  if ((NSNull *)result.textureId == [NSNull null]) {
    result.textureId = nil;
  }
  result.isLooping = dict[@"isLooping"];
  if ((NSNull *)result.isLooping == [NSNull null]) {
    result.isLooping = nil;
  }
  return result;
}
-(NSDictionary*)toMap {
  return [NSDictionary dictionaryWithObjectsAndKeys:(self.textureId ? self.textureId : [NSNull null]), @"textureId", (self.isLooping ? self.isLooping : [NSNull null]), @"isLooping", nil];
}
@end

@implementation FLTVolumeMessage
+(FLTVolumeMessage*)fromMap:(NSDictionary*)dict {
  FLTVolumeMessage* result = [[FLTVolumeMessage alloc] init];
  result.textureId = dict[@"textureId"];
  if ((NSNull *)result.textureId == [NSNull null]) {
    result.textureId = nil;
  }
  result.volume = dict[@"volume"];
  if ((NSNull *)result.volume == [NSNull null]) {
    result.volume = nil;
  }
  return result;
}
-(NSDictionary*)toMap {
  return [NSDictionary dictionaryWithObjectsAndKeys:(self.textureId ? self.textureId : [NSNull null]), @"textureId", (self.volume ? self.volume : [NSNull null]), @"volume", nil];
}
@end

@implementation FLTBrightnessMessage
+(FLTBrightnessMessage*)fromMap:(NSDictionary*)dict {
  FLTBrightnessMessage* result = [[FLTBrightnessMessage alloc] init];
  result.textureId = dict[@"textureId"];
  if ((NSNull *)result.textureId == [NSNull null]) {
    result.textureId = nil;
  }
  result.screenBrightness = dict[@"screenBrightness"];
  if ((NSNull *)result.screenBrightness == [NSNull null]) {
    result.screenBrightness = nil;
  }
  return result;
}
-(NSDictionary*)toMap {
  return [NSDictionary dictionaryWithObjectsAndKeys:(self.textureId ? self.textureId : [NSNull null]), @"textureId", (self.screenBrightness ? self.screenBrightness : [NSNull null]), @"screenBrightness", nil];
}
@end

@implementation FLTPositionMessage
+(FLTPositionMessage*)fromMap:(NSDictionary*)dict {
  FLTPositionMessage* result = [[FLTPositionMessage alloc] init];
  result.textureId = dict[@"textureId"];
  if ((NSNull *)result.textureId == [NSNull null]) {
    result.textureId = nil;
  }
  result.position = dict[@"position"];
  if ((NSNull *)result.position == [NSNull null]) {
    result.position = nil;
  }
  return result;
}
-(NSDictionary*)toMap {
  return [NSDictionary dictionaryWithObjectsAndKeys:(self.textureId ? self.textureId : [NSNull null]), @"textureId", (self.position ? self.position : [NSNull null]), @"position", nil];
}
@end

void FLTVideoPlayerApiSetup(id<FlutterBinaryMessenger> binaryMessenger, id<FLTVideoPlayerApi> api) {
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.initialize"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        [api initialize:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.create"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTCreateMessage *input = [FLTCreateMessage fromMap:message];
        FLTTextureMessage *output = [api create:input error:&error];
        callback(wrapResult([output toMap], error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.dispose"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTTextureMessage *input = [FLTTextureMessage fromMap:message];
        [api dispose:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.setLooping"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTLoopingMessage *input = [FLTLoopingMessage fromMap:message];
        [api setLooping:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.setVolume"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTVolumeMessage *input = [FLTVolumeMessage fromMap:message];
        [api setVolume:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.setBrightness"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTVolumeMessage *input = [FLTVolumeMessage fromMap:message];
        [api setBrightness:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.setSpeed"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTVolumeMessage *input = [FLTVolumeMessage fromMap:message];
        [api setSpeed:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.getBrightness"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTTextureMessage *input = [FLTTextureMessage fromMap:message];
        FLTBrightnessMessage *output = [api getBrightness:input error:&error];
        callback(wrapResult([output toMap], error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.play"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTTextureMessage *input = [FLTTextureMessage fromMap:message];
        [api play:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.prepare"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTTextureMessage *input = [FLTTextureMessage fromMap:message];
        [api prepare:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.stop"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTTextureMessage *input = [FLTTextureMessage fromMap:message];
        [api stop:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.reload"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTTextureMessage *input = [FLTTextureMessage fromMap:message];
        [api reload:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.setScaleMode"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTPositionMessage *input = [FLTPositionMessage fromMap:message];
        [api setScaleMode:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.setMirrorMode"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTPositionMessage *input = [FLTPositionMessage fromMap:message];
        [api setMirrorMode:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.selectTrack"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTPositionMessage *input = [FLTPositionMessage fromMap:message];
        [api selectTrack:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.position"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTTextureMessage *input = [FLTTextureMessage fromMap:message];
        FLTPositionMessage *output = [api position:input error:&error];
        callback(wrapResult([output toMap], error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.seekTo"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTPositionMessage *input = [FLTPositionMessage fromMap:message];
        [api seekTo:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.VideoPlayerApi.pause"
        binaryMessenger:binaryMessenger];
    if (api) {
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTTextureMessage *input = [FLTTextureMessage fromMap:message];
        [api pause:input error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
}

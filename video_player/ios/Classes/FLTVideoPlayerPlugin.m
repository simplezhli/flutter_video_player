// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTVideoPlayerPlugin.h"
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import "messages.h"
#import <AliyunPlayer/AliyunPlayer.h>
#import <libkern/OSAtomic.h>
#import <Photos/Photos.h>

#if !__has_feature(objc_arc)
#error Code Requires ARC.
#endif


@interface FLTFrameUpdater : NSObject
@property(nonatomic) int64_t textureId;
@property(nonatomic, weak, readonly) NSObject<FlutterTextureRegistry>* registry;
- (void)refreshDisplay;
@end

@implementation FLTFrameUpdater
- (FLTFrameUpdater*)initWithRegistry:(NSObject<FlutterTextureRegistry>*)registry {
  NSAssert(self, @"super init cannot be nil");
  if (self == nil) return nil;
  _registry = registry;
  return self;
}

- (void)refreshDisplay {
  [_registry textureFrameAvailable:_textureId];
}
@end

@interface FLTVideoPlayer : NSObject <FlutterTexture, FlutterStreamHandler, AVPDelegate, CicadaRenderDelegate>
@property(readonly, nonatomic) AliPlayer* player;
@property(nonatomic) FlutterEventChannel* eventChannel;
@property(nonatomic) FlutterEventSink eventSink;
@property(nonatomic) FLTFrameUpdater* frameUpdater;
@property(nonatomic, assign) CVPixelBufferRef newPixelBuffer;
@property(nonatomic, assign) CVPixelBufferRef lastestPixelBuffer;
@property(nonatomic, readonly) bool disposed;
@property(nonatomic, readonly) bool isInitialized;
@property(nonatomic, readonly) int64_t bufferedPosition;
@end


@implementation FLTVideoPlayer
- (instancetype)initWithAsset:(NSString*)asset frameUpdater:(FLTFrameUpdater*)frameUpdater {
  NSString* path = [[NSBundle mainBundle] pathForResource:asset ofType:nil];
  return [self initWithURL:[NSURL fileURLWithPath:path] frameUpdater:frameUpdater];
}

- (instancetype)initWithURL:(NSURL*)url frameUpdater:(FLTFrameUpdater*)frameUpdater {
  AVPUrlSource* urlSource = [[AVPUrlSource alloc]init];
  urlSource.playerUrl = url;
  return [self initWithPlayerItem:urlSource frameUpdater:frameUpdater];
}

- (instancetype)initWithPlayerItem:(AVPUrlSource*)source frameUpdater:(FLTFrameUpdater*)frameUpdater {
  self = [super init];
  NSAssert(self, @"super init cannot be nil");
  _isInitialized = false;
  _disposed = false;
  _lastestPixelBuffer = nil;
  _frameUpdater = frameUpdater;
  _player = [[AliPlayer alloc] init];
  _player.delegate = self;
  _player.renderDelegate = self;
  AVPConfig *defaultConfig = [[AVPConfig alloc] init];
  defaultConfig.highBufferDuration = 1000;
  defaultConfig.networkTimeout = 10000;
  defaultConfig.networkRetryCount = 2;
  defaultConfig.clearShowWhenStop = YES;
  defaultConfig.pixelBufferOutputFormat = kCVPixelFormatType_32BGRA;
  [_player setConfig:defaultConfig];
  _player.enableHardwareDecoder = YES;
  //设置播放源
  [_player setUrlSource:source];
  //准备播放
  [_player prepare];
  return self;
}

/**
 @brief 错误代理回调
 @param player 播放器player指针
 @param errorModel 播放器错误描述，参考AliVcPlayerErrorModel
 */
- (void)onError:(AliPlayer*)player errorModel:(AVPErrorModel *)errorModel {
    if (_eventSink != nil) {
      _eventSink([FlutterError
                errorWithCode: [NSString stringWithFormat: @"%lu", (unsigned long)errorModel.code]
                message: errorModel.message
                details: @""]);
    }
}

/**
 @brief 播放器事件回调
 @param player 播放器player指针
 @param eventType 播放器事件类型，@see AVPEventType
 */
-(void)onPlayerEvent:(AliPlayer*)player eventType:(AVPEventType)eventType {
    switch (eventType) {
        case AVPEventPrepareDone: {
            // 准备完成
            [self sendInitialized];
            break;
        }
        case AVPEventCompletion: {
            // 播放完成
            if (_eventSink) {
              _eventSink(@{@"event" : @"completed"});
            }
            break;
        }
        case AVPEventLoadingStart: {
            // 缓冲开始
            if (_eventSink != nil) {
              _eventSink(@{@"event" : @"bufferingStart"});
            }
            break;
        }
        case AVPEventLoadingEnd: {
            // 缓冲完成
            if (_eventSink != nil) {
              _eventSink(@{@"event" : @"bufferingEnd"});
            }
            break;
        }
        default:
            break;
    }
}

/**
 @brief 视频缓存位置回调
 @param player 播放器player指针
 @param position 视频当前缓存位置
 */
- (void)onBufferedPositionUpdate:(AliPlayer*)player position:(int64_t)position {
    // 更新缓冲进度
    if (_eventSink != nil && _bufferedPosition != position) {
      _bufferedPosition = position;
      NSMutableArray<NSArray<NSNumber*>*>* values = [[NSMutableArray alloc] init];
      int64_t start = 0;
      [values addObject:@[ @(start), @(position) ]];
      _eventSink(@{@"event" : @"bufferingUpdate", @"values" : values});
    }
}

- (void)onVideoSizeChanged:(AliPlayer*)player width:(int)width height:(int)height rotation:(int)rotation {
    [_player redraw];
}

- (void)onPlayerStatusChanged:(AliPlayer*)player oldStatus:(AVPStatus)oldStatus newStatus:(AVPStatus)newStatus {
    int state;
    switch (newStatus) {
        case AVPStatusIdle:
            state = 0;
            break;
        case AVPStatusInitialzed:
            state = 1;
            break;
        case AVPStatusPrepared:
            state = 2;
            break;
        case AVPStatusStarted:
            state = 3;
            break;
        case AVPStatusPaused:
            state = 4;
            break;
        case AVPStatusStopped:
            state = 5;
            break;
        case AVPStatusCompletion:
            state = 6;
            break;
        case AVPStatusError:
            state = 7;
            break;
        default:
            state = 8;
            break;
    }
    if (_eventSink != nil) {
        _eventSink(@{@"event" : @"stateChanged", @"state" : @(state)});
    }
    
}

- (void)onLoadingProgress:(AliPlayer*)player progress:(float)progress {
    if (_eventSink != nil) {
        _eventSink(@{@"event" : @"loadingProgress", @"percent" : @(progress), @"kbps" : @(0)});
    }

}

/**
 @brief 获取截图回调
 @param player 播放器player指针
 @param image 图像
 */
- (void)onCaptureScreen:(AliPlayer *)player image:(UIImage *)image {
    // 预览，保存截图
    if (!image) {
      // 截图为空
      return;
    }
    [self saveImage:image];
}

- (void)saveImage:(UIImage *)image {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted) {
        // 因为系统原因, 保存到相册失败
    } else if (status == PHAuthorizationStatusDenied) {
        // 因为系统原因, 保存到相册失败
        [self saveImageHasAuthority:image];
    } else if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                [self saveImageHasAuthority:image];
            }else {
                // 因为系统原因, 保存到相册失败
            }
        }];
    }
}

- (void)saveImageHasAuthority:(UIImage *)image {
    // PHAsset : 一个资源, 比如一张图片\一段视频
    // PHAssetCollection : 一个相簿
    // PHAsset的标识, 利用这个标识可以找到对应的PHAsset对象(图片对象)
    __block NSString *assetLocalIdentifier = nil;
    
    // 如果想对"相册"进行修改(增删改), 那么修改代码必须放在[PHPhotoLibrary sharedPhotoLibrary]的performChanges方法的block中
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // 1.保存图片A到"相机胶卷"中
        // 创建图片的请求
        if (@available(iOS 9.0, *)) {
            assetLocalIdentifier = [PHAssetCreationRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
        }
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success == NO) {
            // 保存图片失败!
            return;
        }
        
        // 2.获得相簿
        PHAssetCollection *createdAssetCollection = [self createdAssetCollection];
        if (createdAssetCollection == nil) {
            // 创建相簿失败!
            return;
        }
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            // 3.添加"相机胶卷"中的图片A到"相簿"D中
            
            // 获得图片
            PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetLocalIdentifier] options:nil].lastObject;
            
            // 添加图片到相簿中的请求
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdAssetCollection];
            
            // 添加图片到相簿
            [request addAssets:@[asset]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success == NO) {
                // 保存图片失败!
            } else {
                //保存图片成功!
            }
        }];
    }];
}

- (PHAssetCollection *)createdAssetCollection {
    // 从已存在相簿中查找这个应用对应的相簿
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *assetCollection in assetCollections) {
        if ([assetCollection.localizedTitle isEqualToString:@"相机胶卷"]) {
            return assetCollection;
        }
    }
    
    // 没有找到对应的相簿, 得创建新的相簿
    
    // 错误信息
    NSError *error = nil;
    
    // PHAssetCollection的标识, 利用这个标识可以找到对应的PHAssetCollection对象(相簿对象)
    __block NSString *assetCollectionLocalIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        // 创建相簿的请求
        assetCollectionLocalIdentifier = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"相机胶卷"].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    
    // 如果有错误信息
    if (error) return nil;
    
    // 获得刚才创建的相簿
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetCollectionLocalIdentifier] options:nil].lastObject;
}

- (void)sendInitialized {
  if (_eventSink && !_isInitialized) {
    int width = _player.width;
    int height = _player.height;

    // The player has not yet initialized.
    if (height == CGSizeZero.height && width == CGSizeZero.width) {
      return;
    }
    // The player may be initialized but still needs to determine the duration.
    if ([self duration] == 0) {
      return;
    }
    
    if ([_player rotation] == 90 || [_player rotation] == 270) {
        width = _player.height;
        height = _player.width;
    }

    _isInitialized = true;
    _eventSink(@{
      @"event" : @"initialized",
      @"duration" : @([self duration]),
      @"width" : @(width),
      @"height" : @(height)
    });
  }
}

- (void)play {
  if (!_isInitialized) {
    return;
  }
  [_player start];
}

- (void)pause {
  if (!_isInitialized) {
    return;
  }
  [_player pause];
}

- (void)prepare {
  [_player prepare];
}

- (void)stop {
  [_player stop];
}

- (void)reload {
  [_player reload];
}

- (void)snapshot {
  [_player snapShot];
}

- (int64_t)position {
  return [_player currentPosition];
}

- (int64_t)duration {
  return [_player duration];
}

- (void)seekTo:(int)location {
  [_player seekToTime:location seekMode:AVP_SEEKMODE_ACCURATE];
}

- (void)setScaleMode:(int)value {
    switch (value) {
        case 1:
            _player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFILL;
            break;
        case 2:
            _player.scalingMode = AVP_SCALINGMODE_SCALETOFILL;
            break;
        default:
            _player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFIT;
            break;
    }
}

- (void)setMirrorMode:(int)value {
    switch (value) {
        case 1:
            _player.mirrorMode = AVP_MIRRORMODE_HORIZONTAL;
            break;
        case 2:
            _player.mirrorMode = AVP_MIRRORMODE_VERTICAL;
            break;
        default:
            _player.mirrorMode = AVP_MIRRORMODE_NONE;
            break;
    }
}

- (void)setIsLooping:(bool)isLooping {
  _player.loop = isLooping;
}

- (void)setVolume:(double)volume {
  _player.volume = (float)((volume < 0.0) ? 0.0 : ((volume > 1.0) ? 1.0 : volume));
}

- (void)setSpeed:(double)speed {
  _player.rate = (float)((speed < 0.0) ? 0.5 : ((speed > 2.0) ? 2.0 : speed));
}

- (BOOL)onVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer pts:(int64_t)pts {
  _newPixelBuffer = pixelBuffer;
  [_frameUpdater refreshDisplay];
  return NO;
}

- (BOOL)onVideoRawBuffer:(uint8_t **)buffer lineSize:(int32_t *)lineSize pts:(int64_t)pts width:(int32_t)width height:(int32_t)height {
   return NO;
}

- (CVPixelBufferRef)copyPixelBuffer {
  if(_newPixelBuffer != nil){
      //参考 https://github.com/RandyWei/flt_video_player
      CVPixelBufferRetain(_newPixelBuffer);
      CVPixelBufferRef pixelBuffer = _lastestPixelBuffer;
      while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, _newPixelBuffer, (void **) &_lastestPixelBuffer)) {
          pixelBuffer = _lastestPixelBuffer;
      }
      return pixelBuffer;
  }
  return NULL;
}

- (void)onTextureUnregistered {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self dispose];
  });
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
  _eventSink = nil;
  return nil;
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
  _eventSink = events;
  return nil;
}

/// This method allows you to dispose without touching the event channel.  This
/// is useful for the case where the Engine is in the process of deconstruction
/// so the channel is going to die or is already dead.
- (void)disposeSansEventChannel {
  _disposed = true;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dispose {
  if (_player) {
    [_player stop];
    [_player destroy];
    _player = nil;
  }
  [self disposeSansEventChannel];
  [_eventChannel setStreamHandler:nil];
  
  [self releaseLatestPixelBuffer];
}

- (void)releaseLatestPixelBuffer {
  if (_lastestPixelBuffer) {
    CFAutorelease(_lastestPixelBuffer);
  }
}

@end

@interface FLTVideoPlayerPlugin () <FLTVideoPlayerApi>
@property(readonly, weak, nonatomic) NSObject<FlutterTextureRegistry>* registry;
@property(readonly, weak, nonatomic) NSObject<FlutterBinaryMessenger>* messenger;
@property(readonly, strong, nonatomic) NSMutableDictionary* players;
@property(readonly, strong, nonatomic) NSObject<FlutterPluginRegistrar>* registrar;
@end

@implementation FLTVideoPlayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FLTVideoPlayerPlugin* instance = [[FLTVideoPlayerPlugin alloc] initWithRegistrar:registrar];
  [registrar publish:instance];
  FLTVideoPlayerApiSetup(registrar.messenger, instance);
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  self = [super init];
  NSAssert(self, @"super init cannot be nil");
  _registry = [registrar textures];
  _messenger = [registrar messenger];
  _registrar = registrar;
  _players = [NSMutableDictionary dictionaryWithCapacity:1];
  return self;
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  for (NSNumber* textureId in _players.allKeys) {
    FLTVideoPlayer* player = _players[textureId];
    [player disposeSansEventChannel];
  }
  [_players removeAllObjects];
  // TODO(57151): This should be commented out when 57151's fix lands on stable.
  // This is the correct behavior we never did it in the past and the engine
  // doesn't currently support it.
  // FLTVideoPlayerApiSetup(registrar.messenger, nil);
}

- (FLTTextureMessage*)onPlayerSetup:(FLTVideoPlayer*)player
                       frameUpdater:(FLTFrameUpdater*)frameUpdater {
  int64_t textureId = [_registry registerTexture:player];
  frameUpdater.textureId = textureId;
  FlutterEventChannel* eventChannel = [FlutterEventChannel
      eventChannelWithName:[NSString stringWithFormat:@"flutter.io/videoPlayer/videoEvents%lld",
                                                      textureId]
           binaryMessenger:_messenger];
  [eventChannel setStreamHandler:player];
  player.eventChannel = eventChannel;
  _players[@(textureId)] = player;
  FLTTextureMessage* result = [[FLTTextureMessage alloc] init];
  result.textureId = @(textureId);
  return result;
}

- (void)initialize:(FlutterError* __autoreleasing*)error {
  // Allow audio playback when the Ring/Silent switch is set to silent
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

  for (NSNumber* textureId in _players) {
    [_registry unregisterTexture:[textureId unsignedIntegerValue]];
    [_players[textureId] dispose];
  }
  [_players removeAllObjects];
}

- (FLTTextureMessage*)create:(FLTCreateMessage*)input error:(FlutterError**)error {
  FLTFrameUpdater* frameUpdater = [[FLTFrameUpdater alloc] initWithRegistry:_registry];
  FLTVideoPlayer* player;
  if (input.asset) {
    NSString* assetPath;
    if (input.packageName) {
      assetPath = [_registrar lookupKeyForAsset:input.asset fromPackage:input.packageName];
    } else {
      assetPath = [_registrar lookupKeyForAsset:input.asset];
    }
    player = [[FLTVideoPlayer alloc] initWithAsset:assetPath frameUpdater:frameUpdater];
    return [self onPlayerSetup:player frameUpdater:frameUpdater];
  } else if (input.uri) {
    player = [[FLTVideoPlayer alloc] initWithURL:[NSURL URLWithString:input.uri]
                                    frameUpdater:frameUpdater];
    return [self onPlayerSetup:player frameUpdater:frameUpdater];
  } else {
    *error = [FlutterError errorWithCode:@"video_player" message:@"not implemented" details:nil];
    return nil;
  }
}

- (void)dispose:(FLTTextureMessage*)input error:(FlutterError**)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [_registry unregisterTexture:input.textureId.intValue];
  [_players removeObjectForKey:input.textureId];
  // If the Flutter contains https://github.com/flutter/engine/pull/12695,
  // the `player` is disposed via `onTextureUnregistered` at the right time.
  // Without https://github.com/flutter/engine/pull/12695, there is no guarantee that the
  // texture has completed the un-reregistration. It may leads a crash if we dispose the
  // `player` before the texture is unregistered. We add a dispatch_after hack to make sure the
  // texture is unregistered before we dispose the `player`.
  //
  // TODO(cyanglaz): Remove this dispatch block when
  // https://github.com/flutter/flutter/commit/8159a9906095efc9af8b223f5e232cb63542ad0b is in
  // stable And update the min flutter version of the plugin to the stable version.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   if (!player.disposed) {
                     [player dispose];
                   }
                 });
}

- (void)setLooping:(FLTLoopingMessage*)input error:(FlutterError**)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player setIsLooping:[input.isLooping boolValue]];
}

- (void)setVolume:(FLTVolumeMessage*)input error:(FlutterError**)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player setVolume:[input.volume doubleValue]];
}

- (void)play:(FLTTextureMessage*)input error:(FlutterError**)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player play];
}

- (FLTPositionMessage*)position:(FLTTextureMessage*)input error:(FlutterError**)error {
  FLTVideoPlayer* player = _players[input.textureId];
  FLTPositionMessage* result = [[FLTPositionMessage alloc] init];
  result.position = @([player position]);
  return result;
}

- (void)seekTo:(FLTPositionMessage*)input error:(FlutterError**)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player seekTo:[input.position intValue]];
}

- (void)pause:(FLTTextureMessage*)input error:(FlutterError**)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player pause];
}

- (void)setBrightness:(FLTVolumeMessage*)input error:(FlutterError**)error {
  [UIScreen mainScreen].brightness = [input.volume doubleValue];
}

- (void)setSpeed:(FLTVolumeMessage*)input error:(FlutterError**)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player setSpeed:[input.volume doubleValue]];
}

- (FLTBrightnessMessage*)getBrightness:(FLTTextureMessage*)input error:(FlutterError**)error {
  FLTBrightnessMessage* result = [[FLTBrightnessMessage alloc] init];
  result.screenBrightness = @([UIScreen mainScreen].brightness);
  return result;
}

- (void)prepare:(FLTTextureMessage*)input error:(FlutterError *_Nullable *_Nonnull)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player prepare];
}

- (void)stop:(FLTTextureMessage*)input error:(FlutterError *_Nullable *_Nonnull)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player stop];
}

- (void)reload:(FLTTextureMessage*)input error:(FlutterError *_Nullable *_Nonnull)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player reload];
}

- (void)snapshot:(FLTTextureMessage*)input error:(FlutterError *_Nullable *_Nonnull)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player snapshot];
}
- (void)setScaleMode:(FLTPositionMessage*)input error:(FlutterError *_Nullable *_Nonnull)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player setScaleMode:[input.position intValue]];
}
- (void)setMirrorMode:(FLTPositionMessage*)input error:(FlutterError *_Nullable *_Nonnull)error {
  FLTVideoPlayer* player = _players[input.textureId];
  [player setMirrorMode:[input.position intValue]];
}

- (void)selectTrack:(FLTPositionMessage*)input error:(FlutterError *_Nullable *_Nonnull)error {
    
}
@end

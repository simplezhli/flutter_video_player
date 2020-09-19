// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.res.Resources;
import android.provider.Settings;
import android.util.Log;
import android.util.LongSparseArray;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugins.videoplayer.Messages.CreateMessage;
import io.flutter.plugins.videoplayer.Messages.LoopingMessage;
import io.flutter.plugins.videoplayer.Messages.PositionMessage;
import io.flutter.plugins.videoplayer.Messages.TextureMessage;
import io.flutter.plugins.videoplayer.Messages.VideoPlayerApi;
import io.flutter.plugins.videoplayer.Messages.VolumeMessage;
import io.flutter.view.FlutterMain;
import io.flutter.view.TextureRegistry;

/** Android platform implementation of the VideoPlayerPlugin. */
public class VideoPlayerPlugin implements FlutterPlugin, VideoPlayerApi, ActivityAware {
  private static final String TAG = "VideoPlayerPlugin";
  private final LongSparseArray<VideoPlayer> videoPlayers = new LongSparseArray<>();
  private FlutterState flutterState;

  private FlutterPluginBinding pluginBinding;
  private ActivityPluginBinding activityBinding;
  /** Register this with the v2 embedding for the plugin to respond to lifecycle callbacks. */
  public VideoPlayerPlugin() {}

  private VideoPlayerPlugin(Registrar registrar) {
    this.flutterState =
        new FlutterState(
            registrar.context(),
            registrar.activity(),
            registrar.messenger(),
            registrar::lookupKeyForAsset,
            registrar::lookupKeyForAsset,
            registrar.textures());
    flutterState.startListening(this, registrar.messenger());
  }

  /** Registers this with the stable v1 embedding. Will not respond to lifecycle events. */
  public static void registerWith(Registrar registrar) {
    final VideoPlayerPlugin plugin = new VideoPlayerPlugin(registrar);
    registrar.addViewDestroyListener(
        view -> {
          plugin.onDestroy();
          return false; // We are not interested in assuming ownership of the NativeView.
        });
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    pluginBinding = binding;
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    if (flutterState == null) {
      Log.wtf(TAG, "Detached from the engine before registering to it.");
    }
    flutterState.stopListening(binding.getBinaryMessenger());
    flutterState = null;
    pluginBinding = null;
  }

  private void disposeAllPlayers() {
    for (int i = 0; i < videoPlayers.size(); i++) {
      videoPlayers.valueAt(i).dispose();
    }
    videoPlayers.clear();
  }

  private void onDestroy() {
    // The whole FlutterView is being destroyed. Here we release resources acquired for all
    // instances
    // of VideoPlayer. Once https://github.com/flutter/flutter/issues/19358 is resolved this may
    // be replaced with just asserting that videoPlayers.isEmpty().
    // https://github.com/flutter/flutter/issues/20989 tracks this.
    disposeAllPlayers();
  }

  public void initialize() {
    disposeAllPlayers();
  }

  public TextureMessage create(CreateMessage arg) {
    TextureRegistry.SurfaceTextureEntry handle =
        flutterState.textureRegistry.createSurfaceTexture();
    EventChannel eventChannel =
        new EventChannel(
            flutterState.binaryMessenger, "flutter.io/videoPlayer/videoEvents" + handle.id());

    VideoPlayer player;
    if (arg.getAsset() != null) {
      String assetLookupKey;
      if (arg.getPackageName() != null) {
        assetLookupKey =
            flutterState.keyForAssetAndPackageName.get(arg.getAsset(), arg.getPackageName());
      } else {
        assetLookupKey = flutterState.keyForAsset.get(arg.getAsset());
      }
      player =
          new VideoPlayer(
              flutterState.applicationContext,
              eventChannel,
              handle,
              "asset:///" + assetLookupKey,
              null);
    } else {
      player =
          new VideoPlayer(
              flutterState.applicationContext,
              eventChannel,
              handle,
              arg.getUri(),
              arg.getFormatHint());
    }
    videoPlayers.put(handle.id(), player);

    TextureMessage result = new TextureMessage();
    result.setTextureId(handle.id());
    return result;
  }

  @Override
  public void dispose(TextureMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.dispose();
    videoPlayers.remove(arg.getTextureId());
  }

  @Override
  public void setLooping(LoopingMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.setLooping(arg.getIsLooping());
  }

  @Override
  public void setVolume(VolumeMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.setVolume(arg.getVolume());
  }
  
  @Override
  public void setSpeed(VolumeMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.setSpeed(arg.getVolume());
  }

  @Override
  public void setBrightness(VolumeMessage arg) {
    float brightness = Float.parseFloat(arg.getVolume().toString());
    Window window = flutterState.activity.getWindow();
    WindowManager.LayoutParams lp = window.getAttributes();
    if (brightness < 0 || brightness > 1) {
      lp.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE;
    } else {
      lp.screenBrightness = brightness;
    }
    window.setAttributes(lp);
  }

  @Override
  public Messages.BrightnessMessage getBrightness(TextureMessage arg) {
    ContentResolver cr = flutterState.activity.getContentResolver();
    int systemBrightness = Settings.System.getInt(cr, Settings.System.SCREEN_BRIGHTNESS,0);
    
    Messages.BrightnessMessage result = new Messages.BrightnessMessage();
    result.setScreenBrightness((double) (systemBrightness / getBrightnessMax()));
    return result;
  }

  // https://blog.csdn.net/jklwan/article/details/93669170
  private float getBrightnessMax() {
    try {
      Resources system = Resources.getSystem();
      int resId = system.getIdentifier("config_screenBrightnessSettingMaximum", "integer", "android");
      if (resId != 0) {
        return system.getInteger(resId);
      }
    }catch (Exception ignore){
      
    }
    return 255f;
  }

  @Override
  public void prepare(TextureMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.prepare();
  }

  @Override
  public void play(TextureMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.play();
  }

  @Override
  public void stop(TextureMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.stop();
  }

  @Override
  public void reload(TextureMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.reload();
  }
  
  @Override
  public void snapshot(TextureMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.snapshot();
  }

  @Override
  public void setScaleMode(PositionMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.setScaleMode(arg.getPosition().intValue());
  }

  @Override
  public void setMirrorMode(PositionMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.setMirrorMode(arg.getPosition().intValue());
  }

  @Override
  public void selectTrack(PositionMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.selectTrack(arg.getPosition().intValue());
  }

  public PositionMessage position(TextureMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    PositionMessage result = new PositionMessage();
    result.setPosition(player.getPosition());
//    player.sendBufferingUpdate();
    return result;
  }

  public void seekTo(PositionMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.seekTo(arg.getPosition().intValue());
  }

  public void pause(TextureMessage arg) {
    VideoPlayer player = videoPlayers.get(arg.getTextureId());
    player.pause();
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activityBinding = binding;
    this.flutterState =
            new FlutterState(
                    pluginBinding.getApplicationContext(),
                    activityBinding.getActivity(),
                    pluginBinding.getBinaryMessenger(),
                    FlutterMain::getLookupKeyForAsset,
                    FlutterMain::getLookupKeyForAsset,
                    pluginBinding.getTextureRegistry());
    flutterState.startListening(this, pluginBinding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    activityBinding = null;
  }

  private interface KeyForAssetFn {
    String get(String asset);
  }

  private interface KeyForAssetAndPackageName {
    String get(String asset, String packageName);
  }

  private static final class FlutterState {
    private final Context applicationContext;
    private final Activity activity;
    private final BinaryMessenger binaryMessenger;
    private final KeyForAssetFn keyForAsset;
    private final KeyForAssetAndPackageName keyForAssetAndPackageName;
    private final TextureRegistry textureRegistry;

    FlutterState(
        Context applicationContext,
        Activity activity,
        BinaryMessenger messenger,
        KeyForAssetFn keyForAsset,
        KeyForAssetAndPackageName keyForAssetAndPackageName,
        TextureRegistry textureRegistry) {
      this.applicationContext = applicationContext;
      this.activity = activity;
      this.binaryMessenger = messenger;
      this.keyForAsset = keyForAsset;
      this.keyForAssetAndPackageName = keyForAssetAndPackageName;
      this.textureRegistry = textureRegistry;
    }

    void startListening(VideoPlayerPlugin methodCallHandler, BinaryMessenger messenger) {
      VideoPlayerApi.setup(messenger, methodCallHandler);
    }

    void stopListening(BinaryMessenger messenger) {
      VideoPlayerApi.setup(messenger, null);
    }
  }
}

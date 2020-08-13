package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.net.Uri;
import android.view.Surface;

import com.aliyun.player.AliPlayer;
import com.aliyun.player.AliPlayerFactory;
import com.aliyun.player.IPlayer;
import com.aliyun.player.bean.ErrorInfo;
import com.aliyun.player.bean.InfoBean;
import com.aliyun.player.bean.InfoCode;
import com.aliyun.player.source.UrlSource;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.view.TextureRegistry;

final class VideoPlayer {
  private static final String FORMAT_SS = "ss";
  private static final String FORMAT_DASH = "dash";
  private static final String FORMAT_HLS = "hls";
  private static final String FORMAT_OTHER = "other";

  private AliPlayer aliyunVodPlayer;

  private Surface surface;

  private final TextureRegistry.SurfaceTextureEntry textureEntry;

  private QueuingEventSink eventSink = new QueuingEventSink();

  private final EventChannel eventChannel;
  private long mCurrentPosition;
  private long mVideoBufferedPosition;
  private boolean isInitialized = false;

  VideoPlayer(
      Context context,
      EventChannel eventChannel,
      TextureRegistry.SurfaceTextureEntry textureEntry,
      String dataSource,
      String formatHint) {
    this.eventChannel = eventChannel;
    this.textureEntry = textureEntry;
    mCurrentPosition = 0;
    mVideoBufferedPosition = 0;
    aliyunVodPlayer = AliPlayerFactory.createAliPlayer(context.getApplicationContext());
    
//    //设置播放器参数
//    PlayerConfig config = aliyunVodPlayer.getConfig();
//    //停止之后清空画面。防止画面残留（建议设置）
//    config.mClearFrameWhenStop = true;
//    aliyunVodPlayer.setConfig(config);

    Uri uri = Uri.parse(dataSource);

    UrlSource urlSource = new UrlSource();
    urlSource.setUri(dataSource);
    aliyunVodPlayer.setDataSource(urlSource);

    setupVideoPlayer(eventChannel, textureEntry);
    //准备播放
    aliyunVodPlayer.prepare();
  }

  private void setupVideoPlayer(EventChannel eventChannel, TextureRegistry.SurfaceTextureEntry textureEntry) {

    eventChannel.setStreamHandler(
        new EventChannel.StreamHandler() {
          @Override
          public void onListen(Object o, EventChannel.EventSink sink) {
            eventSink.setDelegate(sink);
          }

          @Override
          public void onCancel(Object o) {
            eventSink.setDelegate(null);
          }
        });
    SurfaceTexture surfaceTexture = textureEntry.surfaceTexture();
    surface = new Surface(surfaceTexture);
    aliyunVodPlayer.setSurface(surface);
    
    aliyunVodPlayer.setOnVideoSizeChangedListener(new IPlayer.OnVideoSizeChangedListener() {
      @Override
      public void onVideoSizeChanged(int width, int height) {
        textureEntry.surfaceTexture().setDefaultBufferSize(width, height);
        // 视频宽高变化通知
        aliyunVodPlayer.redraw();
      }
    });
    aliyunVodPlayer.setOnPreparedListener(new IPlayer.OnPreparedListener() {
      @Override
      public void onPrepared() {
        //准备成功事件
        if (!isInitialized) {
          isInitialized = true;
          sendInitialized();
        }
      }
    });
    aliyunVodPlayer.setOnCompletionListener(new IPlayer.OnCompletionListener() {
      @Override
      public void onCompletion() {
        //播放完成事件
        Map<String, Object> event = new HashMap<>();
        event.put("event", "completed");
        eventSink.success(event);
      }
    });
    aliyunVodPlayer.setOnStateChangedListener(new IPlayer.OnStateChangedListener() {
      @Override
      public void onStateChanged(int newState) {
        //播放器状态改变事件
        
      }
    });
    aliyunVodPlayer.setOnLoadingStatusListener(new IPlayer.OnLoadingStatusListener() {
      @Override
      public void onLoadingBegin() {
        Map<String, Object> event = new HashMap<>();
        event.put("event", "loadingBegin");
        eventSink.success(event);
      }

      @Override
      public void onLoadingProgress(int percent, float kbps) {
        Map<String, Object> event = new HashMap<>();
        event.put("event", "loadingProgress");
        event.put("percent", percent);
        event.put("kbps", kbps);
        eventSink.success(event);
      }

      @Override
      public void onLoadingEnd() {
        Map<String, Object> event = new HashMap<>();
        event.put("event", "loadingEnd");
        eventSink.success(event);
      }
    });
    aliyunVodPlayer.setOnErrorListener(new IPlayer.OnErrorListener() {
      @Override
      public void onError(ErrorInfo errorInfo) {
        //出错事件
        if (eventSink != null && errorInfo != null) {
          eventSink.error(errorInfo.getCode() + "", errorInfo.getMsg(), errorInfo.getExtra());
        }
      }
    });
    aliyunVodPlayer.setOnInfoListener(new IPlayer.OnInfoListener() {
      @Override
      public void onInfo(InfoBean infoBean) {
        if (infoBean.getCode() == InfoCode.BufferedPosition) {
          //更新bufferedPosition
          mVideoBufferedPosition = (int) infoBean.getExtraValue();
          sendBufferingUpdate();
        } else if (infoBean.getCode() == InfoCode.CurrentPosition) {
          //更新currentPosition
          mCurrentPosition = infoBean.getExtraValue();
        }
      }
    });
  }

  void sendBufferingUpdate() {
    Map<String, Object> event = new HashMap<>();
    event.put("event", "bufferingUpdate");
    List<? extends Number> range = Arrays.asList(0, mVideoBufferedPosition);
    // iOS supports a list of buffered ranges, so here is a list with a single range.
    event.put("values", Collections.singletonList(range));
    eventSink.success(event);
  }

  void play() {
    aliyunVodPlayer.start();
  }

  void pause() {
    aliyunVodPlayer.pause();
  }

  void setLooping(boolean value) {
    aliyunVodPlayer.setLoop(value);
  }

  void setVolume(double value) {
    float bracketedValue = (float) Math.max(0.0, Math.min(1.0, value));
    aliyunVodPlayer.setVolume(bracketedValue);
  }

  void seekTo(int location) {
    aliyunVodPlayer.seekTo(location);
  }

  long getPosition() {
    return mCurrentPosition;
  }

  private void sendInitialized() {
    if (isInitialized) {
      Map<String, Object> event = new HashMap<>();
      event.put("event", "initialized");
      event.put("duration", aliyunVodPlayer.getDuration());

      int width = aliyunVodPlayer.getVideoWidth();
      int height = aliyunVodPlayer.getVideoHeight();
      int rotationDegrees = aliyunVodPlayer.getVideoRotation();
      // Switch the width/height if video was taken in portrait mode
      if (rotationDegrees == 90 || rotationDegrees == 270) {
        width = aliyunVodPlayer.getVideoHeight();
        height = aliyunVodPlayer.getVideoWidth();
      }
      event.put("width", width);
      event.put("height", height);
      eventSink.success(event);
    }
  }

  void dispose() {
    if (isInitialized) {
      aliyunVodPlayer.stop();
    }
    textureEntry.release();
    eventChannel.setStreamHandler(null);
    
    if (aliyunVodPlayer != null) {
      aliyunVodPlayer.stop();
      aliyunVodPlayer.setSurface(null);
      aliyunVodPlayer.release();
      aliyunVodPlayer = null;
    }
    if (surface != null) {
      surface.release();
      surface = null;
    }
  }
}

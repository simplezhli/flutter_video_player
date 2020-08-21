package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.media.MediaScannerConnection;
import android.os.Build;
import android.view.Surface;

import com.aliyun.player.AliPlayer;
import com.aliyun.player.AliPlayerFactory;
import com.aliyun.player.IPlayer;
import com.aliyun.player.bean.ErrorCode;
import com.aliyun.player.bean.ErrorInfo;
import com.aliyun.player.bean.InfoBean;
import com.aliyun.player.bean.InfoCode;
import com.aliyun.player.nativeclass.MediaInfo;
import com.aliyun.player.nativeclass.PlayerConfig;
import com.aliyun.player.nativeclass.TrackInfo;
import com.aliyun.player.source.UrlSource;

import java.io.File;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.Log;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.videoplayer.utils.FileUtils;
import io.flutter.plugins.videoplayer.utils.ThreadUtils;
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
    
    //设置播放器参数
    PlayerConfig config = aliyunVodPlayer.getConfig();
    //停止之后清空画面。防止画面残留（建议设置）
    config.mClearFrameWhenStop = true;
    config.mNetworkTimeout = 10000;
    config.mNetworkRetryCount = 2;
    //高缓冲时长。单位ms。当网络不好导致加载数据时，如果加载的缓冲时长到达这个值，结束加载状态。
    config.mHighBufferDuration = 1000;
    aliyunVodPlayer.setConfig(config);

//    CacheConfig cacheConfig = new CacheConfig();
//    //开启缓存功能
//    cacheConfig.mEnable = true;
//    //能够缓存的单个文件最大时长。超过此长度则不缓存
//    cacheConfig.mMaxDurationS = 3600;
//    //缓存目录的位置(/storage/emulated/0/Android/data/包名/files/Media/cache/)
//    cacheConfig.mDir = getDir(context) + "cache" + File.separator;
//    //缓存目录的最大大小。超过此大小，将会删除最旧的缓存文件
//    cacheConfig.mMaxSizeMB = 200;
//    //设置缓存配置给到播放器
//    aliyunVodPlayer.setCacheConfig(cacheConfig);

    UrlSource urlSource = new UrlSource();
    urlSource.setUri(dataSource);
    aliyunVodPlayer.setDataSource(urlSource);

    setupVideoPlayer(eventChannel, textureEntry, context);
    //准备播放
    prepare();
  }

  private void setupVideoPlayer(EventChannel eventChannel, TextureRegistry.SurfaceTextureEntry textureEntry, Context context) {

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
        Log.d("java:", "-----------" + width + "----------" + height);
        textureEntry.surfaceTexture().setDefaultBufferSize(width, height);
        // 视频宽高变化通知
        if (aliyunVodPlayer == null) {
          return;
        }
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
        Map<String, Object> event = new HashMap<>();
        event.put("event", "stateChanged");
        event.put("state", newState);
        eventSink.success(event);
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
          String errorMsg;
          if (errorInfo.getCode().getValue() == ErrorCode.ERROR_LOADING_TIMEOUT.getValue()) {
            errorMsg = "加载超时";
          } else if (errorInfo.getCode().getValue() == ErrorCode.ERROR_NETWORK_CONNECT_TIMEOUT.getValue()) {
            errorMsg = "网络连接超时";
          } else if (errorInfo.getCode().getValue() == ErrorCode.ERROR_NETWORK_COULD_NOT_CONNECT.getValue()) {
            errorMsg = "无法连接到服务器";
          } else if (errorInfo.getCode().getValue() == ErrorCode.ERROR_SERVER_VOD_INVALIDVIDEO_NOSTREAM.getValue()) {
            errorMsg = "网络连接错误";
          } else {
            errorMsg = errorInfo.getMsg();
          }
          
          eventSink.error(errorInfo.getCode().getValue() + "", errorMsg, errorInfo.getExtra());
        }
      }
    });
    aliyunVodPlayer.setOnInfoListener(new IPlayer.OnInfoListener() {
      @Override
      public void onInfo(InfoBean infoBean) {
        if (infoBean.getCode() == InfoCode.BufferedPosition) {
          //更新bufferedPosition
          if (mVideoBufferedPosition != (int) infoBean.getExtraValue()) {
            mVideoBufferedPosition = (int) infoBean.getExtraValue();
            sendBufferingUpdate();
          }
        } else if (infoBean.getCode() == InfoCode.CurrentPosition) {
          //更新currentPosition
          mCurrentPosition = infoBean.getExtraValue();
        } else if (infoBean.getCode() == InfoCode.NetworkRetry) {
          eventSink.error(infoBean.getCode() + "", "加载超时", infoBean.getExtraMsg());
        }
      }
    });
    
    //截图回调
    aliyunVodPlayer.setOnSnapShotListener(new IPlayer.OnSnapShotListener(){
      @Override
      public void onSnapShot(Bitmap bitmap, int with, int height){
        //获取到的bitmap。以及图片的宽高。
        ThreadUtils.runOnSubThread(new Runnable() {
          @Override
          public void run() {
            String videoPath = FileUtils.getDir(context) + "snapShot" + File.separator;
            String bitmapPath = FileUtils.saveBitmap(bitmap, videoPath);

            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
              FileUtils.saveImgToMediaStore(context.getApplicationContext(), bitmapPath,"image/png");
            } else {
              MediaScannerConnection.scanFile(context.getApplicationContext(),
                      new String[] {bitmapPath},
                      new String[] {"image/png"}, null);
            }

            ThreadUtils.runOnUiThread(new Runnable() {
              @Override
              public void run() {
                Map<String, Object> event = new HashMap<>();
                event.put("event", "snapshot");
                event.put("filePath", bitmapPath);
                eventSink.success(event);
              }
            });
          }
        });
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
  
  void prepare() {
    if (aliyunVodPlayer == null) {
      return;
    }
    aliyunVodPlayer.prepare();
  }

  void play() {
    if (aliyunVodPlayer == null) {
      return;
    }
    aliyunVodPlayer.start();
  }

  void pause() {
    if (aliyunVodPlayer == null) {
      return;
    }
    aliyunVodPlayer.pause();
  }

  void stop() {
    if (aliyunVodPlayer == null) {
      return;
    }
    aliyunVodPlayer.stop();
  }

  void reload() {
    if (aliyunVodPlayer == null) {
      return;
    }
    aliyunVodPlayer.reload();
  }

  void setLooping(boolean value) {
    if (aliyunVodPlayer == null) {
      return;
    }
    aliyunVodPlayer.setLoop(value);
  }
  
  //设置倍速播放:支持0.5~2倍速的播放
  void setSpeed(double value) {
    if (aliyunVodPlayer == null) {
      return;
    }
    float bracketedValue = (float) Math.max(0.5, Math.min(2.0, value));
    aliyunVodPlayer.setSpeed(bracketedValue);;
  }

  void setScaleMode(int value) {
    if (aliyunVodPlayer == null) {
      return;
    }
    
    IPlayer.ScaleMode scaleMode;
    if (value == 1) {
      // 填充（将按照视频宽高比等比放大，充满view，不会有画面变形）
      scaleMode = IPlayer.ScaleMode.SCALE_ASPECT_FILL;
    } else if (value == 2) {
      // 拉伸（如果视频宽高比例与view比例不一致，会导致画面变形）
      scaleMode = IPlayer.ScaleMode.SCALE_TO_FILL;
    } else {
      // 宽高比适应（将按照视频宽高比等比缩小到view内部，不会有画面变形）
      scaleMode = IPlayer.ScaleMode.SCALE_ASPECT_FIT;
    }
    aliyunVodPlayer.setScaleMode(scaleMode);
  }

  void setMirrorMode(int value) {
    if (aliyunVodPlayer == null) {
      return;
    }

    IPlayer.MirrorMode mirrorMode;
    if (value == 1) {
      // 水平镜像
      mirrorMode = IPlayer.MirrorMode.MIRROR_MODE_HORIZONTAL;
    } else if (value == 2) {
      // 垂直镜像
      mirrorMode = IPlayer.MirrorMode.MIRROR_MODE_VERTICAL;
    } else {
      // 无镜像
      mirrorMode = IPlayer.MirrorMode.MIRROR_MODE_NONE;
    }
    
    aliyunVodPlayer.setMirrorMode(mirrorMode);
  }

  void selectTrack(int value) {
    if (aliyunVodPlayer == null) {
      return;
    }
    aliyunVodPlayer.selectTrack(value);
  }

  void setVolume(double value) {
    if (aliyunVodPlayer == null) {
      return;
    }
    float bracketedValue = (float) Math.max(0.0, Math.min(1.0, value));
    aliyunVodPlayer.setVolume(bracketedValue);
  }

  void seekTo(int location) {
    if (aliyunVodPlayer == null) {
      return;
    }
    mCurrentPosition = location;
    aliyunVodPlayer.seekTo(location, IPlayer.SeekMode.Accurate);
  }

  void snapshot() {
    if (aliyunVodPlayer == null) {
      return;
    }
    aliyunVodPlayer.snapshot();
  }
  
  long getPosition() {
    return mCurrentPosition;
  }

  private void sendInitialized() {
    if (isInitialized) {
      Map<String, Object> event = new HashMap<>();
      MediaInfo mediaInfo = aliyunVodPlayer.getMediaInfo();
      if (mediaInfo != null) {
        List<TrackInfo> trackInfos  = mediaInfo.getTrackInfos();
        for (TrackInfo info : trackInfos) {
          if (info.getType() == TrackInfo.Type.TYPE_VOD) {
            /// 清晰度
            // TODO 暂时未实现
            Log.d("java:", "-----------" + info.getVodDefinition());
            int index = info.getIndex();
          }
        }
      }
     
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

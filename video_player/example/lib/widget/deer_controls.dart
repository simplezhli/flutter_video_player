
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';
import 'package:video_player_example/widget/bottom_bar.dart';
import 'package:video_player_example/widget/gesture_dialog.dart';
import 'package:video_player_example/widget/seek_dialog.dart';
import 'package:video_player_example/widget/tips_view.dart';

class DeerControls extends StatefulWidget {

  const DeerControls({Key key}) : super(key: key);
  
  @override
  _DeerControlsState createState() => _DeerControlsState();
}

class _DeerControlsState extends State<DeerControls> with SingleTickerProviderStateMixin {

  VideoPlayerController controller;
  ChewieController chewieController;
  AnimationController animationController;

  VideoPlayerValue _latestValue;
  /// 用于显示拖动进度条时的时间提示框
  bool _progressBarDragging = false;
  /// 用于显示音量提示框
  bool _volumeDragging = false;
  /// 用于显示亮度提示框
  bool _brightnessDragging = false;
 
  /// 手势起始点
  Offset _initialOffset;
  /// 记录进度调节位置
  Duration _position;
  /// 用于进度与音量调节
  Duration _currentPosition;
  double _currentVolume;
  double _currentBrightness;

  Timer _initTimer;
  /// 底部操作条显示时间倒计时
  Timer _hideTimer;
  /// 底部操作条是否显示
  bool _hideStuff = true;
  /// 是否锁屏
  bool _isLock = false;
  
  String _filePath;
  
  @override
  void initState() {
    if (animationController == null) {
      animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
        reverseDuration: Duration(milliseconds: 300),
      );
    }
    super.initState();
  }

  @override
  void dispose() {
    _dispose(controller);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    animationController?.dispose();
    super.dispose();
  }

  void _dispose(VideoPlayerController controller) {
    controller?.removeListener(_updateState);
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose(_oldController?.videoPlayerController);
      _initialize();
    }

    super.didChangeDependencies();
  }

  void _initialize() {
    controller?.addListener(_updateState);
    _updateState();

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
        _startHideTimer();
      });
    }
  }

  void _updateState() {
    _latestValue = controller.value;
    if ((controller.value != null && controller.value.isPlaying)) {
      animationController.forward();

    } else {
      if (!controller.value.initialized) {
        if (chewieController.autoPlay) {
          animationController.forward();
        }
      } else {
        animationController.reverse();
      }
    }
    
    if (_latestValue.filePath != _filePath && chewieController.isFullScreen) {
      /// 截图刷新
      _filePath = _latestValue.filePath;
      setState(() {
        
      });
      _initTimer?.cancel();
      _initTimer = Timer(Duration(seconds: 3), () {
        controller.setFilePath("");
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        // 如果锁屏，先解锁
        if (_isLock) {
          setState(() {
            _isLock = !_isLock;
            _hideStuff = false;
            _hideTimer?.cancel();
            _startHideTimer();
          });
          _setOrientations();
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildGestureView(),
          ),
          Positioned.fill(
            child: _buildGestureDetector(),
          ),
          if (chewieController.isFullScreen)
            Positioned(
              left: 0, right: 0, top: 0,
              child: _buildTitleBar(),
            ),
          if (chewieController.isFullScreen)
            Positioned(
              left: 10, bottom: 0, top: 0,
              child: _buildLock(),
            ),
          if (chewieController.isFullScreen)
            Positioned(
              right: 10, bottom: 0, top: 0,
              child: _buildSnapshot(),
            ),
          if (chewieController.isFullScreen)
            Positioned(
              right: 70, bottom: 0, top: 60,
              child: _latestValue.filePath != null && _latestValue.filePath != "" ? Align(
                alignment: Alignment.topLeft,
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Image.file(File(_latestValue.filePath)),
                ),
              ) : const SizedBox.shrink(),
            ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomBar(
              hideStuff: _isLock ? true : _hideStuff,
              progress: animationController,
              playPause: _playPause,
              onDragStart: () {
                setState(() {
                  _progressBarDragging = true;
                  _hideTimer?.cancel();
                });
              },
              onDragUpdate: () {
                setState(() {

                });
              },
              onDragEnd: () {
                setState(() {
                  _progressBarDragging = false;
                  _startHideTimer();
                });
              },
            ),
          ),
          Positioned.fill(
            child: TipsView(
              replay: _playPause,
              reTry: _reTry,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSnapshot() {
    return IgnorePointer(
      ignoring: _hideStuff,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        opacity: _isLock ? 0.0 : (_hideStuff ? 0.0 : 1.0),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(6.0),
            ),
            width: 50,
            height: 50,
            child: IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.white,),
              onPressed: () async {
                await controller.snapshot();
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLock() {
    return IgnorePointer(
      ignoring: _hideStuff,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        opacity: _hideStuff ? 0.0 : 1.0,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(6.0),
            ),
            width: 50,
            height: 50,
            child: IconButton(
              icon: Icon(_isLock ? Icons.lock : Icons.lock_open, color: Colors.white,),
              onPressed: () async {
                setState(() {
                  _isLock = !_isLock;
                });
                await _setOrientations();
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTitleBar() {
    return IgnorePointer(
      ignoring: _hideStuff,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        opacity: _isLock ? 0.0 : (_hideStuff ? 0.0 : 1.0),
        child: Container(
          height: 60.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(.3),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .9],
            ),
          ),
          child: Row(
            children: [
              BackButton(color: Colors.white,),
              Spacer(),
              IconButton(
                icon: Icon(Icons.more_horiz, color: Colors.white,),
                onPressed: () {
                  if (_isLock) {
                    return;
                  }
                  // 打卡菜单时，隐藏BottomBar和TitleBar
                  setState(() {
                    _hideStuff = true;
                  });
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGestureView() {
    Widget body;
    if (_progressBarDragging) {
      body = SeekDialog();
    }
    if (_volumeDragging) {
      body = GestureDialog(
        icon: _latestValue.volume == 0 ? Icons.volume_off : Icons.volume_up,
        value: _latestValue.volume,
      );
    }
    if (_brightnessDragging) {
      body = GestureDialog(
        icon: Icons.wb_sunny,
        value: _latestValue.brightness,
      );
    }
    return Center(
      child: body ?? const SizedBox.shrink(),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _hideStuff = true;
      });
    });
  }

  Widget _buildGestureDetector() {
    return GestureDetector(
      onTap: () {
        if (_hideStuff) {
          _cancelAndRestartTimer();
        } else {
          _hideTimer?.cancel();
          setState(() {
            _hideStuff = true;
          });
        }
      },      
      onDoubleTap: _playPause,
      onHorizontalDragStart: (DragStartDetails details) {
        if (_isLock) {
          return;
        }
        if (!_latestValue.initialized) {
          return;
        }
        _currentPosition = _latestValue.position;
        _initialOffset = details.globalPosition;
        controller.cancelTimer();
        _progressBarDragging = true;
        setState(() {});
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (_isLock) {
          return;
        }
        if (!_latestValue.initialized) {
          return;
        }
        setState(() {});
        seekToRelativePosition(details.globalPosition);
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_isLock) {
          return;
        }
        if (!_latestValue.initialized) {
          return;
        }
        _progressBarDragging = false;
        controller.seekTo(_position);
        if (controller.value.isPlaying) {
          controller.createTimer();
        }
        setState(() {});
      },
      onVerticalDragStart: (DragStartDetails details) {
        if (_isLock) {
          return;
        }
        if (!_latestValue.initialized) {
          return;
        }
        _initialOffset = details.globalPosition;
        _currentVolume = controller.value.volume;
        _currentBrightness = controller.value.brightness;
        final RenderBox box = context.findRenderObject() as RenderBox;
        setState(() {
          /// 区分滑动左右区域
          if (_initialOffset.dx > box.size.width / 2) {
            _volumeDragging = true;
            _brightnessDragging = false;
          } else {
            _volumeDragging = false;
            _brightnessDragging = true;
          }
        });
      },
      onVerticalDragUpdate: (DragUpdateDetails details) {
        if (_isLock) {
          return;
        }
        if (!_latestValue.initialized) {
          return;
        }
        final offsetDifference = _initialOffset.dy - details.globalPosition.dy;
        final RenderBox box = context.findRenderObject() as RenderBox;
        final double relative = offsetDifference * 1.8 / box.size.height;
        double brightness = double.parse((relative + _currentBrightness).clamp(0, 1).toStringAsFixed(2));
        double volume = double.parse((relative + _currentVolume).clamp(0, 1).toStringAsFixed(1));
        if (volume != controller.value.volume && _volumeDragging) {
          controller.setVolume(volume);
        }
        if (brightness != controller.value.brightness && _brightnessDragging) {
          controller.setBrightness(brightness);
        }
        setState(() {});
      },
      onVerticalDragEnd: (DragEndDetails details) {
        if (_isLock) {
          return;
        }
        if (!_latestValue.initialized) {
          return;
        }
        setState(() {
          _volumeDragging = false;
          _brightnessDragging = false;
        });
      }
    );
  }
  
  void seekToRelativePosition(Offset globalPosition) {
    if (globalPosition == null) {
      return;
    }
    final offsetDifference = globalPosition.dx - _initialOffset.dx;
    final box = context.findRenderObject() as RenderBox;
    final double relative = offsetDifference / box.size.width;
   
    final Duration deltaPosition = controller.value.duration * relative;
    final Duration duration = controller.value.duration;
    int finalDeltaPosition;
    if (duration.inHours >=1) {
      // 视频时长为1小时以上，小屏和全屏的手势滑动最长为视频时长的十分之一
      finalDeltaPosition = deltaPosition.inMilliseconds % 10;
    } else if (duration.inMinutes > 30) {
      // 视频时长为31分钟－60分钟时，小屏和全屏的手势滑动最长为视频时长五分之一
      finalDeltaPosition = deltaPosition.inMilliseconds % 5;
    } else if (duration.inMinutes > 10) {
      // 视频时长为11分钟－30分钟时，小屏和全屏的手势滑动最长为视频时长三分之一
      finalDeltaPosition = deltaPosition.inMilliseconds % 3;
    } else if (duration.inMinutes > 3) {
      // 视频时长为4-10分钟时，小屏和全屏的手势滑动最长为视频时长二分之一
      finalDeltaPosition = deltaPosition.inMilliseconds % 2;
    } else {
      // 视频时长为1秒钟至3分钟时，小屏和全屏的手势滑动最长为视频结束
      finalDeltaPosition = deltaPosition.inMilliseconds;
    }
    
    _position = _currentPosition + Duration(milliseconds: finalDeltaPosition);
    
    if (_position <= const Duration(seconds: 0)) {
      _position = const Duration(seconds: 0);
    }
    if (_position >= controller.value.duration) {
      _position = controller.value.duration;
    }
    controller.updatePosition(_position);
  }

  Future<void> _reTry(Duration latestPosition) async {
    if (!_latestValue.initialized) {
      await controller.initialize();
      chewieController.refresh();
    }
    animationController.forward();
    await controller.seekTo(latestPosition);
    await controller.play();
  }

  Future<void> _playPause() async {
    // 播放完成不受锁屏限制
    bool isFinished = _latestValue.position >= _latestValue.duration;
    if (!isFinished && _isLock) {
      return;
    }
    /// 重新计时
    _hideTimer?.cancel();
    _startHideTimer();
    
    if (controller.value.isPlaying) {
      animationController.reverse();
      await controller.pause();
    } else {

      if (controller.value.initialized) {
        animationController.forward();
        if (isFinished) {
          await controller.seekTo(Duration(seconds: 0));
        }
        await controller.play();
      }
    }
  }

  Future<void> _setOrientations() async {
    if (_isLock) {
      /// 获取屏幕方向，并锁定当前方向
      final orientation = await NativeDeviceOrientationCommunicator().orientation();
      if (orientation == NativeDeviceOrientation.landscapeLeft) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);
      }
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    }
  }
}


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';
import 'package:video_player_example/chewie/chewie_progress_colors.dart';
import 'package:video_player_example/chewie/material_progress_bar.dart';

import 'chewie/utils.dart';

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
  bool _dragging = false;

  Duration _latestPosition;
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
  }

  void _updateState() {
    setState(() {
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
    });
  }
  
  @override
  Widget build(BuildContext context) {
    
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null ? 
      chewieController.errorBuilder(
        context,
        chewieController.videoPlayerController.value.errorDescription,
      ):
      Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_latestValue.errorDescription, style: const TextStyle(color: Colors.white, fontSize: 14.0),),
              SizedBox(height: 10,),
              OutlineButton.icon(
                borderSide: const BorderSide(color: Colors.white),
                label: const Text('重试', style: const TextStyle(color: Colors.white, fontSize: 14.0),),
                icon: Icon(
                  Icons.replay,
                  semanticLabel: 'Replay',
                  size: 20.0,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (!_latestValue.initialized) {
                    await controller.initialize();
                  }
                  await controller.play();
                  // TODO
                  await controller.seekTo(Duration(seconds: 20));
                  if (chewieController.initComplete != null) {
                    chewieController.initComplete();
                  }
                },
              )
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: _dragging ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              height: 36.0,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPosition()
                ],
              ),
            ) : const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(
          child: _buildGestureDetector(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomBar(),
        ),
        _buildLoading(),
        if (_latestValue != null && _latestValue.initialized && 
            _latestValue.position >= _latestValue.duration && !_dragging && !_latestValue.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Center(
                child: OutlineButton.icon(
                  borderSide: BorderSide(color: Colors.white),
                  label: const Text('重播', style: TextStyle(color: Colors.white, fontSize: 14.0),),
                  color: Colors.transparent,
                  icon: Icon(
                    Icons.replay,
                    semanticLabel: 'Replay',
                    size: 20.0,
                    color: Colors.white,
                  ),
                  onPressed: _playPause,
                ),
              ),
            ),
        ),
      ],
    );
  }
  
  Widget _buildLoading() {
    if (_latestValue != null && (_latestValue.state == VideoState.initalized
        || _latestValue.state == VideoState.idle || _latestValue.state == VideoState.prepared) || _latestValue.isLoading) {
      _latestPosition = _latestValue.position;
      return const Positioned.fill(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return const Positioned.fill(child: const SizedBox.shrink());
    }
  }
  
  Widget _buildBottomBar() {
    return Container(
      height: 60.0,
      padding: EdgeInsets.only(top: 20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(.3),
            Colors.transparent,
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0, .9],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: animationController,
              semanticLabel: 'Play/Pause',
              size: 25.0,
              color: Colors.white,
            ),
            onPressed: _playPause,
          ),
          Expanded(child: _buildProgressBar(),),
          Padding(
            padding: EdgeInsets.only(left: 15.0),
            child: _buildPosition(),
          ),
          IconButton(
            icon: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
              size: 25.0,
            ),
            onPressed: _onExpandCollapse,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return MaterialVideoProgressBar(controller,
      onDragStart: () {
        _dragging = true;
      },
      onDragEnd: () {
        _dragging = false;
      },
      colors: chewieController.materialProgressColors ??
          ChewieProgressColors(
            playedColor: Theme.of(context).accentColor,
            handleColor: Theme.of(context).accentColor,
            bufferedColor: Colors.white.withOpacity(.5),
            backgroundColor: Colors.white.withOpacity(.3),
          ),
    );
  }

  Widget _buildPosition() {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return RichText(
      text: TextSpan(
        text: '${formatDuration(position)}',
        children: [
          TextSpan(
            text: ' / ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.0,
            ),
          ),
          TextSpan(
            text: '${formatDuration(duration)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.0,
            ),
          ),
        ],
        style: const TextStyle(color: Colors.white, fontSize: 12.0),
      ),
    );
  }
  
  Widget _buildGestureDetector() {
    return GestureDetector(
      onDoubleTap: _playPause,
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        _currentPosition = _latestValue.position;
        _initialOffset = details.globalPosition;
        controller.cancelTimer();
        _dragging = true;
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);

      },
      onHorizontalDragEnd: (DragEndDetails details) {
        _dragging = false;
        controller.seekTo(_position);
        if (controller.value.isPlaying) {
          controller.createTimer();
        }
      },
    );
  }
  Offset _initialOffset;
  Duration _position;
  Duration _currentPosition;
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
  
  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        animationController.reverse();
        controller.pause();
      } else {

        if (controller.value.initialized) {
          if (isFinished) {
            controller.seekTo(Duration(seconds: 0));
          }
          animationController.forward();
          controller.play();
        }
      }
    });
  }

  void _onExpandCollapse() {
    chewieController.toggleFullScreen();
  }
}

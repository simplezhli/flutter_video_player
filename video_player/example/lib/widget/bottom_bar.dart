
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';
import 'package:video_player_example/chewie/chewie_progress_colors.dart';
import 'package:video_player_example/chewie/material_progress_bar.dart';
import 'package:video_player_example/chewie/utils.dart';

class BottomBar extends StatefulWidget {

  const BottomBar({
    Key key,
    @required this.playPause,
    @required this.progress,
    this.progressBarColor,
    this.hideStuff,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
  }) : super(key: key);

  final VoidCallback playPause;
  final Animation<double> progress;
  final Color progressBarColor;
  final bool hideStuff;
  final Function() onDragStart;
  final Function() onDragEnd;
  final Function() onDragUpdate;

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {

  VideoPlayerController controller;
  ChewieController chewieController;
  VideoPlayerValue _latestValue;
  
  @override
  void dispose() {
    _dispose(controller);
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
      controller?.addListener(_updateState);
      _updateState();
    }

    super.didChangeDependencies();
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    /// 隐藏时忽略各种指针事件
    return IgnorePointer(
      ignoring: widget.hideStuff,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: widget.hideStuff ? 0.0 : 1.0,
            child: Container(
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
                      progress: widget.progress,
                      semanticLabel: 'Play/Pause',
                      size: 25.0,
                      color: Colors.white,
                    ),
                    onPressed: widget.playPause,
                  ),
                  Expanded(child: _buildProgressBar(),),
                  Padding(
                    padding: EdgeInsets.only(left: 15.0),
                    child: _buildPosition(),
                  ),
                  IconButton(
                    icon: Icon(
                      chewieController.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 25.0,
                    ),
                    onPressed: _onExpandCollapse,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: !widget.hideStuff ? 0.0 : 1.0,
              // 全屏不显示底部进度条
              child: widget.hideStuff && _latestValue.initialized && !chewieController.isFullScreen ? LinearProgressIndicator(
                value: _latestValue.position.inMilliseconds / _latestValue.duration.inMilliseconds,
                minHeight: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(widget.progressBarColor ?? Theme.of(context).accentColor),
                backgroundColor: Colors.transparent,
              ) : const SizedBox.shrink(),
            ),
          ), 
        ],
      ),
    );
  }

  void _onExpandCollapse() {
    chewieController.toggleFullScreen();
  }

  Widget _buildProgressBar() {
    return MaterialVideoProgressBar(controller,
      onDragStart: widget.onDragStart,
      onDragUpdate: widget.onDragUpdate,
      onDragEnd:  widget.onDragEnd,
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
}

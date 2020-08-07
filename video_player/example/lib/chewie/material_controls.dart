import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';
import 'package:video_player_example/chewie/chewie_progress_colors.dart';
import 'package:video_player_example/chewie/material_progress_bar.dart';
import 'package:video_player_example/chewie/utils.dart';

class MaterialControls extends StatefulWidget {
  const MaterialControls({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls>
    with SingleTickerProviderStateMixin {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  final barHeight = 55.0;
  final marginSize = 5.0;

  VideoPlayerController controller;
  ChewieController chewieController;

  AnimationController animationController;

  @override
  void initState() {
    super.initState();

    if (animationController == null) {
      animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
        reverseDuration: Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
        context,
        chewieController.videoPlayerController.value.errorDescription,
      )
          : Center(
        child: Icon(
          Icons.error,
          color: Colors.white,
          size: 42,
        ),
      );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: _hideStuff ? 0.0 : 1.0,
            child: Container(
              padding: EdgeInsets.only(bottom: chewieController.isLive ? 0 : 20),
              decoration: !_hideStuff
                  ? BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(.7),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0, .9]))
                  : null,
              child: Column(
                children: <Widget>[
                  _latestValue != null &&
                      !_latestValue.isPlaying &&
                      _latestValue.duration == null ||
                      _latestValue.isBuffering
                      ? const Expanded(
                    child: const Center(
                      child: const CircularProgressIndicator(),
                    ),
                  )
                      : _buildHitArea(),
                  _buildBottomBar(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildLiveIndicator() {
    return Container(
        margin: EdgeInsets.only(left: 10),
        alignment: Alignment.center,
        child: Row(children: [
          Container(
            margin: EdgeInsets.only(right: 5),
            height: 7,
            width: 7,
            decoration:
            BoxDecoration(shape: BoxShape.circle, color: Colors.red),
            child: SizedBox(),
          ),
          const Text('LIVE', style: TextStyle(color: Colors.white))
        ]));
  }

  AnimatedOpacity _buildBottomBar(
      BuildContext context,
      ) {
    final iconColor = Theme.of(context).textTheme.button.color;

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        height: !chewieController.isLive ? barHeight : 48,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: chewieController.isLive ? 0 : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  chewieController.isLive
                      ? _buildLiveIndicator()
                      : _buildPosition(iconColor),
                  Spacer(),
                  chewieController.allowMuting
                      ? _buildMuteButton(controller)
                      : Container(),
                  chewieController.allowFullScreen
                      ? _buildExpandButton()
                      : Container(),
                ],
              ),
            ),
            !chewieController.isLive ?
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildProgressBar(),
              ) : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          padding: EdgeInsets.only(
            left: 4.0,
            right: 10.0,
          ),
          child: Center(
            child: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else
              _cancelAndRestartTimer();
          } else {
            setState(() {
              _hideStuff = true;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity: _dragging || !_hideStuff ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: GestureDetector(
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(48.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.0).copyWith(top: 30),
                      child: IconButton(
                        icon: _latestValue != null
                            && _latestValue.position >= _latestValue.duration
                            && !chewieController.isLive
                            ? Icon(Icons.replay,
                            semanticLabel: 'Replay',
                            size: 50.0,
                            color: Colors.white)
                            : AnimatedIcon(
                          icon: AnimatedIcons.play_pause,
                          progress: animationController,
                          semanticLabel: 'Play/Pause',
                          size: 50.0,
                          color: Colors.white,
                        ),
                        onPressed: () => _playPause(),
                      ),
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
      VideoPlayerController controller,
      ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: 8.0,
                right: 4.0,
              ),
              child: Icon(
                (_latestValue != null && _latestValue.volume > 0)
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: RichText(
            text: TextSpan(
                text: '${formatDuration(position)}',
                children: [
                  TextSpan(
                      text: ' / ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.75),
                        fontSize: 14.0,
                      )),
                  TextSpan(
                      text: '${formatDuration(duration)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.75),
                        fontSize: 14.0,
                      )),
                ],
                style: TextStyle(color: Colors.white, fontSize: 14.0))));
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<Null> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        animationController.reverse();
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            animationController.forward();
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration(seconds: 0));
          }
          animationController.forward();
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: MaterialVideoProgressBar(
        controller,
        onDragStart: () {
          setState(() {
            _dragging = true;
          });

          _hideTimer?.cancel();
        },
        onDragEnd: () {
          setState(() {
            _dragging = false;
          });

          _startHideTimer();
        },
        colors: chewieController.materialProgressColors ??
            ChewieProgressColors(
                playedColor: Theme.of(context).accentColor,
                handleColor: Theme.of(context).accentColor,
                bufferedColor: Theme.of(context).backgroundColor,
                backgroundColor: Theme.of(context).disabledColor),
      ),
    );
  }
}
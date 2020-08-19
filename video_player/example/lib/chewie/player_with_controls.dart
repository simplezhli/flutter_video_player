import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';
import 'package:video_player_example/chewie/material_controls.dart';

class PlayerWithControls extends StatefulWidget {
  PlayerWithControls({Key key}) : super(key: key);

  @override
  _PlayerWithControlsState createState() => _PlayerWithControlsState();
}

class _PlayerWithControlsState extends State<PlayerWithControls> {

  ChewieController _chewieController;
  double aspectRatio;
  
  @override
  void didChangeDependencies() {
    ChewieController chewieController = ChewieController.of(context);
    if (chewieController != _chewieController) {
      _chewieController = chewieController;
      _chewieController.addListener(_refresh);
    }
    super.didChangeDependencies();
  }
  
  void _refresh() {
    /// 视频比例变化时刷新
    if (_chewieController.aspectRatio == null) {
      if (aspectRatio != _chewieController.videoPlayerController.value.aspectRatio) {
        if (!mounted) {
          return;
        }
        setState(() {
          
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.removeListener(_refresh);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
   
    if (_chewieController.aspectRatio == null) {
      aspectRatio = _chewieController.videoPlayerController.value.aspectRatio;
    } else {
      aspectRatio = min(_chewieController.aspectRatio, _chewieController.videoPlayerController.value.aspectRatio);
    }
    return Center(
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: _chewieController.isFullScreen ? _calculateAspectRatio(context) : aspectRatio,
          child: _buildPlayerWithControls(_chewieController, context),
        ),
      ),
    );
  }

  double _calculateAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return width > height ? width / height : height / width;
  }

  Widget _buildControls(
      BuildContext context,
      ChewieController chewieController,
      ) {
    return chewieController.showControls
        ? chewieController.customControls != null
        ? chewieController.customControls
        : MaterialControls()
        : const SizedBox.shrink();
  }

  Container _buildPlayerWithControls(
      ChewieController chewieController, BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          chewieController.placeholder ?? const SizedBox.shrink(),
          Center(
            child: AspectRatio(
              aspectRatio: chewieController.videoPlayerController.value.aspectRatio,
              child: VideoPlayer(chewieController.videoPlayerController),
            ),
          ),
          chewieController.overlay ?? const SizedBox.shrink(),
          _buildControls(context, chewieController),
        ],
      ),
    );
  }
}
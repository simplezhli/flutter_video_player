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
  int scaleMode;
  double aspectRatio;
  VideoPlayerController controller;

  @override
  void dispose() {
    _dispose(controller);
    super.dispose();
  }

  void _dispose(VideoPlayerController controller) {
    controller?.removeListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    final _oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = _chewieController.videoPlayerController;

    if (_oldController != _chewieController) {
      _dispose(_oldController?.videoPlayerController);
      controller?.addListener(_refresh);
    }

    super.didChangeDependencies();
  }
  
  void _refresh() {
    /// 视频尺寸变化时刷新
    if (scaleMode != _chewieController.videoPlayerController.value.scaleMode) {
      scaleMode = _chewieController.videoPlayerController.value.scaleMode;
      if (!mounted) {
        return;
      }
      setState(() {

      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
   
    if (_chewieController.aspectRatio == null) {
      aspectRatio = _chewieController.videoPlayerController.value.aspectRatio;
    } else {
      aspectRatio = _chewieController.aspectRatio;
    }

    aspectRatio = _chewieController.isFullScreen ? _calculateAspectRatio(context) : aspectRatio;
    
    return Center(
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: aspectRatio,
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
    print(chewieController.videoPlayerController.value.mirrorMode);
    return Container(
      child: Stack(
        children: <Widget>[
          chewieController.placeholder ?? const SizedBox.shrink(),
          Center(
            child: AspectRatio(
              aspectRatio: chewieController.videoPlayerController.value.scaleMode != 0 ? aspectRatio : chewieController.videoPlayerController.value.aspectRatio,
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
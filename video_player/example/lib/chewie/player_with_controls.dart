
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';
import 'package:video_player_example/chewie/material_controls.dart';

class PlayerWithControls extends StatelessWidget {
  PlayerWithControls({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
   
    return Center(
      child: AspectRatio(
        aspectRatio: chewieController.isFullScreen ? _calculateAspectRatio(context) : chewieController.videoPlayerController.value.aspectRatio,
        child: _buildPlayerWithControls(chewieController, context),
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
        : Container();
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


import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';
import 'package:video_player_example/chewie/utils.dart';

class SeekDialog extends StatelessWidget {

  const SeekDialog({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      height: 36.0,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPosition(context),
        ],
      ),
    );
  }

  Widget _buildPosition(BuildContext context) {
    VideoPlayerValue _latestValue = ChewieController.of(context).videoPlayerController.value;
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

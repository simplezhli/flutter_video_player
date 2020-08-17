
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';

/// 包含加载中、重试、重播，网络提示
class TipsView extends StatefulWidget {

  const TipsView({
    Key key,
    @required this.replay,
    @required this.reTry,
  }) : super(key: key);
  
  final Future<void> Function(Duration position) reTry;
  final VoidCallback replay;
  
  @override
  _TipsViewState createState() => _TipsViewState();
}

class _TipsViewState extends State<TipsView> {

  VideoPlayerController _controller;
  ChewieController _chewieController;
  VideoPlayerValue _latestValue;
  ///  用于恢复之前播放位置
  Duration _latestPosition;
  
  @override
  void didChangeDependencies() {
    _chewieController = ChewieController.of(context);
    _controller = _chewieController.videoPlayerController;
    super.didChangeDependencies();
  }
  
  @override
  Widget build(BuildContext context) {
    Widget body;
    _latestValue = _controller?.value;
    if (_latestValue == null) {
      return const SizedBox.shrink();
    }
    
    body = _buildError();
    if (body == null) {
      body = _buildLoading();
    }
    if (body == null) {
      body = _buildReplay();
    }
    if (body == null) {
      body = const SizedBox.shrink();
    }
    return body;
  }
  
  Widget _buildError() {
    if (_latestValue.hasError) {
      return _chewieController.errorBuilder != null ?
      _chewieController.errorBuilder(
        context,
        _latestValue.errorDescription,
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
                  semanticLabel: 'ReTry',
                  size: 20.0,
                  color: Colors.white,
                ),
                onPressed: () async{
                  await widget.reTry(_latestPosition);
                },
              )
            ],
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildReplay() {
    // 视频初始化完成，同时播放时长大于等于视频时长。
    if (_latestValue.initialized && _latestValue.position >= _latestValue.duration && !_latestValue.isLoading) {
      return Container(
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
            onPressed: widget.replay,
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildLoading() {
    if (_latestValue.state == VideoState.initalized || _latestValue.state == VideoState.idle || _latestValue.isLoading) {
      if (_latestValue.isLoading) {
        /// 播放途中卡主，记录当前位置，便于后面恢复播放。
        _latestPosition = _latestValue.position;
      }
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return null;
  }
}

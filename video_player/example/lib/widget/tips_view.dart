
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';

/// 包含缓冲加载、重试、重播，网络变化提示
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

    body = _buildNetChangeView();
    
    if (body == null) {
      body = _buildErrorView();
    }
    if (body == null) {
      body = _buildLoadingView();
    }
    if (body == null) {
      body = _buildReplayView();
    }
    if (body == null) {
      body = const SizedBox.shrink();
    }
    return body;
  }
  
  Widget _buildErrorView() {
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

  Widget _buildReplayView() {
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

  Widget _buildLoadingView() {
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
  
  Widget _buildNetChangeView() {
    if (_chewieController.isCheckConnectivity && 
        _chewieController.isWifi != null && !_chewieController.isWifi) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('当前为非Wi-Fi，是否继续播放？', style: TextStyle(color: Colors.white, fontSize: 14.0),),
              SizedBox(height: 10,),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlineButton(
                    borderSide: const BorderSide(color: Colors.white),
                    child: const Text('继续播放', style: const TextStyle(color: Colors.white, fontSize: 14.0),),
                    onPressed: () {
                      _chewieController.setNetState(true);
                    },
                  ),
                  const SizedBox(width: 40,),
                  OutlineButton(
                    borderSide: const BorderSide(color: Colors.lightBlue),
                    child: const Text('退出播放', style: const TextStyle(color: Colors.lightBlue, fontSize: 14.0),),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      );
    }
    return null;
  }
}

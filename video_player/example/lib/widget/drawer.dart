

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';

class MyDrawer extends StatefulWidget {

  MyDrawer({
    Key key,
    this.controller,
  })  : super(key: key);

  final ChewieController controller;
  
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {

  final List<double> speedList = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  final List<String> scaleModeList = ['适应', '拉伸'];
  final List<String> mirrorModeList = ['无镜像', '水平镜像', '垂直镜像'];
  final List<String> loopingList = ['关闭', '开启'];
  
  double _speed;
  int _scaleMode;
  int _mirrorMode;
  bool _isLooping;

  @override
  void initState() {
    widget.controller.videoPlayerController.addListener(_updateState);
    super.initState();
  }

  void _updateState() {
    if (!mounted) {
      return;
    }
    VideoPlayerValue value = widget.controller.videoPlayerController.value;
    if (value.speed != _speed) {
      _speed = value.speed;
      setState(() {

      });
    }
    if (value.scaleMode != _scaleMode) {
      _scaleMode = value.scaleMode;
      setState(() {

      });
    }
    if (value.mirrorMode != _mirrorMode) {
      _mirrorMode = value.mirrorMode;
      setState(() {

      });
    }

    if (value.isLooping != _isLooping) {
      _isLooping = value.isLooping;
      setState(() {

      });
    }
  }

  @override
  void dispose() {
    widget.controller.videoPlayerController.addListener(_updateState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: double.infinity,
      color: Colors.black54,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20.0, left: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('播放速度', style: const TextStyle(color: Colors.white54),),
            const SizedBox(height: 15.0,),
            Row(
              children: List.generate(speedList.length, (index) => _buildSpeedButton(speedList[index])),
            ),
            const SizedBox(height: 35.0,),
            Text('画面尺寸', style: const TextStyle(color: Colors.white54),),
            const SizedBox(height: 15.0,),
            Row(
              children: List.generate(scaleModeList.length, (index) => _buildScaleModeButton(index)),
            ),
            const SizedBox(height: 35.0,),
            Text('循环播放', style: const TextStyle(color: Colors.white54),),
            const SizedBox(height: 15.0,),
            Row(
              children: List.generate(loopingList.length, (index) => _buildLoopingButton(index)),
            ),
            const SizedBox(height: 35.0,),
            Text('画面镜像', style: const TextStyle(color: Colors.white54),),
            const SizedBox(height: 15.0,),
            Row(
              children: List.generate(mirrorModeList.length, (index) => _buildMirrorModeButton(index)),
            ),
            const SizedBox(height: 35.0,),
            
          ],
        ),
      ),
    );
  }

  Widget _buildLoopingButton(int index) {
    bool isSelected = widget.controller.videoPlayerController.value.isLooping;
    if (index == 1 && isSelected) {
      isSelected = true;
    } else if (index == 0 && !isSelected) {
      isSelected = true;
    } else {
      isSelected = false;
    }
    return InkWell(
      onTap: () {
        widget.controller.videoPlayerController.setLooping(index != 0);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 26.0),
        child: Text(loopingList[index],
          style: TextStyle(
            color: isSelected ? Colors.lightBlue : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMirrorModeButton(int index) {
    bool isSelected = index == widget.controller.videoPlayerController.value.mirrorMode;
    return InkWell(
      onTap: () {
        widget.controller.videoPlayerController.setMirrorMode(index);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 26.0),
        child: Text(mirrorModeList[index],
          style: TextStyle(
            color: isSelected ? Colors.lightBlue : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildScaleModeButton(int index) {
    bool isSelected = index == widget.controller.videoPlayerController.value.scaleMode;
    return InkWell(
      onTap: () {
        widget.controller.videoPlayerController.setScaleMode(index);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 26.0),
        child: Text(scaleModeList[index],
          style: TextStyle(
            color: isSelected ? Colors.lightBlue : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton(double speed) {
    bool isSelected = speed == widget.controller.videoPlayerController.value.speed;
    return Expanded(
      child: InkWell(
        onTap: () {
          widget.controller.videoPlayerController.setSpeed(speed);
        },
        child: Text(speed.toString(),
          style: TextStyle(
            color: isSelected ? Colors.lightBlue : Colors.white,
            fontSize: 15.0,
          ),
        ),
      ),
    );
  }

}

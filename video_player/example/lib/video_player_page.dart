

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';
import 'package:video_player_example/widget/deer_controls.dart';
import 'package:wakelock/wakelock.dart';


class VideoPlayerPage extends StatefulWidget {
  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {

  VideoPlayerController _videoPlayerController1;
  VideoPlayerController _videoPlayerController2;
  ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController1 = VideoPlayerController.network(
        'http://vfx.mtime.cn/Video/2019/03/19/mp4/190319104618910544.mp4');
    _videoPlayerController2 = VideoPlayerController.network(
        'http://vfx.mtime.cn/Video/2019/03/13/mp4/190313094901111138.mp4');
    _chewieController = ChewieController(
      allowedScreenSleep: false,
      customControls: DeerControls(),
      videoPlayerController: _videoPlayerController1,
      autoInitialize: true,
      autoPlay: true,
      looping: false,
      initComplete: () {
        setState(() {

        });
      },
    );
    Wakelock.enable();
  }

  @override
  void dispose() {
    
    _videoPlayerController1?.restoreBrightness();
    _videoPlayerController2?.restoreBrightness();
    _videoPlayerController1.dispose();
    _videoPlayerController2.dispose();
    _chewieController.dispose();
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video player example'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Chewie(
              controller: _chewieController,
            ),
          ),
          FlatButton(
            onPressed: () {
              _chewieController.enterFullScreen();
            },
            child: Text('Fullscreen'),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: FlatButton(
                  onPressed: () {
                    setState(() {
                      _chewieController.dispose();
                      _videoPlayerController2.pause();
                      _videoPlayerController2.seekTo(Duration(seconds: 0));
                      _chewieController = ChewieController(
                        customControls: DeerControls(),
                        videoPlayerController: _videoPlayerController1,
                        autoInitialize: true,
                        autoPlay: false,
                        looping: false,
                        initComplete: () {
                          setState(() {

                          });
                        },
                      );
                    });
                  },
                  child: Padding(
                    child: Text("Video 1"),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
              Expanded(
                child: FlatButton(
                  onPressed: () {
                    setState(() {
                      _chewieController.dispose();
                      _videoPlayerController1.pause();
                      _videoPlayerController1.seekTo(Duration(seconds: 0));
                      _chewieController = ChewieController(
                        customControls: DeerControls(),
                        videoPlayerController: _videoPlayerController2,
                        autoInitialize: true,
                        autoPlay: false,
                        looping: false,
                        initComplete: () {
                          setState(() {

                          });
                        },
                      );
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text("Video 2"),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

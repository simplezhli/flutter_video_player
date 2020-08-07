// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:auto_orientation/auto_orientation.dart';
/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_player.dart';

void main() {
  runApp(
    MaterialApp(
      home: _App(),
    ),
  );
}

class _App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('home_page'),
      appBar: AppBar(
        title: const Text('Video player example'),
      ),
      body: _BumbleBeeRemoteVideo(),
    );
  }
}

class _BumbleBeeRemoteVideo extends StatefulWidget {
  @override
  _BumbleBeeRemoteVideoState createState() => _BumbleBeeRemoteVideoState();
}

class _BumbleBeeRemoteVideoState extends State<_BumbleBeeRemoteVideo> {

  VideoPlayerController _videoPlayerController1;
  VideoPlayerController _videoPlayerController2;
  ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController1 = VideoPlayerController.network(
        'http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4');
    _videoPlayerController2 = VideoPlayerController.network(
        'http://vfx.mtime.cn/Video/2019/03/19/mp4/190319222227698228.mp4');
    _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController1,
        aspectRatio: 3 / 2,
        autoPlay: false,
        looping: false,
        routePageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondAnimation, provider) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget child) {
              return VideoScaffold(
                child: Scaffold(
                  resizeToAvoidBottomPadding: false,
                  body: Container(
                    alignment: Alignment.center,
                    color: Colors.black,
                    child: provider,
                  ),
                ),
              );
            },
          );
        }
      // Try playing around with some of these other options:

      // showControls: false,
      // materialProgressColors: ChewieProgressColors(
      //   playedColor: Colors.red,
      //   handleColor: Colors.blue,
      //   backgroundColor: Colors.grey,
      //   bufferedColor: Colors.lightGreen,
      // ),
      // placeholder: Container(
      //   color: Colors.grey,
      // ),
      // autoInitialize: true,
    );
  }

  @override
  void dispose() {
    _videoPlayerController1.dispose();
    _videoPlayerController2.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: Chewie(
              controller: _chewieController,
            ),
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
                      videoPlayerController: _videoPlayerController1,
                      aspectRatio: 3 / 2,
                      autoPlay: false,
                      looping: false,
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
                      videoPlayerController: _videoPlayerController2,
                      aspectRatio: 3 / 2,
                      autoPlay: false,
                      looping: false,
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
    );
  }
}

class VideoScaffold extends StatefulWidget {
  const VideoScaffold({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  State<StatefulWidget> createState() => _VideoScaffoldState();
}

class _VideoScaffoldState extends State<VideoScaffold> {
  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    AutoOrientation.landscapeAutoMode();
    super.initState();
  }

  @override
  dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    AutoOrientation.portraitAutoMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

import 'package:flutter/material.dart';
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
        allowedScreenSleep: false,
        videoPlayerController: _videoPlayerController1,
        aspectRatio: 3 / 2,
        autoInitialize: true,
        autoPlay: true,
        looping: false,
        initComplete: () {
          setState(() {
            
          });
        },
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
                      videoPlayerController: _videoPlayerController1,
                      aspectRatio: 3 / 2,
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
                      videoPlayerController: _videoPlayerController2,
                      aspectRatio: 3 / 2,
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
    );
  }
}

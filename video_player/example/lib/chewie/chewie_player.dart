import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/chewie/chewie_progress_colors.dart';
import 'package:video_player_example/chewie/player_with_controls.dart';
import 'package:wakelock/wakelock.dart';
import 'package:connectivity/connectivity.dart';

typedef Widget ChewieRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    _ChewieControllerProvider controllerProvider);

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. Chewie wraps it in a friendly skin to
/// make it easy to use!
class Chewie extends StatefulWidget {
  Chewie({
    Key key,
    this.controller,
    this.beforeFullScreen,
    this.afterFullScreen
  })  : assert(controller != null, 'You must provide a chewie controller'),
        super(key: key);

  /// The [ChewieController]
  final ChewieController controller;
  
  /// Function to execute before going into FullScreen
  final Function beforeFullScreen;

  /// Function to execute after exiting FullScreen
  final Function afterFullScreen;

  @override
  ChewieState createState() {
    return ChewieState();
  }
}

class ChewieState extends State<Chewie> {
  bool _isFullScreen = false;
  StreamSubscription<ConnectivityResult> _subscription;
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
    if (widget.controller.isCheckConnectivity) {
      _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(Chewie oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
  }
  
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        widget.controller.setNetState(true);
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.none:
        widget.controller.setNetState(false);
        break;
      default:
        break;
    }
  }
  
  void listener() async {
    if (widget.controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isFullScreen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ChewieControllerProvider(
      controller: widget.controller,
      child: PlayerWithControls(),
    );
  }

  Widget _buildFullScreenVideo(
      BuildContext context,
      Animation<double> animation,
      _ChewieControllerProvider controllerProvider) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      _ChewieControllerProvider controllerProvider) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      ) {
    var controllerProvider = _ChewieControllerProvider(
      controller: widget.controller,
      child: PlayerWithControls(),
    );

    if (widget.controller.routePageBuilder == null) {
      return _defaultRoutePageBuilder(
          context, animation, secondaryAnimation, controllerProvider);
    }
    return widget.controller.routePageBuilder(
        context, animation, secondaryAnimation, controllerProvider);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final isMobile = Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS;
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    SystemChrome.setEnabledSystemUIOverlays([]);
    if (isMobile) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
//      AutoOrientation.landscapeAutoMode();
    }

    if (!widget.controller.allowedScreenSleep && isMobile) {
      Wakelock.enable();
    }
    if (widget.beforeFullScreen != null) widget.beforeFullScreen();
    await Navigator.of(context, rootNavigator: true).push(route);

    if (widget.afterFullScreen != null) widget.afterFullScreen();
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    if (isMobile) {
      Wakelock.disable();
    }

    SystemChrome.setEnabledSystemUIOverlays(
        widget.controller.systemOverlaysAfterFullScreen);
    SystemChrome.setPreferredOrientations(
        widget.controller.deviceOrientationsAfterFullScreen);
//    AutoOrientation.portraitAutoMode();
  }
}

/// The ChewieController is used to configure and drive the Chewie Player
/// Widgets. It provides methods to control playback, such as [pause] and
/// [play], as well as methods that control the visual appearance of the player,
/// such as [enterFullScreen] or [exitFullScreen].
///
/// In addition, you can listen to the ChewieController for presentational
/// changes, such as entering and exiting full screen mode. To listen for
/// changes to the playback, such as a change to the seek position of the
/// player, please use the standard information provided by the
/// `VideoPlayerController`.
class ChewieController extends ChangeNotifier {
  ChewieController({
    this.videoPlayerController,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.materialProgressColors,
    this.placeholder,
    this.overlay,
    this.showControlsOnInitialize = true,
    this.showControls = true,
    this.customControls,
    this.errorBuilder,
    this.allowedScreenSleep = true,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.isCheckConnectivity = true,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    this.routePageBuilder,
    this.initComplete,
  }) : assert(videoPlayerController != null,
  'You must provide a controller to play a video') {
    _initialize();
  }
  
  final void Function() initComplete;

  /// The controller for the video you want to play
  final VideoPlayerController videoPlayerController;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Weather or not to show the controls when initializing the widget.
  final bool showControlsOnInitialize;

  /// Whether or not to show the controls at all
  final bool showControls;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget customControls;

  /// When the video playback runs  into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String errorMessage) errorBuilder;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double aspectRatio;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final ChewieProgressColors materialProgressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  /// A widget which is placed between the video and the controls
  final Widget overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the fullscreen control should be shown
  final bool allowFullScreen;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  final bool isCheckConnectivity;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  final ChewieRoutePageBuilder routePageBuilder;

  static ChewieController of(BuildContext context) {
    final chewieControllerProvider = context.dependOnInheritedWidgetOfExactType<_ChewieControllerProvider>();

    return chewieControllerProvider.controller;
  }

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  bool _isWifi;

  bool get isWifi => _isWifi;

  bool get isPlaying => videoPlayerController.value.isPlaying;

  final Connectivity _connectivity = Connectivity();
  
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }
    await setNetState(result == ConnectivityResult.wifi);
  }

  Future<void> _initialize() async {
    await videoPlayerController.setLooping(looping);
    /// 判断是否需要检测网络环境
    if (isCheckConnectivity) {
      /// 等待网络为wifi时初始化
      _initConnectivity();
    } else {
      await _initPlayer();
    }
    
    if (fullScreenByDefault) {
      enterFullScreen();
      videoPlayerController.addListener(_fullScreenListener);
    }
  }
  
  Future<void> _initPlayer() async {
    if ((autoInitialize || autoPlay) && !videoPlayerController.value.initialized) {
      await videoPlayerController.initialize();
      if (initComplete != null) {
        initComplete();
      }

      if (autoPlay) {
        await play();
      }

      if (startAt != null) {
        await seekTo(startAt);
      }
    }
  }

  Future<void> _fullScreenListener() async {
    if (isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  Future<void> setNetState(bool isWifi) async {
    if (isWifi == _isWifi) {
      // 避免重复操作
      return;
    }
    _isWifi = isWifi;
    notifyListeners();
    if (isWifi) {
      /// 如果为wifi，检查是否初始化。没有则初始化，有则直接播放。
      if (!videoPlayerController.value.initialized) {
        await videoPlayerController.initialize();
        if (initComplete != null) {
          initComplete();
        }
        
        if (startAt != null) {
          await seekTo(startAt);
        }
        
        if (autoPlay) {
          await play();
        }
        
      } else {
        await play();
      }
    } else {
      /// 不为wifi则暂停播放 
      await pause();
    }
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  void togglePause() {
    isPlaying ? pause() : play();
  }

  Future<void> prepare() async {
    await videoPlayerController.prepare();
  }

  Future<void> play() async {
    await videoPlayerController.play();
  }

  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await videoPlayerController.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
  }
}

class _ChewieControllerProvider extends InheritedWidget {
  const _ChewieControllerProvider({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        assert(child != null),
        super(key: key, child: child);

  final ChewieController controller;

  @override
  bool updateShouldNotify(_ChewieControllerProvider old) =>
      controller != old.controller;
}
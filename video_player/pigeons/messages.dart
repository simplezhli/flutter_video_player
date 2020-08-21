import 'package:pigeon/pigeon_lib.dart';

class TextureMessage {
  int textureId;
}

class LoopingMessage {
  int textureId;
  bool isLooping;
}

class VolumeMessage {
  int textureId;
  double volume;
}

class PositionMessage {
  int textureId;
  int position;
}

class BrightnessMessage {
  int textureId;
  double screenBrightness;
}

class CreateMessage {
  String asset;
  String uri;
  String packageName;
  String formatHint;
}

@HostApi()
abstract class VideoPlayerApi {
  void initialize();
  TextureMessage create(CreateMessage msg);
  void dispose(TextureMessage msg);
  void setLooping(LoopingMessage msg);
  void setVolume(VolumeMessage msg);
  void setBrightness(VolumeMessage msg);
  void setSpeed(VolumeMessage msg);
  BrightnessMessage getBrightness(TextureMessage msg);
  void play(TextureMessage msg);
  void prepare(TextureMessage msg);
  void stop(TextureMessage msg);
  void reload(TextureMessage msg);
  void snapshot(TextureMessage msg);
  void setScaleMode(PositionMessage msg);
  void setMirrorMode(PositionMessage msg);
  void selectTrack(PositionMessage msg);
  PositionMessage position(TextureMessage msg);
  void seekTo(PositionMessage msg);
  void pause(TextureMessage msg);
}

void configurePigeon(PigeonOptions opts) {
  opts.dartOut = '../video_player_platform_interface/lib/messages.dart';
  opts.objcHeaderOut = 'ios/Classes/messages.h';
  opts.objcSourceOut = 'ios/Classes/messages.m';
  opts.objcOptions.prefix = 'FLT';
  opts.javaOut =
      'android/src/main/java/io/flutter/plugins/videoplayer/Messages.java';
  opts.javaOptions.package = 'io.flutter.plugins.videoplayer';
}


/// flutter pub run pigeon  --input pigeons/messages.dart
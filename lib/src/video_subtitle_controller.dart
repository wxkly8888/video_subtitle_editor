import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:video_subtitle_editor/src/utils/subtitle/asset_subtitle.dart';
import 'package:video_subtitle_editor/src/utils/mysubtitle_controller.dart';

import 'models/subtitle.dart';

class VideoSubtitleController extends ChangeNotifier {

  /// Video from [File].
  final File videoFile;

  final VideoPlayerController _video;

  List<Subtitle> _subtitles = [];

  List<Subtitle> get subtitles => _subtitles;

  Subtitle? subtitle;
  get currentSubtitle => subtitle;

  Subtitle? highlightSubtitle;

  /// Get the [VideoPlayerController]
  VideoPlayerController get video => _video;


  /// Get the [VideoPlayerController.value.initialized]
  bool get initialized => _video.value.isInitialized;

  /// Get the [VideoPlayerController.value.isPlaying]
  bool get isPlaying => _video.value.isPlaying;

  /// Get the [VideoPlayerController.value.position]
  Duration get videoPosition => _video.value.position;

  /// Get the [VideoPlayerController.value.duration]
  Duration get videoDuration => _video.value.duration;

  /// Get the [VideoPlayerController.value.size]
  Size get videoDimension => _video.value.size;
  double get videoWidth => videoDimension.width;
  double get videoHeight => videoDimension.height;

  /// Constructs a [VideoSubtitleController] that edits a video from a file.
  ///
  /// The [videoFile] argument must not be null.
  VideoSubtitleController.file(
      this.videoFile)  : _video = VideoPlayerController.file(File(
    // https://github.com/flutter/flutter/issues/40429#issuecomment-549746165
    Platform.isIOS ? Uri.encodeFull(videoFile.path) : videoFile.path,
  ));



  getSubtitleFromTimeStamp(Duration timestamp) {
    for(int i = 0; i < _subtitles.length; i++) {
      if(_subtitles[i].start <= timestamp && _subtitles[i].end >= timestamp) {
        return _subtitles[i];
      }
    }
    return null;
  }
  Future<void> initialize() async {
    await _video.initialize();
    _video.addListener(_videoListener);
    _video.setLooping(true);
    var subtitlePath = "assets/test.srt";
    var controller = MySubtitleController(
      provider: AssetSubtitle(subtitlePath),
    );
    await controller.initial();
    _subtitles = controller.getAllTitles();
    notifyListeners();
  }


  void _videoListener() {
    seekSubtitleTo(videoPosition);
  }

  void seekSubtitleTo(Duration timestamp) {
    subtitle = getSubtitleFromTimeStamp(timestamp);
    notifyListeners();
  }
   seekTo(Duration timestamp) async{
    await _video.seekTo(timestamp);
    seekSubtitleTo(timestamp);
  }
  void setSubtitleIndex(int index) {
    notifyListeners();
  }
}
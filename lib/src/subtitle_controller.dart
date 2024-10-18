import 'package:flutter/cupertino.dart';
import 'package:subtitle/subtitle.dart';
import 'package:video_subtitle_editor/src/utils/asset_subtitle.dart';
import 'utils/mysubtitle_controller.dart';

class VideoSubtitleController extends ChangeNotifier {

  List<Subtitle> _subtitles = [];

  List<Subtitle> get subtitles => _subtitles;

  Subtitle? subtitle;
  get currentSubtitle => subtitle;

  getSubtitleFromTimeStamp(Duration timestamp) {
    for(int i = 0; i < _subtitles.length; i++) {
      if(_subtitles[i].start <= timestamp && _subtitles[i].end >= timestamp) {
        return _subtitles[i];
      }
    }
    return null;
  }

  Future<void> initialize(String path) async {

    var controller = MySubtitleController(
      provider: AssetSubtitle(path),
    );
    await controller.initial();
    _subtitles = controller.getAllTitles();
  }
  void seekTo(Duration timestamp) {
   subtitle = getSubtitleFromTimeStamp(timestamp);
   notifyListeners();
  }

  void setSubtitleIndex(int index) {
    notifyListeners();
  }
}

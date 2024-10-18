import 'package:flutter/cupertino.dart';
import 'package:subtitle/subtitle.dart';
import 'package:video_subtitle_editor/src/utils/asset_subtitle.dart';
import 'utils/mysubtitle_controller.dart';

class VideoSubtitleController extends ChangeNotifier {
  int _subtitleIndex = 0;

  int get subtitleIndex => _subtitleIndex;
  List<Subtitle> _subtitles = [];

  List<Subtitle> get subtitles => _subtitles;

  get currentSubtitle => _subtitles[_subtitleIndex];

  Future<void> initialize(String path) async {

    var controller = MySubtitleController(
      provider: AssetSubtitle(path),
    );
    await controller.initial();
    _subtitles = controller.getAllTitles();
  }

  void setSubtitleIndex(int index) {
    _subtitleIndex = index;
    notifyListeners();
  }
}

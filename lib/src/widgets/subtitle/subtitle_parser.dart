import 'package:subtitle/subtitle.dart';

import '../../../video_subtitle_editor.dart';
import '../../utils/asset_subtitle.dart';
import '../../utils/mysubtitle_controller.dart';

Stream<List<Subtitle>> generateSubtitles(
    VideoEditorController controller) async* {
  print("generateSubtitles called");
  var path = 'assets/test.srt';
  var controller = MySubtitleController(
    provider: AssetSubtitle(path),
  );
  await controller.initial();
  List<Subtitle> subtitles = controller.getAllTitles();
  print("subtitles size:${subtitles.length}");
  yield subtitles;
}

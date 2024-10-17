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
  yield subtitles;
  //! By using objects
  // var object = SubtitleObject(
  //   data: vttData,
  //   type: SubtitleType.vtt,
  // );
  // var parser = SubtitleParser(object);
  // printResult(parser.parsing());
  //
  // for (int i = 1; i <= quantity; i++) {
  //   subtitleList.add("subtitle:${(eachPart * i).toInt()}");
  //  yield subtitleList;
  // }
}

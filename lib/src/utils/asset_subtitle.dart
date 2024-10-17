import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:subtitle/subtitle.dart';

class AssetSubtitle extends SubtitleProvider {
  /// The subtitle path in your assets.
  final String path;
  final SubtitleType? type;

  const AssetSubtitle(
      this.path, {
        this.type,
      });

  @override
  Future<SubtitleObject> getSubtitle() async {
    // Preparing subtitle file data by reading the file.
    // final data = await rootBundle.loadString(path);
    final data =  await rootBundle.loadString("assets/test.srt");
    print("srt data1111111:$data");
    // Find the current format type of subtitle.
    final ext = extension(path);
    final type = this.type ?? getSubtitleType(ext);

    return SubtitleObject(data: data, type: type);
  }
}
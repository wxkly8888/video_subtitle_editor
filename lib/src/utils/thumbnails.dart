import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:subtitle/subtitle.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/models/cover_data.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'asset_subtitle.dart';
import 'mysubtitle_controller.dart';

Stream<List<Uint8List>> generateTrimThumbnails(
  VideoEditorController controller, {
  required int quantity,
}) async* {
  final String path = controller.file.path;
  final double eachPart = controller.videoDuration.inMilliseconds / quantity;
  List<Uint8List> byteList = [];

  for (int i = 1; i <= quantity; i++) {
    try {
      final Uint8List? bytes = await VideoThumbnail.thumbnailData(
        imageFormat: ImageFormat.JPEG,
        video: path,
        timeMs: (eachPart * i).toInt(),
        quality: controller.trimThumbnailsQuality,
      );
      if (bytes != null) {
        byteList.add(bytes);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    yield byteList;
  }
}

Stream<List<Subtitle>> generateSubtitles(
    VideoEditorController controller) async* {
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

Stream<List<CoverData>> generateCoverThumbnails(
  VideoEditorController controller, {
  required int quantity,
}) async* {
  final int duration = controller.isTrimmed
      ? controller.trimmedDuration.inMilliseconds
      : controller.videoDuration.inMilliseconds;
  final double eachPart = duration / quantity;
  List<CoverData> byteList = [];

  for (int i = 0; i < quantity; i++) {
    try {
      final CoverData bytes = await generateSingleCoverThumbnail(
        controller.file.path,
        timeMs: (controller.isTrimmed
                ? (eachPart * i) + controller.startTrim.inMilliseconds
                : (eachPart * i))
            .toInt(),
        quality: controller.coverThumbnailsQuality,
      );

      if (bytes.thumbData != null) {
        byteList.add(bytes);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    yield byteList;
  }
}

/// Generate a cover at [timeMs] in video
///
/// Returns a [CoverData] depending on [timeMs] milliseconds
Future<CoverData> generateSingleCoverThumbnail(
  String filePath, {
  int timeMs = 0,
  int quality = 10,
}) async {
  final Uint8List? thumbData = await VideoThumbnail.thumbnailData(
    imageFormat: ImageFormat.JPEG,
    video: filePath,
    timeMs: timeMs,
    quality: quality,
  );

  return CoverData(thumbData: thumbData, timeMs: timeMs);
}

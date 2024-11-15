import 'dart:io';

import 'package:ffmpeg_kit_flutter_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_video/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_video/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_video/return_code.dart';
import 'package:ffmpeg_kit_flutter_video/statistics.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  static Future<void> dispose() async {
    final executions = await FFmpegKit.listSessions();
    if (executions.isNotEmpty) await FFmpegKit.cancel();
  }

  static Future<String> createTempSubtitleFile(String subtitleContent) async {
    final directory = await getApplicationCacheDirectory();
    final file = File('${directory.path}/temp_subtitles.srt');
    await file.writeAsString(subtitleContent);
    return file.path;
  }

  //generate the output generated video file path
  static Future<String> generateOutputPath() async {
    final directory = await getApplicationCacheDirectory();
    const outputName = 'subtitled.mp4';
    return '${directory.path}/$outputName';
  }

  //how to export sounds from video
  static Future<FFmpegSession> exportAudio({
    required String videoPath,
    required String outputPath,
    required void Function(File file) onCompleted,
    Duration? startTime,
    Duration? endTime,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) {
    var command = [
      '-i', videoPath,
      '-vn',
      '-y', // Add this flag to overwrite the existing file
    ];
    // Add start time if provided
    if (startTime != null) {
      command.addAll(['-ss', startTime.inSeconds.toString()]);
    }

    // Add end time if provided
    if (endTime != null) {
      command.addAll(['-to', endTime.inSeconds.toString()]);
    }
    // Specify the output path
    command.add(outputPath);
    return FFmpegKit.executeWithArgumentsAsync(
      command,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (ReturnCode.isSuccess(code)) {
          onCompleted(File(outputPath));
        } else {
          if (onError != null) {
            onError(
              Exception(
                  'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}'),
              StackTrace.current,
            );
          }
          return;
        }
      },
      null,
      onProgress,
    );
  }

  static Future<FFmpegSession> exportVideoWithSubtitles({
    required String videoPath,
    required String subtitlePath,
    required String outputPath,
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) {
    final command = [
      '-i', videoPath,
      '-vf', "subtitles=$subtitlePath",
      '-y', // Add this flag to overwrite the existing file
      outputPath
    ]; // log('FFmpeg start process with command = ${execute.command}');
    return FFmpegKit.executeWithArgumentsAsync(
      command,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (ReturnCode.isSuccess(code)) {
          onCompleted(File(outputPath));
        } else {
          if (onError != null) {
            onError(
              Exception(
                  'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}'),
              StackTrace.current,
            );
          }
          return;
        }
      },
      null,
      onProgress,
    );
  }
}

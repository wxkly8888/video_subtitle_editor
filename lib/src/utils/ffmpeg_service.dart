import 'dart:io';
import 'dart:ui';

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_full/statistics.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../video_subtitle_editor.dart';

class FFmpegService {
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

  static Future<void> resizeVideoWithPadding({
    required double resizedRatio,
    required String videoPath,
    required String outputPath,
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) async {
    final command = [
      '-i', videoPath,
      '-vf',
      'scale=iw*min($resizedRatio/iw\\,1):ih*min($resizedRatio/iw\\,1), pad=$resizedRatio:ih:(ow-iw)/2:(oh-ih)/2',
      '-y', // Overwrite the existing file
      outputPath
    ];

    final session = await FFmpegKit.executeWithArgumentsAsync(
      command,
      (session) async {
        final state = await session.getState();
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
        }
      },
      null,
      onProgress,
    );
  }

  static Future<FFmpegSession> generateThumbnail({
    required String videoPath,
    required String outputPath,
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) {
    final command = [
      '-i', videoPath,
      '-ss', '00:00:01',
      '-vframes', '1',
      '-y', // Add this flag to overwrite the existing file
      outputPath
    ];
    printCommand(command);

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
    printCommand(command);

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
  static void printCommand(List<String> commandList){
    String sb = "ffmpeg";
    for(int i = 0; i < commandList.length; i++){
      sb += " ${commandList[i]}";
    }
    //print commands
    print("export command: $sb");
  }

  static Future<void> copyFontFilesAndRegisterFFmpeg(String assetPath, List fontFiles) async {
    final tempDir = await getTemporaryDirectory();
    final fontDir = Directory('${tempDir.path}/fonts');
    if (!await fontDir.exists()) {
      await fontDir.create(recursive: true);
    }
    for (final fontFile in fontFiles) {
      final file = File('${fontDir.path}/$fontFile');
      if(await file.exists()){
        continue;
      }
      final byteData = await rootBundle.load('$assetPath/$fontFile');
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
    await FFmpegKitConfig.setFontDirectory(fontDir.path,{});
    print('Font directories registered successfully.');
  }

  /**
   * const List<String> videoResolutions = [
      "1920x1080",
      "1280x720",
      "854x480",
      ];

   */
  static getWidthFromResolution(String resolution){
    return int.parse(resolution.split("x")[0]);
  }
  static getHeightFromResolution(String resolution){
    return int.parse(resolution.split("x")[1]);
  }
  static Future<FFmpegSession> exportVideoWithSubtitles({
    required String videoPath,
    required String subtitlePath,
    required String outputPath,
    required void Function(File file) onCompleted,
    double width = 1280,
    double height = 720,
    int? frameRate,
    String? resolution,
    String? format,
    SubtitleStyle? subtitleStyle,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) async {
    try {
      // Convert SRT to ASS with styles if style is provided
      String finalSubtitlePath = subtitlePath.replaceAll("srt", "ass");
      if (subtitleStyle != null) {
        await convertSrtToAss(
          srtPath: subtitlePath,
          assPath: finalSubtitlePath,
          style: subtitleStyle,
          height:height,
          width: width,
          resolution: resolution??"1280x720"
        );
      }

      final command = [
        '-i', videoPath,
        '-vf', 'subtitles=$finalSubtitlePath',
        if (frameRate != null) ...['-r', frameRate.toString()],
        if (resolution != null) ...['-s', resolution],
        '-c:v', 'mpeg4',
        '-q:v', '2',
        '-c:a', 'aac',
        '-b:a', '128k',
        '-y',
        outputPath,
      ];

      if (format != null) {
        command.addAll(['-f', format]);
      }

      printCommand(command);
      return await FFmpegKit.executeWithArgumentsAsync(
        command,
        (session) async {
          final state = FFmpegKitConfig.sessionStateToString(await session.getState());
          final code = await session.getReturnCode();
          final output = await session.getOutput();
          print("FFmpeg output: $output");

          if (ReturnCode.isSuccess(code)) {
            onCompleted(File(outputPath));
          } else {
            if (onError != null) {
              onError(
                Exception('FFmpeg process exited with state $state and return code $code.\n$output'),
                StackTrace.current,
              );
            }
          }
        },
        (log) => print("FFmpeg log: ${log.getMessage()}"),
        onProgress,
      );
    } catch (e, s) {
      print("FFmpeg exception: $e");
      if (onError != null) {
        onError(e, s);
      }
      throw e;
    }
  }

  static Future<void> convertSrtToAss({
    required String srtPath,
    required String assPath,
    required String resolution,
    required SubtitleStyle style,
    double height = 720,
    double width = 1280,
  }) async {
    final srtFile = File(srtPath);
    final assFile = File(assPath);

    if (!await srtFile.exists()) {
      throw Exception('SRT file does not exist');
    }
    double rate = height/getHeightFromResolution(resolution);
    final srtContent = await srtFile.readAsString();
    final assContent = _convertSrtContentToAss(srtContent, style, rate);
    await assFile.writeAsString(assContent);
  }
 static String _convertSrtContentToAss(String srtContent, SubtitleStyle style, double rate) {
   final relativeBottom = (style.position.bottom / rate) ;
    final buffer = StringBuffer();
    // Write ASS header
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: Converted Subtitle');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('Collisions: Normal');
    buffer.writeln('PlayDepth: 0');
    buffer.writeln('Timer: 100.0000');
    buffer.writeln('');
    buffer.writeln('[V4+ Styles]');
    buffer.writeln('Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');
    buffer.writeln('Style: Default,${style.font},${style.fontSize},&H${_colorToASSFormat(style.textColor)},&H${_colorToASSFormat(style.textColor)},&H${_colorToASSFormat(style.outlineColor)},&H${_colorToASSFormat(style.backgroundColor)},${style.bold ? 1 : 0},${style.italic ? 1 : 0},0,0,100,100,0,0,1,${style.outlineWidth},0,2,10,10,${relativeBottom},1');
    buffer.writeln('');
    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    // Convert SRT to ASS format
    final srtLines = srtContent.split('\n');
    for (var i = 0; i < srtLines.length; i++) {
      if (RegExp(r'^\d+$').hasMatch(srtLines[i])) {
        final startEnd = srtLines[++i].split(' --> ');
        final start = _convertSrtTimeToAssTime(startEnd[0]);
        final end = _convertSrtTimeToAssTime(startEnd[1]);
        final text = srtLines[++i].replaceAll('\n', '\\N');
        buffer.writeln('Dialogue: 0,$start,$end,Default,,0,0,0,,$text');
      }
    }

    return buffer.toString();
  }

  static String _convertSrtTimeToAssTime(String srtTime) {
    var parts = srtTime.split(',');

    final timeParts = parts[0].split(':');
    if(parts[1].length==3){
      parts[1] = parts[1].substring(0,1);
    }
    return '${timeParts[0]}:${timeParts[1]}:${timeParts[2]}.${parts[1]}';
  }

  static String _colorToASSFormat(Color color) {
    return '${color.blue.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.red.toRadixString(16).padLeft(2, '0')}';
  }

}

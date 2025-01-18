import 'dart:io';
import 'dart:ui';

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_full/statistics.dart';
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
  static Future<FFmpegSession> exportVideoWithSubtitles({
    required String videoPath,
    required String subtitlePath,
    required String outputPath,
    required void Function(File file) onCompleted,
    int? frameRate,
    String? resolution,
    String? format,
    SubtitleStyle? subtitleStyle,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) async {
    try {
      // Convert SRT to ASS with styles if style is provided
      String finalSubtitlePath = subtitlePath;
      if (subtitleStyle != null) {
        finalSubtitlePath = await convertSrtToAss(
          srtPath: subtitlePath,
          style: subtitleStyle,
        );
      }

      FFmpegKitConfig.setFontDirectoryList(["/system/fonts", "/System/Library/Fonts", "/assets/fonts"]);
      
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

  static Future<String> convertSrtToAss({
    required String srtPath,
    required SubtitleStyle style,
  }) async {
    final assPath = srtPath.replaceAll('.srt', '.ass');
    
    try {
      // Build the subtitle conversion command with styles
      final command = [
        '-i', srtPath,
        '-vf', 'subtitles=$srtPath:force_style=\'Fontname=${style.font},'
              'FontSize=${style.fontSize},'
              'PrimaryColour=&H${_colorToASSFormat(style.textColor)},'
              'OutlineColour=&H${_colorToASSFormat(style.outlineColor)},'
              'BackColour=&H${_colorToASSFormat(style.backgroundColor)},'
              'Bold=${style.bold ? 1 : 0},'
              'Italic=${style.italic ? 1 : 0},'
              'BorderStyle=3,'
              'Outline=${style.outlineWidth}\'',
        '-y',
        assPath
      ];

      printCommand(command);
      
      final session = await FFmpegKit.execute(command.join(' '));
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return assPath;
      } else {
        final output = await session.getOutput();
        print('FFmpeg conversion output: $output');
        throw Exception('Failed to convert SRT to ASS: $output');
      }
    } catch (e) {
      print('Error converting SRT to ASS: $e');
      // Clean up temp file in case of error
      throw e;
    }
  }

  // Helper method to convert Color to ASS format (AABBGGRR)
  static String _colorToASSFormat(Color color) {
    return '${color.alpha.toRadixString(16).padLeft(2, '0')}'
           '${color.blue.toRadixString(16).padLeft(2, '0')}'
           '${color.green.toRadixString(16).padLeft(2, '0')}'
           '${color.red.toRadixString(16).padLeft(2, '0')}';
  }
}

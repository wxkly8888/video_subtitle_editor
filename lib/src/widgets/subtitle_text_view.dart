import 'package:flutter/material.dart';
import 'package:video_subtitle_editor/src/widgets/subtitle/style/subtitle_style.dart';
import 'package:video_subtitle_editor/video_subtitle_editor.dart';

class SubtitleTextView extends StatefulWidget {
  const SubtitleTextView({
    required this.subtitleController,
    required this.videoController,
    this.subtitleStyle = const SubtitleStyle(),
    super.key,
    this.backgroundColor,
  });

  final SubtitleStyle subtitleStyle;
  final Color? backgroundColor;
  final VideoSubtitleController subtitleController;
  final VideoEditController videoController;

  @override
  State<StatefulWidget> createState() {
    return _SubtitleTextViewState();
  }
}

class _SubtitleTextViewState extends State<SubtitleTextView> {
  SubtitleStyle get subtitleStyle => widget.subtitleStyle;

  VideoSubtitleController get subtitleController => widget.subtitleController;

  VideoEditController get videoController => widget.videoController;

  Color? get backgroundColor => widget.backgroundColor;

  @override
  void initState() {
    super.initState();
    subtitleController.addListener(_update);
    videoController.video.addListener(_updateSubtitleFromVideo);
  }

  _update() {
    setState(() {});
  }

  _updateSubtitleFromVideo() {
        final videoPlayerPosition = videoController.video.value.position;
        print("UI: videoPlayerPosition: $videoPlayerPosition");
        subtitleController.seekTo(videoPlayerPosition);
  }

  TextStyle get _textStyle {
    return subtitleStyle.hasBorder
        ? TextStyle(
            fontSize: subtitleStyle.fontSize,
            foreground: Paint()
              ..style = subtitleStyle.borderStyle.style
              ..strokeWidth = subtitleStyle.borderStyle.strokeWidth
              ..color = subtitleStyle.borderStyle.color,
          )
        : TextStyle(
            fontSize: subtitleStyle.fontSize,
            color: subtitleStyle.textColor,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: Container(
            color: backgroundColor,
            child: _TextContent(
              text: subtitleController.currentSubtitle?.data ?? "",
              textStyle: _textStyle,
            ),
          ),
        ),
        if (subtitleStyle.hasBorder)
          Center(
            child: Container(
              color: backgroundColor,
              child: _TextContent(
                text: subtitleController.currentSubtitle?.data ?? "",
                textStyle: TextStyle(
                  color: subtitleStyle.textColor,
                  fontSize: subtitleStyle.fontSize,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TextContent extends StatelessWidget {
  const _TextContent({
    required this.textStyle,
    required this.text,
  });

  final TextStyle textStyle;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: textStyle,
    );
  }
}

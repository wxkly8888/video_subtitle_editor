import 'package:flutter/material.dart';
import 'package:video_subtitle_editor/src/widgets/style/subtitle_style.dart';
import 'package:video_subtitle_editor/video_subtitle_editor.dart';

import 'dashline_text.dart';
import 'style/subtitle_position.dart';

class SubtitleTextView extends StatefulWidget {
  SubtitleTextView({
    required this.controller,
    super.key,
    this.backgroundColor,
    SubtitleStyle? subtitleStyle,
  }) : subtitleStyle = subtitleStyle ?? SubtitleStyle(); // Initialize here

  final SubtitleStyle subtitleStyle;
  final Color? backgroundColor;
  final VideoSubtitleController controller;

  @override
  State<StatefulWidget> createState() {
    return _SubtitleTextViewState();
  }
}

class _SubtitleTextViewState extends State<SubtitleTextView> {
  SubtitleStyle get subtitleStyle => widget.subtitleStyle;

  VideoSubtitleController get videoSubtitleController => widget.controller;

  Color? get backgroundColor => widget.backgroundColor;

  @override
  void initState() {
    super.initState();
    videoSubtitleController.addListener(_update);
  }

  _update() {
    print("update subtitle text view");
    if (mounted) setState(() {});
  }

  // TextStyle get _textStyle {
  //   return subtitleStyle.hasBorder
  //       ? TextStyle(
  //           fontSize: subtitleStyle.fontSize,
  //           color: subtitleStyle.textColor,
  //           fontFamily: subtitleStyle.font,
  //           foreground: Paint()
  //             ..style = subtitleStyle.borderStyle.style
  //             ..strokeWidth = subtitleStyle.borderStyle.strokeWidth
  //             ..color = subtitleStyle.borderStyle.color,
  //         )
  //       : TextStyle(
  //           fontSize: subtitleStyle.fontSize,
  //           color: subtitleStyle.textColor,
  //           fontFamily: subtitleStyle.font,
  //         );
  // }

  @override
  Widget build(BuildContext context) {
    return videoSubtitleController.currentSubtitle == null
        ? Container()
        : Stack(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(bottom: subtitleStyle.position.bottom),
                  child: GestureDetector(
                      onPanUpdate: (details) {
                        if (!subtitleStyle.hasBorder) return;
                        setState(() {
                          subtitleStyle.position.bottom =
                              subtitleStyle.position.bottom - details.delta.dy;
                          if(subtitleStyle.position.bottom < 0) {
                            subtitleStyle.position.bottom = 0;
                          }else if(subtitleStyle.position.bottom >videoSubtitleController.videoHeight/2)  {
                            subtitleStyle.position.bottom = videoSubtitleController.videoHeight/2;
                          }
                        });
                      },
                      child: Center(
                        child: DashedLineWidget(
                          isVisible: subtitleStyle.hasBorder,
                          child: _TextContent(
                            text:
                                videoSubtitleController.currentSubtitle?.data ??
                                    "",
                            textStyle: TextStyle(
                              fontSize: subtitleStyle.fontSize,
                              color: subtitleStyle.textColor,
                              fontFamily: subtitleStyle.font,
                            ),
                          ),
                        ),
                      ))),
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

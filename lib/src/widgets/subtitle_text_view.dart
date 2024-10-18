import 'package:flutter/material.dart';
import 'package:subtitle/subtitle.dart';
import 'package:video_subtitle_editor/src/widgets/subtitle/style/subtitle_style.dart';

class SubtitleTextView extends StatelessWidget {
  const SubtitleTextView({
    required this.subtitleStyle,
    required this.subtitle,
    super.key,
    this.backgroundColor,
  });
  final SubtitleStyle subtitleStyle;
  final Color? backgroundColor;
  final Subtitle subtitle;
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
                    text:subtitle.data,
                    textStyle: _textStyle,
                  ),
                ),
              ),
              if (subtitleStyle.hasBorder)
                Center(
                  child: Container(
                    color: backgroundColor,
                    child: _TextContent(
                      text:subtitle.data,
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

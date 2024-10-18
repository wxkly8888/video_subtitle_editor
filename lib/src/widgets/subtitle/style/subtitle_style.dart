import 'package:flutter/material.dart';
import 'package:video_subtitle_editor/src/widgets/subtitle/style/subtitle_border_style.dart';
import 'package:video_subtitle_editor/src/widgets/subtitle/style/subtitle_position.dart';

const _defaultFontSize = 16.0;

class SubtitleStyle {
  const SubtitleStyle({
    this.hasBorder = false,
    this.borderStyle = const SubtitleBorderStyle(),
    this.fontSize = _defaultFontSize,
    this.textColor = Colors.white,
    this.position = const SubtitlePosition(),
  });
  final bool hasBorder;
  final SubtitleBorderStyle borderStyle;
  final double fontSize;
  final Color textColor;
  final SubtitlePosition position;
}

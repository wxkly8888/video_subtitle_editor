import 'package:flutter/material.dart';
import 'package:video_subtitle_editor/src/widgets/style/subtitle_position.dart';

import 'subtitle_border_style.dart';

const _defaultFontSize = 16.0;

class SubtitleStyle {
  SubtitleStyle({
    this.hasBorder = false,
    this.borderStyle = const SubtitleBorderStyle(),
    this.fontSize = _defaultFontSize,
    this.font = 'Arial',
    this.textColor = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.outlineColor = Colors.black,
    SubtitlePosition? position,
  }) : position = position ?? SubtitlePosition();  // Remove const

  final bool hasBorder;
  final SubtitleBorderStyle borderStyle;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final Color outlineColor;
  final String font;
  final bool bold = false;
  final bool italic = false;
  final double outlineWidth = 1.0;
  final SubtitlePosition position;  // Keep final, but the object itself is mutable
}
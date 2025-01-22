const _defaultSubtitleBottomPosition = 50.0;

class SubtitlePosition {
  SubtitlePosition({
    this.left = 0.0,
    this.right = 0.0,
    this.top,
    double bottom = _defaultSubtitleBottomPosition,
  }) : _bottom = bottom;

  final double left;
  final double right;
  final double? top;
  double _bottom;
  
  double get bottom => _bottom;
  set bottom(double value) {
    _bottom = value;
  }
}
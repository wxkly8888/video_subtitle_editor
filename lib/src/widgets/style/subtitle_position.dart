enum LayoutType { bottom, center, top }

class SubtitlePosition {
  SubtitlePosition({
    this.left = 0.0,
    this.right = 0.0,
    this.top = 0.0,
    this.bottom = 0.0,
    this.layoutType = LayoutType.bottom,
  });
  LayoutType layoutType = LayoutType.bottom;
  final double left;
  final double right;
  double top;
  double bottom;
  //set top
  set setTop(double value) {
    top = value;
  }

  //set bottom
  set setBottom(double value) {
    bottom = value;
  }
}

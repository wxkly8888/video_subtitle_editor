import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/widgets/trim/subtitle_slider.dart';
import 'package:video_editor/src/widgets/trim/thumbnail_slider.dart';

enum _TrimBoundaries { left, right, inside, progress }

/// Spacing to touch detection, touch target should be minimum 24 x 24 dp
const _touchMargin = 24.0;

class TrimSlider extends StatefulWidget {
  /// Slider that trim video length.
  const TrimSlider({
    super.key,
    required this.controller,
    this.height = 60,
    this.horizontalMargin = 0.0,
    this.child,
    this.hasHaptic = true,
    this.maxViewportRatio = 5,
    this.scrollController,
  });

  /// The [controller] param is mandatory so every change in the controller settings will propagate in the trim slider view
  final VideoEditorController controller;

  /// The [height] param specifies the height of the generated thumbnails
  ///
  /// Defaults to `60`
  final double height;

  /// The [horizontalMargin] param specifies the horizontal space to set around the slider.
  /// It is important when the trim can be dragged (`controller.maxDuration` < `controller.videoDuration`)
  ///
  /// Defaults to `0`
  final double horizontalMargin;

  /// The [child] param can be specify to display a widget below this one (e.g: [TrimTimeline])
  final Widget? child;

  //// The [hasHaptic] param specifies if haptic feed back can be triggered when the trim touch an edge (left or right)
  ///
  /// Defaults to `true`
  final bool hasHaptic;

  /// The [maxViewportRatio] param specifies the upper limit of the view ratio
  /// This param is useful to avoid having a trimmer way too wide, which is not usuable and performances consuming
  ///
  /// The default view port value equals to `controller.videoDuration / controller.maxDuration`
  /// To disable the extended trimmer view, [maxViewportRatio] should be set to `3`
  ///
  /// Defaults to `2.5`
  final double maxViewportRatio;

  //// The [scrollController] param specifies the scroll controller to use for the trim slider view
  final ScrollController? scrollController;

  @override
  State<TrimSlider> createState() => _TrimSliderState();
}

class _TrimSliderState extends State<TrimSlider>
    with AutomaticKeepAliveClientMixin<TrimSlider> {
  _TrimBoundaries? _boundary;

  /// Set to `true` if the video was playing before the gesture
  bool _isVideoPlayerHold = false;

  /// Value of [widget.controller.trimPosition] precomputed by local change
  /// When scrolling the view fast the position can get out of synch
  /// using this param on local change fixes the issue

  Rect _rect = Rect.zero;
  Size _trimLayout = Size.zero;
  Size _fullLayout = Size.zero;

  /// Horizontal margin around the [ThumbnailSlider]
  late final double _horizontalMargin =
      widget.horizontalMargin + widget.controller.trimStyle.edgeWidth;

  late final _viewportRatio = min(
    widget.maxViewportRatio,
    widget.controller.videoDuration.inMilliseconds /
        widget.controller.maxDuration.inMilliseconds,
  );

  // Touch detection

  // Edges touch margin come from it size, but minimum is [margin]
  late final _edgesTouchMargin =
      max(widget.controller.trimStyle.edgeWidth, _touchMargin);

  // Position line touch margin come from it size, but minimum is [margin]
  late final _positionTouchMargin =
      max(widget.controller.trimStyle.positionLineWidth, _touchMargin);

  // Scroll view

  late final ScrollController _scrollController;

  /// The distance of rect left side to the left of the scroll view before bouncing
  double? _preSynchLeft;

  /// The distance of rect right side to the right of the scroll view before bouncing
  double? _preSynchRight;

  /// Save last [_scrollController] pixels position before the bounce animation starts
  double? _lastScrollPixelsBeforeBounce;

  /// Save last [_scrollController] pixels position
  double _lastScrollPixels = 0;

  double scale = 1.0;
  double lastScale = 1.0;
  bool isScaling = false;


  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    //widget.controller.addListener(_updateTrim);
    _scrollController.addListener(attachTrimToScroll);
  }

  @override
  void dispose() {
    //widget.controller.removeListener(_updateTrim);
    _scrollController.removeListener(attachTrimToScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns `false` if the scroll controller is currently bouncing back
  /// to reach either the min scroll extent or the max scroll extent
  bool get isNotScrollBouncingBack {
    final isBouncingFromLeft =
        _scrollController.offset < _scrollController.position.minScrollExtent &&
            _scrollController.offset > _lastScrollPixels;
    final isBouncingFromRight =
        _scrollController.offset > _scrollController.position.maxScrollExtent &&
            _scrollController.offset < _lastScrollPixels;
    return !(isBouncingFromLeft || isBouncingFromRight);
  }

  /// Scroll to update [_rect] and trim values on scroll
  /// Will fix [_rect] to the scroll view when it is bouncing
  void attachTrimToScroll() {
    if (_scrollController.position.isScrollingNotifier.value) {
      print("attachTrimToScroll called");
      // update trim and video position
      _resetControllerPosition();
      _lastScrollPixels = _scrollController.offset;
    }
  }
  @override
  bool get wantKeepAlive => true;

  //--------//
  //GESTURES//
  //--------//

  void _onHorizontalDragEnd([_]) {
    _updateControllerIsTrimming(false);
    if (_boundary == null) return;
    if (_boundary != _TrimBoundaries.progress) {
      _resetControllerPosition();
    }
  }

  void _createTrimRect() {
    _rect = Rect.fromPoints(
      Offset(widget.controller.minTrim * _fullLayout.width, 0.0),
      Offset(widget.controller.maxTrim * _fullLayout.width, widget.height),
    ).shift(Offset(_horizontalMargin, 0));
  }

  /// Reset the video cursor position to fit the rect
  void _resetControllerPosition() async {
    if (_boundary == _TrimBoundaries.progress) return;

    // if the left side changed and overtake the current postion
    if (_boundary == null ||
        _boundary == _TrimBoundaries.inside ||
        _boundary == _TrimBoundaries.left) {
      // reset position to startTrim
      await widget.controller.video.seekTo(widget.controller.startTrim);
    } else if (_boundary == _TrimBoundaries.right) {
      // or if the right side changed and is under the current postion, reset position to endTrim
      // substract 10 milliseconds to avoid the video to loop and to show startTrim
      await widget.controller.video.seekTo(widget.controller.endTrim);
    }
  }

  void _updateControllerIsTrimming(bool value) {
    if (value && widget.controller.isPlaying) {
      _isVideoPlayerHold = true;
      widget.controller.video.pause();
    } else if (_isVideoPlayerHold) {
      _isVideoPlayerHold = false;
      widget.controller.video.play();
    }

    if (_boundary != _TrimBoundaries.progress) {
      widget.controller.isTrimming = value;
    }
    if (value == false) {
      _boundary = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (_, contrainst) {
      final Size trimLayout = Size(
        contrainst.maxWidth - _horizontalMargin * 2,
        contrainst.maxHeight,
      );
      // print("trim slider:trimLayout: $trimLayout");
      _fullLayout = Size(
        trimLayout.width * _viewportRatio * scale,
        contrainst.maxHeight,
      );
      if (_trimLayout != trimLayout) {
        _trimLayout = trimLayout;
        _createTrimRect();
      }

      return SizedBox(
          width: _fullLayout.width,
          child: Stack(children: [
            NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (_boundary == null) {
                  if (scrollNotification is ScrollStartNotification) {
                    _updateControllerIsTrimming(true);
                  } else if (scrollNotification is ScrollEndNotification) {
                    _onHorizontalDragEnd();
                  }
                }
                return true;
              },

                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: isScaling? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                      child: GestureDetector(

                        onScaleEnd: (ScaleEndDetails details) {
                          lastScale = scale;
                          print("last scale update:$scale");
                          setState(() {
                            isScaling = false;
                          });
                        },
                        onScaleStart: (ScaleStartDetails details) {
                          setState(() {
                            isScaling = true;
                          });
                        },
                        onScaleUpdate: (ScaleUpdateDetails details) {
                          if (details.scale != 1.0&& isScaling) {
                            setState(() {
                              scale = lastScale * details.scale;
                              print("onScale update:$scale");
                            });
                          }
                        },
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: _horizontalMargin),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              widget.controller.trimStyle.borderRadius,
                            ),
                            child: SizedBox(
                              height: widget.height,
                              width: _fullLayout.width,
                              child: SubtitleSlider(
                                controller: widget.controller,
                                height: widget.height,
                              ),
                            ),
                          ),
                          if (widget.child != null)
                            SizedBox(
                                width: _fullLayout.width, child: widget.child)
                        ],
                      ),
                    ),
                  )),
            ),
          ]));
    });
  }
}


import 'package:flutter/material.dart';
import 'package:subtitle/subtitle.dart';
import 'package:video_subtitle_editor/src/controller.dart';
import 'package:video_subtitle_editor/src/utils/helpers.dart';
import 'package:video_subtitle_editor/src/widgets/subtitle/subtitle_parser.dart';

class SubtitleSlider extends StatefulWidget {

  const SubtitleSlider({
    super.key,
    required this.controller,

    this.height = 60,
    this.horizontalMargin = 20,
  });

  final double horizontalMargin;

  /// The [height] param specifies the height of the generated thumbnails
  final double height;

  final VideoEditorController controller;

  @override
  State<SubtitleSlider> createState() => _SubtitleSliderState();
}

class _SubtitleSliderState extends State<SubtitleSlider> {
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  /// The max width of [SubtitleSlider]
  double _sliderWidth = 1.0;
  static const double perPixelInSec = 10.0;
  late final ScrollController _scrollController;
  final Size _layout = Size.zero;
  late Size _maxLayout = _calculateMaxLayout();
  late double _horizontalMargin;
  late final Stream<List<Subtitle>> _stream = (() => _generateSubtitles())();


  @override
  void initState() {
    super.initState();
    _horizontalMargin = widget.horizontalMargin;
    calculateSliderWidth(widget.controller);
    widget.controller.addListener(_scaleRect);
    _scrollController = ScrollController();
    //widget.controller.addListener(_updateTrim);
    _scrollController.addListener(attachScroll);
  }
  calculateSliderWidth(VideoEditorController controller){
    final duration = controller.videoDuration.inSeconds;
    _sliderWidth = duration.toDouble()* perPixelInSec;
    print("_sliderWidth: $_sliderWidth");
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scaleRect);
    _rect.dispose();
    super.dispose();
  }

  void _scaleRect() {
    _rect.value = calculateCroppedRect(widget.controller, _layout);
    _maxLayout = _calculateMaxLayout();

  }
  void attachScroll() {
    if (_scrollController.position.isScrollingNotifier.value) {
      print("attachTrimToScroll called offset: ${_scrollController.offset}");
      // update trim and video position
      _controllerSeekTo(_scrollController.offset);
    }
  }
  /// Scroll to update [_rect] and trim values on scroll
  /// Will fix [_rect] to the scroll view when it is bouncing
  /// Sets the video's current timestamp to be at the [position] on the slider
  /// If the expected position is bigger than [controller.endTrim], set it to [controller.endTrim]
  void _controllerSeekTo(double position) async {
    final to = widget.controller.videoDuration *
        ((position + _scrollController.offset) /
            (_sliderWidth + _horizontalMargin * 2));
    await widget.controller.video.seekTo(
        to > widget.controller.endTrim ? widget.controller.endTrim : to);
  }


  Stream<List<Subtitle>> _generateSubtitles() => generateSubtitles(
      widget.controller
  );

  /// Returns the max size the layout should take with the rect value
  Size _calculateMaxLayout() {
    final ratio = _rect.value == Rect.zero
        ? widget.controller.video.value.aspectRatio
        : _rect.value.size.aspectRatio;

    // check if the ratio is almost 1
    if (isNumberAlmost(ratio, 1)) return Size.square(widget.height);

    final size = Size(widget.height * ratio, widget.height);

    if (widget.controller.isRotated) {
      return Size(widget.height / ratio, widget.height);
    }
    return size;
  }
  double computeWidth(Subtitle subtitle){
    final start = subtitle.start.inMilliseconds;
    final end = subtitle.end.inMilliseconds;
    final duration = widget.controller.videoDuration.inMilliseconds;
    final width = (_sliderWidth * (end - start)) / duration;
    return width;
  }
  double computeStartX(Subtitle subtitle){
    final start = subtitle.start.inMilliseconds;
    final duration = widget.controller.videoDuration.inMilliseconds;
    final startX = (_sliderWidth * start) / duration;
    return startX;
  }
  @override
  Widget build(BuildContext context) {
    return
      SingleChildScrollView(
        controller: _scrollController,
        physics:  const BouncingScrollPhysics(),
    scrollDirection: Axis.horizontal,
    child:LayoutBuilder(builder: (_, box) {
      return StreamBuilder<List<Subtitle>>(
        stream: _stream,
        builder: (_, snapshot) {
          final data = snapshot.data;
          if(data==null) return const SizedBox();
          return snapshot.hasData
              ? Padding(padding:
          EdgeInsets.symmetric(horizontal: _horizontalMargin),
          child:  Stack(
            children: data.map((subtitle) {
              double width = computeWidth(subtitle);
              double startX = computeStartX(subtitle);
              return Positioned(
                left: startX,
                child: SizedBox(
                  width: width,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF974836),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      subtitle.data,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ))
              : const SizedBox();
        },
      );
    }));
  }
}

import 'package:flutter/material.dart';
import 'package:video_subtitle_editor/src/models/subtitle.dart';
import 'package:video_subtitle_editor/src/widgets/scale_line.dart';
import 'package:video_subtitle_editor/video_subtitle_editor.dart';

class SubtitleSlider extends StatefulWidget {
  const SubtitleSlider({
    super.key,
    required this.controller,
    this.height = 100,
    this.horizontalMargin = 20,
  });

  final VideoSubtitleController controller;
  final double horizontalMargin;

  /// The [height] param specifies the height of the generated thumbnails
  final double height;

  @override
  State<SubtitleSlider> createState() => _SubtitleSliderState();
}

class _SubtitleSliderState extends State<SubtitleSlider> {
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);

  /// The max width of [SubtitleSlider]
  double _sliderWidth = 1.0;
  static const double perPixelInSec = 100.0;
  static const double touchWidth = 30.0;
  static const double touchHeight = 60.0;

  late final ScrollController _scrollController;
  late double _horizontalMargin;
  late final Stream<List<Subtitle>> _stream = (() => getSubtitles())();

  bool isHighlighted = false;

  @override
  void initState() {
    super.initState();
    _horizontalMargin = widget.horizontalMargin;
    calculateSliderWidth(widget.controller);
    _scrollController = ScrollController();
    _scrollController.addListener(attachScroll);
  }

  calculateSliderWidth(VideoSubtitleController controller) {
    final duration = controller.videoDuration.inSeconds;
    _sliderWidth = duration.toDouble() * perPixelInSec;
    print("UI:_sliderWidth: $_sliderWidth");
  }

  @override
  void dispose() {
    _rect.dispose();
    super.dispose();
  }

  void attachScroll() {
    if (_scrollController.position.isScrollingNotifier.value) {
      // print("attachTrimToScroll called offset: ${_scrollController.offset}");
      // update trim and video position
      print("UI:_scrollController.offset: ${_scrollController.offset}");
      isHighlighted = false;
      _controllerSeekTo(_scrollController.offset);
    }
  }

  /// Scroll to update [_rect] and trim values on scroll
  /// Will fix [_rect] to the scroll view when it is bouncing
  /// Sets the video's current timestamp to be at the [position] on the slider
  /// If the expected position is bigger than [subtitleController.endTrim], set it to [subtitleController.endTrim]
  void _controllerSeekTo(double position) async {
    final to = widget.controller.videoDuration *
        (position / (_sliderWidth + _horizontalMargin * 2));
    print("UI:to: $to");
    await widget.controller.seekTo(to);
  }

  Stream<List<Subtitle>> getSubtitles() {
    return Stream.value(widget.controller.subtitles);
  }

// Returns the max size the layout should take with the rect value
  double computeWidth(Subtitle subtitle) {
    final start = subtitle.start.inMilliseconds;
    final end = subtitle.end.inMilliseconds;
    final duration = widget.controller.videoDuration.inMilliseconds;
    final width = (_sliderWidth * (end - start)) / duration;
    return width;
  }

// Returns the max size the layout should take with the rect value
  double computeStartX(Subtitle subtitle) {
    final start = subtitle.start.inMilliseconds;
    final duration = widget.controller.videoDuration.inMilliseconds;
    final startX = (_sliderWidth * start) / duration;
    return startX;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: LayoutBuilder(builder: (_, box) {
          return StreamBuilder<List<Subtitle>>(
            stream: _stream,
            builder: (_, snapshot) {
              final data = snapshot.data;
              if (data == null) return const SizedBox();

              return Padding(
                  padding: EdgeInsets.symmetric(horizontal: _horizontalMargin),
                  child: Column(children: [
                    CustomPaint(
                      size: Size(_sliderWidth, 30),
                      // Specify the size of the canvas
                      painter: ScalePainter(
                        tickCount: widget.controller.videoDuration.inSeconds,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                        child: Container(
                            height: widget.height + 20,
                            width: _sliderWidth + 20,
                            color: Colors.grey.withOpacity(0.2),
                            child: Stack(children: [
                              ...data.map((subtitle) {
                                return _buildSingleSubtitle(subtitle);
                              }),
                              Visibility(
                                  visible: isHighlighted,
                                  child: Positioned(
                                      left: _calculateLeftTouch(),
                                      top: 10 +
                                          widget.height / 2 -
                                          touchHeight / 2,
                                      child: GestureDetector(
                                          onHorizontalDragUpdate: (details) {
                                            adjustSubtitle(true, details);
                                            setState(() {});
                                          },
                                          child: Container(
                                            width: touchWidth,
                                            height: touchHeight,
                                            decoration: const BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(10),
                                                    bottomLeft:
                                                        Radius.circular(10))),
                                            padding: const EdgeInsets.all(5.0),
                                            child: const Align(
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.arrow_back_ios_rounded,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )))),
                              Visibility(
                                  visible: isHighlighted,
                                  child: Positioned(
                                      left: _calculateRightTouch(),
                                      top: 10 +
                                          widget.height / 2 -
                                          touchHeight / 2,
                                      child: GestureDetector(
                                          onHorizontalDragUpdate: (details) {
                                            adjustSubtitle(true, details);
                                            setState(() {});
                                          },
                                          child: Container(
                                            width: touchWidth,
                                            height: touchHeight,
                                            decoration: const BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(10),
                                                    bottomRight:
                                                        Radius.circular(10))),
                                            padding: const EdgeInsets.all(5.0),
                                            child: const Align(
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )))),
                            ])))
                  ]));
            },
          );
        }));
  }

  double _calculateLeftTouch() {
    print("_calculateLeftTouch called");
    return widget.controller.highlightSubtitle != null
        ? computeStartX(widget.controller.highlightSubtitle!) - touchWidth
        : 0.0;
  }

  double _calculateRightTouch() {
    return widget.controller.highlightSubtitle != null
        ? computeStartX(widget.controller.highlightSubtitle!) +
            computeWidth(widget.controller.highlightSubtitle!)
        : 0.0;
  }

  adjustSubtitle(bool adjustStart, DragUpdateDetails details) {
    print("onHorizontalDragUpdate 1: ${details.primaryDelta}");
    print("onHorizontalDragUpdate 2: ${details.globalPosition}");
    final to = widget.controller.videoDuration *
        (details.globalPosition.dx / (_sliderWidth + _horizontalMargin * 2));
    if (widget.controller.highlightSubtitle != null) {
      if (adjustStart) {
        widget.controller.highlightSubtitle!.start -= to;
      } else {
        widget.controller.highlightSubtitle!.end += to;
      }
      print("UI:highlightSubtitle: ${widget.controller.highlightSubtitle}");
    }
  }

  _buildSingleSubtitle(Subtitle subtitle) {
    double width = computeWidth(subtitle);
    double startX = computeStartX(subtitle);

    return Positioned(
        left: startX,
        top: 10,
        child: GestureDetector(
          onTap: () {
            //set highlighted subtitle
            isHighlighted = !isHighlighted;
            if (isHighlighted) {
              widget.controller.highlightSubtitle = subtitle;
            } else {
              widget.controller.highlightSubtitle = null;
            }
            print(
                "UI:highlightSubtitle: ${widget.controller.highlightSubtitle}");
            setState(() {});
          },
          child:
              //add left arrow
              Container(
            width: width,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFF974836),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(5.0),
            child: Align(
              alignment: Alignment.center,
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
          //add left arrow
        ));
  }
}

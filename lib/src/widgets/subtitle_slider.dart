import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:video_subtitle_editor/src/models/subtitle.dart';
import 'package:video_subtitle_editor/src/widgets/scale_line.dart';
import 'package:video_subtitle_editor/src/widgets/subtitle_text_editor.dart';
import 'package:video_subtitle_editor/video_subtitle_editor.dart';

class SubtitleSlider extends StatefulWidget {
  const SubtitleSlider({
    super.key,
    required this.controller,
    this.height = 100,
    this.subtitleBackgroundColor = const Color(0xFF974836),
    this.touchAreaColor = Colors.grey,
    this.baselineColor = Colors.redAccent,
    this.subtitleTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  });

  final VideoSubtitleController controller;

  /// The [height] param specifies the height of the generated thumbnails
  final double height;
  final Color baselineColor;

  ///the background color of the subtitle
  final Color subtitleBackgroundColor;

  ///the color of the touch area
  final Color touchAreaColor;
  final TextStyle subtitleTextStyle;

  @override
  State<SubtitleSlider> createState() => _SubtitleSliderState();
}

class _SubtitleSliderState extends State<SubtitleSlider>
    with SingleTickerProviderStateMixin {
  /// The max width of [SubtitleSlider]
  double _sliderWidth = 1.0;

  /// how many pixels per second
  static const double perPixelInSec = 100.0;

  /// the width of the left and right touch areas
  double touchWidth = 30.0;

  /// the height of the left and right touch areas
  double touchHeight = 60.0;

  late final ScrollController _scrollController;

  /// the horizontal margin of the slider
  late double _horizontalMargin;

  ///is the subtitle highlighted in edit mode
  bool get isHighlighted => widget.controller.highlightSubtitle != null;

  ///how many pixels per second should be scrolled as video is playing
  double speed = 1;

  @override
  void initState() {
    super.initState();
    //half of screen width
    calculateSliderWidth(widget.controller);
    touchHeight = widget.height / 2;
    touchWidth = widget.height / 4;
    _scrollController = ScrollController();
    _scrollController.addListener(attachScroll);
    widget.controller.video.addListener(videoUpdate);
    speed = _sliderWidth / widget.controller.videoDuration.inMilliseconds;
  }

  calculateSliderWidth(VideoSubtitleController controller) {
    final duration = controller.videoDuration.inSeconds;
    _sliderWidth = duration.toDouble() * perPixelInSec;
  }

  int lastTimeStamp = 0;
  bool isAutoScrolling = false;

  videoUpdate() {
    //how to update SingleChildScrollView scroll position when video is playing
    if (widget.controller.video.value.isPlaying) {
      isAutoScrolling = true;
      int interval =
          widget.controller.videoPosition.inMilliseconds - lastTimeStamp;
      lastTimeStamp = widget.controller.videoPosition.inMilliseconds;
      if (interval > 0) {
        _scrollController.animateTo(speed * (lastTimeStamp + 500),
            duration: const Duration(milliseconds: 500), curve: Curves.linear);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void attachScroll() {
    if (_scrollController.position.isScrollingNotifier.value) {
      // update trim and video position
      if (_scrollController.position.userScrollDirection !=
          ScrollDirection.idle) {
        //user is scrolling the slider
        if (widget.controller.isPlaying) {
          widget.controller.video.pause();
        }
        widget.controller.highlightSubtitle = null;
        _controllerSeekTo(_scrollController.offset);
      } else {}
    }
  }

  /// Sets the video's current timestamp to be at the [position] on the slider
  /// If the expected position is bigger than [subtitleController.endTrim], set it to [subtitleController.endTrim]
  void _controllerSeekTo(double position) async {
    final to = widget.controller.videoDuration *
        (position / (_sliderWidth + _horizontalMargin * 2));
    await widget.controller.seekTo(to);
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
    _horizontalMargin = MediaQuery.of(context).size.width / 2;
    return Stack(children: [
      GestureDetector(
          onTap: () {
            if (widget.controller.isPlaying) {
              widget.controller.video.pause();
            }
          },
          child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _horizontalMargin),
                child: Stack(children: [
                  CustomPaint(
                    size: Size(_sliderWidth, 30),
                    // Specify the size of the canvas
                    painter: ScalePainter(
                      tickCount: widget.controller.videoDuration.inSeconds,
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 35),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                          child: Container(
                              height: widget.height + 20,
                              width: _sliderWidth,
                              color: Colors.grey.withOpacity(0.2),
                              child: Stack(children: [
                                ...widget.controller.subtitles.map((subtitle) {
                                  return _buildSingleSubtitle(subtitle);
                                }),
                                Visibility(
                                    visible: isHighlighted,
                                    child: Positioned(
                                        left: _calculateLeftTouch(),
                                        top: 10,
                                        child: GestureDetector(
                                            onHorizontalDragUpdate: (details) {
                                              adjustSubtitleStartTime(details);
                                              setState(() {});
                                            },
                                            child: Container(
                                              width: touchWidth,
                                              height: widget.height,
                                              decoration: BoxDecoration(
                                                  color: widget.touchAreaColor,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  10),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  10))),
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.arrow_back_ios_rounded,
                                                  size: touchWidth - 10,
                                                ),
                                              ),
                                            )))),
                                Visibility(
                                    visible: isHighlighted,
                                    child: Positioned(
                                        left: _calculateRightTouch(),
                                        top: 10,
                                        child: GestureDetector(
                                            onHorizontalDragUpdate: (details) {
                                              adjustSubtitleEndTime(details);
                                              setState(() {});
                                            },
                                            child: Container(
                                              width: touchWidth,
                                              height: widget.height,
                                              decoration: BoxDecoration(
                                                  color: widget.touchAreaColor,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          topRight:
                                                              Radius.circular(
                                                                  10),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  10))),
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  color: Colors.white,
                                                  size: touchWidth - 10,
                                                ),
                                              ),
                                            )))),
                              ])))),
                  //add a icon button at the center of highlighted subtitle
                  Visibility(
                      visible: isHighlighted,
                      child: Positioned(
                          left: _calculateLeftTouch() +
                              _calculateSubtitleWidth() / 2,
                          child: GestureDetector(
                              onTap: () {
                                //delete the highlighted subtitle
                                widget.controller.deleteHighlightedSubtitle();
                                widget.controller.highlightSubtitle = null;
                                setState(() {});
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.5),
                                    shape: BoxShape.circle),
                                padding: const EdgeInsets.all(5.0),
                                child: const Align(
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.delete_forever,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              )))),
                ]),
              ))),
      Center(
        child: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Column(
              children: [
                Image.asset('images/inverted_triangle.png',
                    package: "video_subtitle_editor",
                    width: 20,
                    color: widget.baselineColor),
                Container(
                  height: widget.height + 30,
                  width: 2,
                  decoration: BoxDecoration(
                      border: Border.all(
                    color: widget.baselineColor,
                    width: 2,
                  )),
                )
              ],
            )),
      ),
    ]);
  }

  void _showFullscreenDialog(BuildContext context, Subtitle editSubtitle,
      {bool isAdded = false, int index = -1}) {
    showDialog(
        context: context,
        builder: (_) => Material(
              type: MaterialType.transparency,
              child: SubtitleEditor(
                subtitle: editSubtitle,
                onSaved: () {
                  if (isAdded) {
                    widget.controller.addSubtitle(editSubtitle, index);
                  }
                  setState(() {});
                },
              ),
            ));
  }

  double _calculateDeleteBtnStartX() {
    if (widget.controller.highlightSubtitle == null) return 0.0;
    return computeStartX(widget.controller.highlightSubtitle!) +
        _horizontalMargin +
        computeWidth(widget.controller.highlightSubtitle!) / 2 -
        10;
  }

  double _calculateLeftTouch() {
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

  double _calculateSubtitleWidth() {
    return widget.controller.highlightSubtitle != null
        ? computeWidth(widget.controller.highlightSubtitle!)
        : 0.0;
  }

  /// Adjust the subtitle start time based on the drag details
  /// @param details: the drag details
  adjustSubtitleStartTime(DragUpdateDetails details) {
    Subtitle? highlightSubtitle = widget.controller.highlightSubtitle;
    if (highlightSubtitle == null) return;
    double offsetX =
        (details.primaryDelta ?? 0) / (_sliderWidth + _horizontalMargin * 2);

    final to = widget.controller.videoDuration * offsetX;
    var adjustStartX = highlightSubtitle.start + to;
    //check if start time is less than pre subtitle end time
    if (adjustStartX <=
        (widget.controller.getPreSubtitle(highlightSubtitle)?.end ??
            const Duration(seconds: 0))) {
      adjustStartX = widget.controller.getPreSubtitle(highlightSubtitle)?.end ??
          const Duration(seconds: 0);
    }
    highlightSubtitle.start = adjustStartX;
  }

  /// Adjust the subtitle end time based on the drag details
  /// @param details: the drag details
  adjustSubtitleEndTime(DragUpdateDetails details) {
    Subtitle? highlightSubtitle = widget.controller.highlightSubtitle;
    if (highlightSubtitle == null) return;
    double offsetX =
        (details.primaryDelta ?? 0) / (_sliderWidth + _horizontalMargin * 2);
    final to = widget.controller.videoDuration * offsetX;
    var adjustEndX = highlightSubtitle.end + to;
    //check if end time is greater than next subtitle start time
    if (adjustEndX >=
        (widget.controller.getNextSubtitle(highlightSubtitle)?.start ??
            widget.controller.videoDuration)) {
      adjustEndX =
          widget.controller.getNextSubtitle(highlightSubtitle)?.start ??
              widget.controller.videoDuration;
    }
    highlightSubtitle.end = adjustEndX;
  }

  double calculatePixelsToMiddle() {
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalMargin = screenWidth / 2;
    double currentScrollOffset = _scrollController.offset;
    return horizontalMargin + currentScrollOffset;
  }
   showAddNewSubtitleView(Subtitle subtitle, Subtitle? nextSubtitle, int index) {
    // Add your logic to add a new subtitle here
    Subtitle newSubtitle = Subtitle(
        start: Duration(
            milliseconds: subtitle.end.inMilliseconds + 100),
        end: Duration(
            milliseconds: nextSubtitle != null
                ? nextSubtitle.start.inMilliseconds - 100
                : subtitle.end.inMilliseconds + 1000),
        data: "New Subtitle",
        index: subtitle.index + 1);
    _showFullscreenDialog(context, newSubtitle,
        isAdded: true, index: index + 1);
  }

  _buildSingleSubtitle(Subtitle subtitle) {
    final index = widget.controller.subtitles.indexOf(subtitle);
    Subtitle? nextSubtitle = widget.controller.getNextSubtitle(subtitle);
    double width = computeWidth(subtitle);
    double startX = computeStartX(subtitle);
    double spaceToNextSubtitle = 0;
    double addedIconStartX = 0;
    double iconSize = 30;
    double minToAllowAddIcon = 50;
    bool showAddedIcon = false;
    //how to calculate how many pixels from the beginning of the slider to the middle of screen

    if (index < widget.controller.subtitles.length - 1) {
      spaceToNextSubtitle =
          computeStartX(widget.controller.subtitles[index + 1]) -
              (startX + width);
    } else {
      spaceToNextSubtitle = _sliderWidth - (startX + width);
    }

    if (spaceToNextSubtitle > minToAllowAddIcon) {
      showAddedIcon = true;
      if (_scrollController.hasClients) {
        if (_scrollController.offset < startX + width + iconSize / 2) {
          addedIconStartX = startX + width + 5;
        } else if (_scrollController.offset >
            startX + width + spaceToNextSubtitle) {
          addedIconStartX = startX + width + spaceToNextSubtitle - iconSize;
        } else {
          addedIconStartX = _scrollController.offset - iconSize / 2;
        }
      }
    }

    return Stack(
      children: [
        Positioned(
          left: startX,
          top: 10,
          child: GestureDetector(
            onTap: () {
              if (isHighlighted) {
                if (widget.controller.highlightSubtitle == subtitle) {
                  _showFullscreenDialog(context, subtitle);
                } else {
                  widget.controller.highlightSubtitle = subtitle;
                }
              } else {
                widget.controller.video.pause();
                widget.controller.highlightSubtitle = subtitle;
              }
              setState(() {});
            },
            child: Container(
              width: width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.subtitleBackgroundColor,
                border: isHighlighted &&
                        subtitle == widget.controller.highlightSubtitle
                    ? Border.symmetric(
                        horizontal: BorderSide(
                          color: widget.touchAreaColor,
                          width: 2,
                        ),
                      )
                    : null,
                borderRadius: isHighlighted &&
                        subtitle == widget.controller.highlightSubtitle
                    ? BorderRadius.zero
                    : BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(5.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  subtitle.data,
                  style: widget.subtitleTextStyle,
                ),
              ),
            ),
          ),
        ),
        //draw a vertical line at the current video position

        if (showAddedIcon)
          Positioned(
              left: startX + width,
              top: 10,
              child: GestureDetector(
                  onTap: () {
                    showAddNewSubtitleView(subtitle, nextSubtitle, index);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Container(
                      width: spaceToNextSubtitle - 10,
                      height: widget.height,
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(5.0),
                    ),
                  ))),
        if (showAddedIcon)
          Positioned(
              left: addedIconStartX,
              top: widget.height / 2 - iconSize / 2 + 5,
              child: GestureDetector(
                  onTap: () {
                    showAddNewSubtitleView(subtitle, nextSubtitle, index);
                  },
                  child: Icon(
                    Icons.add_circle,
                    color: Colors.white,
                    size: iconSize,
                  ))),
      ],
    );
  }
}

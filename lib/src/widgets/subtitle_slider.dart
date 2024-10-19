import 'package:flutter/material.dart';
import 'package:subtitle/subtitle.dart';
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
  late final ScrollController _scrollController;
  late double _horizontalMargin;
  late final Stream<List<Subtitle>> _stream = (() => getSubtitles())();

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
              return snapshot.hasData
                  ? Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: _horizontalMargin),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                          child: Container(
                              height: widget.height+20,
                              width: _sliderWidth+20,
                              color: Colors.grey.withOpacity(0.5),
                              child: Stack(
                                children: [
                                  ...data.map((subtitle) {
                                  double width = computeWidth(subtitle);
                                  double startX = computeStartX(subtitle);
                                  return Positioned(
                                    left: startX,
                                    top: 10,
                                    child: Container(
                                        width: width,
                                        height: widget.height,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF974836),
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.all(8.0),
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
                                        )
                                  );
                                })]
                              ))))
                  : const SizedBox();
            },
          );
        }));
  }
}

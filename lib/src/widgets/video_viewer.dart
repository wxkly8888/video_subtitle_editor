import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_subtitle_editor/src/video_subtitle_controller.dart';
import 'package:video_subtitle_editor/video_subtitle_editor.dart';

class VideoViewer extends StatelessWidget {
  const VideoViewer(
      {super.key, required this.controller, this.position, this.child});

  final VideoSubtitleController controller;
  final SubtitlePosition?
      position; // Keep final, but the object itself is mutable
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    //get screen width
    var screenWidth = MediaQuery.of(context).size.width;
    final double videoHeight = screenWidth / controller.video.value.aspectRatio;
    print("videoHeight: $videoHeight videoWidth: $screenWidth");
    return GestureDetector(onTap: () {
      print("tap video called");
      controller.dismissHighlightedSubtitle();
      if (controller.video.value.isPlaying) {
        controller.video.pause();
      } else {
        controller.video.play();
      }
    }, child: LayoutBuilder(builder: (context, constraints) {
      return Padding(
          padding: EdgeInsets.only(top: 40.0),
          child: SizedBox(
            width: screenWidth,
            height: videoHeight,
            child: Stack(children: [
              Align(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: controller.video.value.aspectRatio,
                  child: VideoPlayer(controller.video),
                ),
              ),
              Align(
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: controller.video,
                    builder: (_, __) => AnimatedOpacity(
                        opacity: controller.isPlaying ? 0 : 1,
                        duration: kThemeAnimationDuration,
                        child: GestureDetector(
                          onTap: controller.video.play,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                            ),
                          ),
                        )),
                  )),
              if (child != null &&
                  position != null &&
                  position!.layoutType == LayoutType.top)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: child!,
                ),
              if (child != null &&
                  position != null &&
                  position!.layoutType != LayoutType.top)
                Positioned(
                  bottom: getLayoutBottomValue(videoHeight),
                  left: 0,
                  right: 0,
                  child: child!,
                ),
            ]),
          ));
    }));
  }

  double getLayoutTopValue(videoHeight) {
    if (position == null) {
      return videoHeight;
    }
    if (position?.layoutType == LayoutType.top) {
      return 0;
    } else if (position?.layoutType == LayoutType.center) {
      return videoHeight / 2;
    } else {
      return 0;
    }
  }

  double getLayoutBottomValue(videoHeight) {
    if (position == null) {
      return 0;
    }
    if (position?.layoutType == LayoutType.bottom) {
      return 0;
    } else if (position?.layoutType == LayoutType.center) {
      return videoHeight / 2 - 30;
    } else {
      return videoHeight - 30;
    }
  }
}

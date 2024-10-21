import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_subtitle_editor/src/video_subtitle_controller.dart';

class VideoViewer extends StatelessWidget {
  const VideoViewer({super.key, required this.controller, this.child});

  final VideoSubtitleController controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    print("video viewer called controller.isPlaying:${controller.isPlaying}");
    return GestureDetector(
        onTap: () {
          print ("ontap called :${controller.video.value.isPlaying}");
          if (controller.video.value.isPlaying) {
            controller.video.pause();
          } else {
            controller.video.play();
          }
        },
        child:  Container(
          width: controller.videoWidth,
          height: controller.videoHeight,
          child: Stack(children: [
            Align(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: controller.video.value.aspectRatio,
                  child: VideoPlayer(controller.video),
                )),
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
            if (child != null)
              Padding(
                padding:  EdgeInsets.only(top: controller.videoHeight/2-50),
                child: child,
              ),
          ]),
        ));
  }
}

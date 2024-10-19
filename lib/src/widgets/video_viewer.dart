import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_subtitle_editor/src/video_subtitle_controller.dart';


class VideoViewer extends StatelessWidget {
  const VideoViewer({super.key, required this.controller, this.child});

  final VideoSubtitleController controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (controller.video.value.isPlaying) {
          controller.video.pause();
        } else {
          controller.video.play();
        }
      },
      child: Center(
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: controller.video.value.aspectRatio,
              child: VideoPlayer(controller.video),
            ),
            if (child != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

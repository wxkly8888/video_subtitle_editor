// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:video_subtitle_editor/src/utils/helpers.dart';
// import 'package:video_subtitle_editor/src/models/cover_data.dart';
// import 'package:video_player/video_player.dart';
// import '../video_subtitle_editor.dart';
//
// enum RotateDirection { left, right }
//
// /// The default value of this property `Offset(1.0, 1.0)`
// const Offset maxOffset = Offset(1.0, 1.0);
//
// /// The default value of this property `Offset.zero`
// const Offset minOffset = Offset.zero;
//
// /// Provides an easy way to change edition parameters to apply in the different widgets of the package and at the exportion
// /// This controller allows to : rotate, crop, trim, cover generation and exportation (video and cover)
// class VideoEditController extends ChangeNotifier {
//
//
//   /// Video from [File].
//   final File file;
//   /// Style for [CropGridViewer]
//   final CropGridStyle cropStyle;
//
//   /// Constructs a [VideoEditController] that edits a video from a file.
//   ///
//   /// The [file] argument must not be null.
//   VideoEditController.file(
//     this.file, {
//     this.cropStyle = const CropGridStyle(),
//
//   })  : _video = VideoPlayerController.file(File(
//           // https://github.com/flutter/flutter/issues/40429#issuecomment-549746165
//           Platform.isIOS ? Uri.encodeFull(file.path) : file.path,
//         ));
//
//   int _rotation = 0;
//   bool isCropping = false;
//
//   double? _preferredCropAspectRatio;
//
//   double _minTrim = minOffset.dx;
//   double _maxTrim = maxOffset.dx;
//
//   Offset _minCrop = minOffset;
//   Offset _maxCrop = maxOffset;
//
//   Offset cacheMinCrop = minOffset;
//   Offset cacheMaxCrop = maxOffset;
//
//   Duration _trimEnd = Duration.zero;
//   Duration _trimStart = Duration.zero;
//   final VideoPlayerController _video;
//
//   // Selected cover value
//   final ValueNotifier<CoverData?> _selectedCover =
//       ValueNotifier<CoverData?>(null);
//
//   /// Get the [VideoPlayerController]
//   VideoPlayerController get video => _video;
//
//   /// Get the [VideoPlayerController.value.initialized]
//   bool get initialized => _video.value.isInitialized;
//
//   /// Get the [VideoPlayerController.value.isPlaying]
//   bool get isPlaying => _video.value.isPlaying;
//
//   /// Get the [VideoPlayerController.value.position]
//   Duration get videoPosition => _video.value.position;
//
//   /// Get the [VideoPlayerController.value.duration]
//   Duration get videoDuration => _video.value.duration;
//
//   /// Get the [VideoPlayerController.value.size]
//   Size get videoDimension => _video.value.size;
//   double get videoWidth => videoDimension.width;
//   double get videoHeight => videoDimension.height;
//
//   /// The [minTrim] param is the minimum position of the trimmed area on the slider
//   ///
//   /// The minimum value of this param is `0.0`
//   /// The maximum value of this param is [maxTrim]
//   double get minTrim => _minTrim;
//
//   /// The [maxTrim] param is the maximum position of the trimmed area on the slider
//   ///
//   /// The minimum value of this param is [minTrim]
//   /// The maximum value of this param is `1.0`
//   double get maxTrim => _maxTrim;
//
//   /// The [startTrim] param is the maximum position of the trimmed area in video position in [Duration] value
//   Duration get startTrim => _trimStart;
//
//   /// The [endTrim] param is the maximum position of the trimmed area in video position in [Duration] value
//   Duration get endTrim => _trimEnd;
//
//   /// The [Duration] of the selected trimmed area, it is the difference of [endTrim] and [startTrim]
//   Duration get trimmedDuration => endTrim - startTrim;
//
//   /// The [minCrop] param is the [Rect.topLeft] position of the crop area
//   ///
//   /// The minimum value of this param is `0.0`
//   /// The maximum value of this param is `1.0`
//   Offset get minCrop => _minCrop;
//
//   /// The [maxCrop] param is the [Rect.bottomRight] position of the crop area
//   ///
//   /// The minimum value of this param is `0.0`
//   /// The maximum value of this param is `1.0`
//   Offset get maxCrop => _maxCrop;
//
//   /// Get the [Size] of the [videoDimension] cropped by the points [minCrop] & [maxCrop]
//   Size get croppedArea => Rect.fromLTWH(
//         0,
//         0,
//         videoWidth * (maxCrop.dx - minCrop.dx),
//         videoHeight * (maxCrop.dy - minCrop.dy),
//       ).size;
//
//   /// The [preferredCropAspectRatio] param is the selected aspect ratio (9:16, 3:4, 1:1, ...)
//   double? get preferredCropAspectRatio => _preferredCropAspectRatio;
//   set preferredCropAspectRatio(double? value) {
//     if (preferredCropAspectRatio == value) return;
//     _preferredCropAspectRatio = value;
//     notifyListeners();
//   }
//
//   /// Set [preferredCropAspectRatio] to the current cropped area ratio
//   void setPreferredRatioFromCrop() {
//     _preferredCropAspectRatio = croppedArea.aspectRatio;
//     notifyListeners();
//   }
//
//   /// Update the [preferredCropAspectRatio] param and init/reset crop parameters [minCrop] & [maxCrop] to match the desired ratio
//   /// The crop area will be at the center of the layout
//   void cropAspectRatio(double? value) {
//     preferredCropAspectRatio = value;
//
//     if (value != null) {
//       final newSize = computeSizeWithRatio(videoDimension, value);
//
//       Rect centerCrop = Rect.fromCenter(
//         center: Offset(videoWidth / 2, videoHeight / 2),
//         width: newSize.width,
//         height: newSize.height,
//       );
//
//       _minCrop =
//           Offset(centerCrop.left / videoWidth, centerCrop.top / videoHeight);
//       _maxCrop = Offset(
//           centerCrop.right / videoWidth, centerCrop.bottom / videoHeight);
//       notifyListeners();
//     }
//   }
//
//
//   Future<void> initialize({double? aspectRatio}) async {
//     await _video.initialize();
//     _video.addListener(_videoListener);
//     _video.setLooping(true);
//     cropAspectRatio(aspectRatio);
//     notifyListeners();
//   }
//
//   @override
//   Future<void> dispose() async {
//     if (_video.value.isPlaying) await _video.pause();
//     _video.removeListener(_videoListener);
//     _video.dispose();
//     _selectedCover.dispose();
//     super.dispose();
//   }
//
//   void _videoListener() {
//     final position = videoPosition;
//     if (position < _trimStart || position > _trimEnd) {
//       _video.seekTo(_trimStart);
//     }
//   }
//
//   //----------//
//   //VIDEO CROP//
//   //----------//
//
//   /// Update the [minCrop] and [maxCrop] with [cacheMinCrop] and [cacheMaxCrop]
//   void applyCacheCrop() => updateCrop(cacheMinCrop, cacheMaxCrop);
//
//   // Update [minCrop] and [maxCrop].
//   ///
//   /// The [min] param is the [Rect.topLeft] position of the crop area
//   /// The [max] param is the [Rect.bottomRight] position of the crop area
//   ///
//   /// Arguments range are [Offset.zero] to `Offset(1.0, 1.0)`.
//   void updateCrop(Offset min, Offset max) {
//     assert(min < max,
//         'Minimum crop value ($min) cannot be bigger and maximum crop value ($max)');
//
//     _minCrop = min;
//     _maxCrop = max;
//     notifyListeners();
//   }
//
//   /// Get the [selectedCover] notifier
//   ValueNotifier<CoverData?> get selectedCoverNotifier => _selectedCover;
//
//   /// Get the [selectedCover] value
//   CoverData? get selectedCoverVal => _selectedCover.value;
//
//   //------------//
//   //VIDEO ROTATE//
//   //------------//
//
//   /// Get the rotation of the video, value should be a multiple of `90`
//   int get cacheRotation => _rotation;
//
//   /// Get the rotation of the video,
//   /// possible values are: `0`, `90`, `180` and `270`
//   int get rotation => (_rotation ~/ 90 % 4) * 90;
//
//   /// Rotate the video by 90 degrees in the [direction] provided
//   void rotate90Degrees([RotateDirection direction = RotateDirection.right]) {
//     switch (direction) {
//       case RotateDirection.left:
//         _rotation += 90;
//         break;
//       case RotateDirection.right:
//         _rotation -= 90;
//         break;
//     }
//     notifyListeners();
//   }
//
//   bool get isRotated => rotation == 90 || rotation == 270;
// }

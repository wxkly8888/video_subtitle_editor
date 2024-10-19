import 'dart:io';

import 'package:example/widgets/export_result.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_subtitle_editor/video_subtitle_editor.dart';
import 'export_service.dart';

void main() => runApp(
      MaterialApp(
        title: 'Flutter Video Editor Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.grey,
          brightness: Brightness.dark,
          tabBarTheme: const TabBarTheme(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          dividerColor: Colors.white,
        ),
        home: const VideoEditorExample(),
      ),
    );

class VideoEditorExample extends StatefulWidget {
  const VideoEditorExample({super.key});

  @override
  State<VideoEditorExample> createState() => _VideoEditorExampleState();
}

class _VideoEditorExampleState extends State<VideoEditorExample> {
  final ImagePicker _picker = ImagePicker();

  void _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);

    if (mounted && file != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              VideoEditor(videoFile: File(file.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Picker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Click on the button to select video"),
            ElevatedButton(
              onPressed: _pickVideo,
              child: const Text("Pick Video From Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}

//-------------------//
//VIDEO EDITOR SCREEN//
//-------------------//
class VideoEditor extends StatefulWidget {
  const VideoEditor({super.key, required this.videoFile});

  final File videoFile;

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  late final VideoSubtitleController _controller = VideoSubtitleController.file(
    widget.videoFile,
  );

  @override
  void initState() {
    super.initState();
    _controller
        .initialize()
        .then((_) =>
        setState(() {}))
        .catchError((error) {});
    _controller.addListener(
      () {
        setState(() {});
      },
    );
  }

  @override
  void dispose() async {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    // ExportService.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );

  void _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;

    // final config = VideoFFmpegVideoEditorConfig(
    //   _controller,
    //   // format: VideoExportFormat.gif,
    //   // commandBuilder: (config, videoPath, outputPath) {
    //   //   final List<String> filters = config.getExportFilters();
    //   //   filters.add('hflip'); // add horizontal flip
    //
    //   //   return '-i $videoPath ${config.filtersCmd(filters)} -preset ultrafast $outputPath';
    //   // },
    // );

    // await ExportService.runFFmpegCommand(
    //   await config.getExecuteConfig(),
    //   onProgress: (stats) {
    //     _exportingProgress.value = config.getFFmpegProgress(stats.getTime());
    //   },
    //   onError: (e, s) => _showErrorSnackBar("Error on export video :("),
    //   onCompleted: (file) {
    //     _isExporting.value = false;
    //     if (!mounted) return;
    //
    //     showDialog(
    //       context: context,
    //       builder: (_) => VideoResultPopup(video: file),
    //     );
    //   },
    // );
  }

  @override
  Widget build(BuildContext context) {
    print("video width: ${_controller.videoWidth}, video height: ${_controller.videoHeight}");

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller.initialized
            ? SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _topNavBar(),
                        Expanded(
                          child:
                              buildVideoView(_controller),
                        ),
                        Text(
                          "${formatter(_controller.videoPosition)}/${formatter(_controller.videoDuration)}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 50),
                          child: SubtitleSlider(
                            controller: _controller,
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: _isExporting,
                          builder: (_, bool export, Widget? child) =>
                              AnimatedSize(
                            duration: kThemeAnimationDuration,
                            child: export ? child : null,
                          ),
                          child: AlertDialog(
                            title: ValueListenableBuilder(
                              valueListenable: _exportingProgress,
                              builder: (_, double value, __) => Text(
                                "Exporting video ${(value * 100).ceil()}%",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _topNavBar() {
    return SafeArea(
      child: SizedBox(
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'Leave editor',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: PopupMenuButton(
                tooltip: 'Open export menu',
                icon: const Icon(Icons.save),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: _exportVideo,
                    child: const Text('Export video'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the [VideoViewer] tranformed with editing view
  /// Paint rect on top of the video area outside of the crop rect
  Widget buildVideoView(VideoSubtitleController controller) {
    return VideoViewer(
      controller: controller,
      child: SubtitleTextView(
        controller: controller,
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");
}

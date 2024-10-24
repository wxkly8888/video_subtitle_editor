import 'package:flutter/material.dart';
import 'package:video_subtitle_editor/src/models/subtitle.dart';

class SubtitleEditor extends StatelessWidget {
  final Subtitle subtitle;
  final Function onSaved;

  const SubtitleEditor({
    required this.subtitle,
    required this.onSaved,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: subtitle.data);
    final FocusNode focusNode = FocusNode();

    // Request focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5), // 50% transparency
      body: Column(
        children: [
          // Add a delete button on the top right corner

          Expanded(
            child:Center(child:  Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                style: const TextStyle(
                  fontSize: 20.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),
          ),
          // Add save and close buttons above the keyboard
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    subtitle.data = controller.text;
                    onSaved.call();
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
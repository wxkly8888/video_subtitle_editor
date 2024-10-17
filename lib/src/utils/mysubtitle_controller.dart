import 'package:subtitle/subtitle.dart';

class MySubtitleController extends ISubtitleController {
  MySubtitleController({
    required SubtitleProvider provider,
  }) : super(provider: provider);

  //return all subtitles
  List<Subtitle> getAllTitles() => subtitles;

  /// Fetch your current single subtitle value by providing the duration.
  @override
  Subtitle? durationSearch(Duration duration) {
    if (!initialized) throw NotInitializedException();

    final l = 0;
    final r = subtitles.length - 1;

    var index = _binarySearch(l, r, duration);

    if (index > -1) {
      return subtitles[index];
    }
    return null;
  }

  /// Perform binary search when search about subtitle by duration.
  int _binarySearch(int l, int r, Duration duration) {
    if (r >= l) {
      var mid = l + (r - l) ~/ 2;

      if (subtitles[mid].inRange(duration)) return mid;

      // If element is smaller than mid, then
      // it can only be present in left subarray
      if (subtitles[mid].isLarg(duration)) {
        return _binarySearch(mid + 1, r, duration);
      }

      // Else the element can only be present
      // in right subarray
      return _binarySearch(l, mid - 1, duration);
    }

    // We reach here when element is not present
    // in array
    return -1;
  }

  @override
  List<Subtitle> multiDurationSearch(Duration duration) {
    var correctSubtitles = List<Subtitle>.empty(growable: true);

    subtitles.forEach((value) {
      if (value.inRange(duration)) correctSubtitles.add(value);
    });

    return correctSubtitles;
  }
}
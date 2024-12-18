import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'exceptions.dart';

/// A response class of HTTP request.
class SubtitleResponse {
  /// The status code of response.
  final int statusCode;

  /// Response body as a string.
  final String body;

  // /// Response body as a list of bytes.
  // final List<int> bodyBytes;

  const SubtitleResponse({
    required this.statusCode,
    required this.body,
    // required this.bodyBytes,
  });
}

/// The base class of any subtitle repository. Deals with the platform directly
/// to get or download the required data and submit it to the provider. You can
/// create your custom by inherited this base class.
abstract class ISubtitleRepository {
  const ISubtitleRepository();

  /// Help to fetch subtitle file data from internet.
  Future<String> fetchFromNetwork(Uri url);

  /// Help to fetch subtitle file data from a specific file.
  Future<String> fetchFromFile(File file);

  /// Simple method enable you to create a http GET request.
  Future<SubtitleResponse> get(Uri url) async {
    final client = HttpClient();
    final request = await client.getUrl(url);
    final response = await request.close();
    var body = await _readResponse(response);

    final res = SubtitleResponse(
      statusCode: response.statusCode,
      body: body,
    );
    return res;
  }

  /// Enable you to create a http request with specific method.
  Future<SubtitleResponse> open(String method, Uri url) async {
    final client = HttpClient();
    final request = await client.openUrl(method, url);
    final response = await request.close();
    var body = await _readResponse(response);

    final res = SubtitleResponse(
      statusCode: response.statusCode,
      body: body,
    );
    return res;
  }

  Future<String> _readResponse(HttpClientResponse response) {
    final completer = Completer<String>();
    final contents = StringBuffer();
    final _ = response.transform(utf8.decoder).listen((data) {
      contents.write(data);
    }, onDone: () {
      completer.complete(contents.toString());
    });
    return completer.future.whenComplete(() => _.cancel());
  }
}

/// Created to load the subtitles as a string from with value need to use futrue.
/// Deals with the platform directly to get or download the required data and submit
/// it to the provider.
class SubtitleRepository extends ISubtitleRepository {
  const SubtitleRepository._();

  static const SubtitleRepository inctance = SubtitleRepository._();

  /// Load the subtitles from network by provide the file url.
  @override
  Future<String> fetchFromNetwork(Uri url) async {
    final response = await get(url);
    if (response.statusCode == 200) {
      return response.body;
    }

    throw ErrorInternetFetchingSubtitle(response.statusCode, response.body);
  }

  /// Load the subtitles from specific file.
  @override
  Future<String> fetchFromFile(File file) {
    return file.readAsString();
  }
}

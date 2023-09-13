import 'dart:typed_data';

import 'package:meta/meta.dart';

@immutable
final class Request {
  const Request({
    required this.method,
    required this.url,
    required this.version,
    required this.headers,
    required this.contentLength,
    required this.body,
  });

  final String method;
  final String url;
  final ({int major, int minor}) version;
  final Map<String, String> headers;
  final int contentLength;
  final Uint8List body;

  //final int _client;
  //final Pointer<Void> _body;
}

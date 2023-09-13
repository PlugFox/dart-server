import 'dart:convert';
import 'dart:io';

import 'package:uv/src/api/serve.dart';

void main() => serve(
      (request) {
        //print(request.body);
        /* return '\n'
            'Hello, world!'
            '\n'
            '${DateTime.now().toUtc().toIso8601String()}'; */
        if (request.contentLength == 0) return 'Empty body';
        final text = utf8.decode(request.body);
        if (text.isEmpty) return 'Empty text';
        if (!text.startsWith('{') || !text.endsWith('}')) {
          return 'Invalid JSON';
        }
        final json = jsonDecode(text);
        return jsonEncode(json);
      },
      address: InternetAddress.anyIPv4,
      port: 3000,
      backlog: 128,
      workers: 4,
    );

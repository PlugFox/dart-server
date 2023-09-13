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
        return jsonEncode(jsonDecode(text));
      },
      address: InternetAddress.anyIPv4,
      port: 3000,
      backlog: 128,
      workers: 4,
    );

import 'dart:io';

import 'package:uv/src/api/serve.dart';

void main() => serve(
      (request) => '\n'
          'Hello, world!'
          '\n'
          '${DateTime.now().toUtc().toIso8601String()}',
      address: InternetAddress.anyIPv4,
      port: 3000,
      backlog: 128,
      workers: 4,
    );

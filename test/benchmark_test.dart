import 'package:http/http.dart' as http;

void main() => Future(() async {
      final url = Uri.http('127.0.0.1:3000', 'json');
      final client = http.Client();
      final body = '{"hello": "world"}';
      final contentLength = body.length.toString();
      final stopwatch = Stopwatch()..start();
      try {
        const total = 1000;
        for (var i = 0; i < total; i++) {
          print('Request $i/$total');
          final response =
              await client.get(Uri.parse('http://127.0.0.1:3000/plain?i=$i'));
          /* final response = await client.post(
            url,
            body: body,
            headers: <String, String>{
              'content-length': contentLength,
              'Content-Type': 'application/json; charset=UTF-8',
            },
          ); */
          assert(response.statusCode == 200);
        }
        print('Elapsed: ${stopwatch.elapsedMilliseconds} ms');
      } finally {
        stopwatch.stop();
      }
    });

import 'dart:async';
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math' as math;

import 'package:uv/src/api/handler.dart';
import 'package:uv/src/isolates/isolated_server.dart';
import 'package:uv/src/isolates/isolated_worker.dart';

/// Starts listening for HTTP requests on the specified address and port.
Future<void> serve(
  Handler handler, {
  io.InternetAddress? address,
  int? port,
  int? backlog,
  int? workers,
}) async {
  workers = switch (workers) {
    != null && > 0 => workers,
    _ => math.max(io.Platform.numberOfProcessors ~/ 2, 2),
  };
  // Start server
  final receivePort = ReceivePort();
  final completer = Completer<SendPort>();
  receivePort.listen((message) {
    switch (message) {
      case SendPort sendPort:
        if (!completer.isCompleted) completer.complete(sendPort);
      default:
        break;
    }
  });
  final serverIsolate = await Isolate.spawn<IsolatedServerArguments>(
    isolatedServer,
    (
      ip: (address ?? io.InternetAddress.anyIPv4).host,
      port: port ?? 8080,
      backlog: backlog ?? 128,
      workers: workers,
      sendPort: receivePort.sendPort,
    ),
    errorsAreFatal: false,
    debugName: 'Server',
  );
  final serverSendPort = await completer.future;

  await Future.delayed(Duration(seconds: 1));

  // Spawn worker isolates.
  final workerIsolates = <({
    Isolate isolate,
    SendPort sendPort,
    int nativePort,
  })>[];
  for (var i = 0; i < workers; i++) {
    final receivePort = ReceivePort();
    final completer = Completer<SendPort>();
    receivePort.listen((message) {
      switch (message) {
        case SendPort sendPort:
          if (!completer.isCompleted) completer.complete(sendPort);
        default:
          break;
      }
    });
    final isolate = await Isolate.spawn<IsolatedWorkerArguments>(
      isolatedWorker,
      (
        index: i,
        handler: handler,
        sendPort: receivePort.sendPort,
      ),
      errorsAreFatal: false,
      debugName: 'Worker#${i + 1}',
    );
    final sendPort = await completer.future;
    workerIsolates.add((
      isolate: isolate,
      sendPort: sendPort,
      nativePort: sendPort.nativePort,
    ));
  }

  print('Server started on ${address ?? io.InternetAddress.anyIPv4}:$port');

  //serverSendPort.send('close_server');
}

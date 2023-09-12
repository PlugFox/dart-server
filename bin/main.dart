import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

typedef _DartInitializeApiDLFunc = Pointer<Void> Function(Pointer<Void>);

typedef _StartServerC = Void Function(
  Pointer<Utf8> ip,
  Int32 port,
  Int32 backlog,
  Pointer<Uint64> ports,
  Int32 portsLength,
);
typedef _StartServerDart = void Function(
  Pointer<Utf8> ip,
  int port,
  int backlog,
  Pointer<Uint64> ports,
  int portsLength,
);

/// Entry point
void main([List<String>? args]) => Future<void>(() async {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        server,
        (
          addr: '0.0.0.0',
          port: 5050,
          backlog: 128,
          sendPort: receivePort.sendPort
        ),
        errorsAreFatal: false,
        debugName: 'Server',
      );
    });

/// Server isolated function.
void server(
    ({
      String addr,
      int port,
      int backlog,
      SendPort sendPort,
    }) args) async {
  final DynamicLibrary dylib;
  if (Platform.isLinux) {
    dylib = DynamicLibrary.open('build/libserver.so');
  } else if (Platform.isMacOS) {
    dylib = DynamicLibrary.open('build/libserver.dylib');
  } else if (Platform.isWindows) {
    dylib = DynamicLibrary.open('build/server.dll');
  } else {
    throw Exception('Platform not supported');
  }

  // Enable using the symbols in dart_api_dl.h.
  final _DartInitializeApiDLFunc dartInitializeApiDL = dylib
      .lookup<NativeFunction<_DartInitializeApiDLFunc>>("init_dart_api")
      .asFunction();
  dartInitializeApiDL(NativeApi.initializeApiDLData);

  // Spawn worker isolates.

  final workers = <(Isolate, SendPort)>[];
  for (var i = 1; i <= 4; i++) {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      worker,
      receivePort.sendPort,
      errorsAreFatal: false,
      debugName: 'Worker#$i',
    );
    final completer = Completer<SendPort>();
    receivePort.listen((message) {
      switch (message) {
        case SendPort sendPort:
          if (!completer.isCompleted) {
            completer.complete(sendPort);
          }
        default:
          print('Message from isolate: $message');
      }
    });
    final sendPort = await completer.future;
    workers.add((isolate, sendPort));
    sendPort.nativePort;
  }

  final ports = [for (final isolate in workers) isolate.$2];
  final ptr = calloc<Uint64>(ports.length);
  ptr
      .asTypedList(ports.length)
      .setAll(0, [for (final port in ports) port.nativePort]);

  // Get the function pointer
  final startServer =
      dylib.lookupFunction<_StartServerC, _StartServerDart>('start_server');

  final ip = args.addr.toNativeUtf8();
  final port = args.port;
  final backlog = args.backlog;

  print('Starting server...');
  startServer(ip, port, backlog, ptr, ports.length);
  //calloc.free(ptr);
}

/// Worker isolated function.
void worker(SendPort sendPort) {
  final DynamicLibrary dylib;
  if (Platform.isLinux) {
    dylib = DynamicLibrary.open('build/libserver.so');
  } else if (Platform.isMacOS) {
    dylib = DynamicLibrary.open('build/libserver.dylib');
  } else if (Platform.isWindows) {
    dylib = DynamicLibrary.open('build/server.dll');
  } else {
    throw Exception('Platform not supported');
  }
  final callbackPointer = Pointer.fromFunction<Void Function()>(myDartCallback);
  final nativeCallback = dylib.lookupFunction<
      Void Function(Pointer<NativeFunction<Void Function()>>),
      void Function(Pointer<NativeFunction<Void Function()>>)>("callback");
  nativeCallback(callbackPointer);

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((message) {
    switch (message) {
      case Uint8ClampedList list:
        print('Received message: (${list.join(', ')})');
      case String msg:
        print('Received message: $msg');
      default:
        print('Received message: $message (type: ${message.runtimeType})');
    }
  }, onError: (error) {
    print('Error: $error');
  }, onDone: () {
    print('Done');
  });
}

final int a = math.Random().nextInt(100);
void myDartCallback() {
  print('Function called from C!, rnd = $a');
}

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
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

void main([List<String>? args]) => Future<void>(() async {
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

      final startServer =
          dylib.lookupFunction<_StartServerC, _StartServerDart>('start_server');

      final ip = '127.0.0.1'.toNativeUtf8();
      final port = 5050;
      final backlog = 128;

      final isolates = <(Isolate, SendPort)>[];
      for (var i = 1; i <= 4; i++) {
        final receivePort = ReceivePort();
        final isolate = await Isolate.spawn(
          handler,
          receivePort.sendPort,
          errorsAreFatal: false,
          debugName: 'Isolate#$i',
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
        isolates.add((isolate, sendPort));
        sendPort.nativePort;
      }

      // Enable using the symbols in dart_api_dl.h.
      final _DartInitializeApiDLFunc dartInitializeApiDL = dylib
          .lookup<NativeFunction<_DartInitializeApiDLFunc>>(
              "Dart_InitializeApiDL")
          .asFunction();
      dartInitializeApiDL(NativeApi.initializeApiDLData);

      final ports = [for (final isolate in isolates) isolate.$2];
      final ptr = calloc<Uint64>(ports.length);
      ptr
          .asTypedList(ports.length)
          .setAll(0, [for (final port in ports) port.nativePort]);

      print('Starting server...');
      startServer(ip, port, backlog, ptr, ports.length);

      calloc.free(ptr);

      await Future.delayed(Duration(seconds: 10));
    });

void handler(SendPort sendPort) {
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

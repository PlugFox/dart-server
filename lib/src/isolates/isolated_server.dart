import 'dart:async';
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart' as st;
import 'package:uv/src/util/shared_dylib.dart';

typedef _InitializeDartApiDLFunc = Pointer<Void> Function(Pointer<Void>);

typedef _CreateServerC = Void Function(
  Pointer<Utf8> host,
  Uint16 port,
  Uint16 backlog,
  Uint16 workers,
  Uint64 sendPort,
);
typedef _CreateServerDart = void Function(
  Pointer<Utf8> host,
  int port,
  int backlog,
  int workers,
  int sendPort,
);

@internal
typedef IsolatedServerArguments = ({
  String ip,
  int port,
  int backlog,
  int workers,
  SendPort sendPort,
});

/// Server isolated function.
@internal
void isolatedServer(IsolatedServerArguments args) => runZonedGuarded<void>(
      () async {
        // Enable using the symbols in dart_api_dl.h.
        final dartInitializeApiDL = dylib
            .lookup<NativeFunction<_InitializeDartApiDLFunc>>("init_dart_api")
            .asFunction<_InitializeDartApiDLFunc>();
        dartInitializeApiDL(NativeApi.initializeApiDLData);

        // Create and prepare native server.
        // Get the function pointer
        final createServer =
            dylib.lookupFunction<_CreateServerC, _CreateServerDart>(
          'create_server',
          isLeaf: true,
        );

        final ReceivePort receivePort = ReceivePort();
        receivePort.listen((message) {});
        args.sendPort.send(receivePort.sendPort);

        await Future.delayed(Duration.zero);

        createServer(
          args.ip.toNativeUtf8(),
          args.port,
          args.backlog,
          args.workers,
          args.sendPort.nativePort,
        );
      },
      (error, stackTrace) {
        print('Fatal error in isolated server!');
        io.stderr
          ..writeln('Fatal error in isolated server!')
          ..writeln(error)
          ..writeln(st.Trace.format(stackTrace));
        io.exit(1);
      },
    );

/* /// Close the server after all requests are handled.
void _$closeServer() => dylib.lookupFunction<Void Function(), void Function()>(
      'close_server',
      isLeaf: true,
    )();
 */
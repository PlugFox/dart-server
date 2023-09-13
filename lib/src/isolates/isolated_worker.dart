import 'dart:async';
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart' as st;
import 'package:uv/src/api/handler.dart';
import 'package:uv/src/util/shared_dylib.dart';

@internal
typedef IsolatedWorkerArguments = ({
  int index,
  Handler handler,
  SendPort sendPort,
});

typedef GetNextRequestDataC = Pointer<ExportedRequestData> Function();
typedef GetNextRequestDataDart = Pointer<ExportedRequestData> Function();

typedef SendResponseToClientC = Int32 Function(
    Int64 clientPtr, Pointer<Utf8> responseData, Uint64 len);
typedef SendResponseToClientDart = int Function(
    int clientPtr, Pointer<Utf8> responseData, int len);

@internal
final class ExportedRequestData extends Struct {
  @Int64()
  external int clientPtr;

  // external Pointer<Uint8> data;
  external Pointer<Utf8> data;

  @Uint64()
  external int len;
}

/// Isolated worker function.
@internal
void isolatedWorker(IsolatedWorkerArguments args) => runZonedGuarded<void>(
      () async {
        final ReceivePort receivePort = ReceivePort();
        final sendPort = receivePort.sendPort;
        receivePort.listen((message) {});

        // Получаем ссылки на функции
        final getNextRequestData =
            dylib.lookupFunction<GetNextRequestDataC, GetNextRequestDataDart>(
                'get_next_request_data');

        final sendResponseToClient = dylib.lookupFunction<SendResponseToClientC,
            SendResponseToClientDart>('send_response_to_client');

        // SendPort to the main isolate.
        args.sendPort.send(sendPort);

        await Future.delayed(Duration.zero);

        Timer.periodic(Duration.zero, (_) async {
          // Вызов функции `get_next_request_data`
          final request = getNextRequestData();
          if (request == nullptr) return;
          /* print('Received data from client: '
              '${}'); */

          final result = await args
              .handler(request.ref.data.toDartString(length: request.ref.len));

          // Вызов функции `send_response_to_client` (например, после обработки данных)
          final body = "<Worker#${args.index}> $result";
          final responseData =
              "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: "
                      "${body.length}\r\n\r\n${body}"
                  .toNativeUtf8();
          sendResponseToClient(
            request.ref.clientPtr,
            responseData,
            responseData.length,
          );
        });

        /* // Prepare native worker and thread pool.
        final workerOnRequestPointer =
            Pointer.fromFunction<Void Function()>(_$workerOnRequest);
        final nativeWorker = dylib.lookupFunction<
            Void Function(Uint16 index,
                Pointer<NativeFunction<Void Function()>>, Uint64 sendPort),
            void Function(int index, Pointer<NativeFunction<Void Function()>>,
                int sendPort)>("create_worker");
        print('Creating worker ${args.index}');
        nativeWorker(args.index, workerOnRequestPointer, sendPort.nativePort); */
      },
      (error, stackTrace) {
        print('Fatal error in isolated worker!');
        io.stderr
          ..writeln('Fatal error in isolated worker!')
          ..writeln(error)
          ..writeln(st.Trace.format(stackTrace));
        io.exit(1);
      },
    );

/*
/// Callback for the native worker.
@pragma('vm:entry-point')
void _$workerOnRequest() {
  _$handler(0);
}
 */

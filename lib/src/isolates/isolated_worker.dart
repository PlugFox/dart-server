import 'dart:async';
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart' as st;
import 'package:uv/src/api/handler.dart';
import 'package:uv/src/api/request.dart';
import 'package:uv/src/util/shared_dylib.dart';

@internal
typedef IsolatedWorkerArguments = ({
  int index,
  Handler handler,
  SendPort sendPort,
});

typedef GetRequestC = Pointer<NativeRequest> Function();
typedef GetRequestDart = Pointer<NativeRequest> Function();

typedef SendResponseC = Int32 Function(
    Int64 client, Pointer<Utf8> responseData, Uint64 len);
typedef SendResponseDart = int Function(
    int client, Pointer<Utf8> responseData, int len);

@internal
final class NativeRequest extends Struct {
  @Int64()
  external int client_ptr; // Указатель на клиентское соединение

  external Pointer<Utf8> method; // GET, POST и т.д.

  external Pointer<Utf8> path; // Путь запроса

  @Uint64()
  external int path_length; // Длина пути запроса

  @Uint8()
  external int version_major; // Версия протокола

  @Uint8()
  external int version_minor; // Версия протокола

  @Uint8()
  external int content_length; // Длина тела запроса

  // Добавь заголовки, если они будут добавлены в будущем

  external Pointer<Void> body; // Указатель на начало тела запроса
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
            dylib.lookupFunction<GetRequestC, GetRequestDart>('get_request');

        final sendResponseToClient = dylib
            .lookupFunction<SendResponseC, SendResponseDart>('send_response');

        // SendPort to the main isolate.
        args.sendPort.send(sendPort);

        await Future.delayed(Duration.zero);

        Timer.periodic(Duration.zero, (_) async {
          // Вызов функции `get_next_request_data`
          final requestPtr = getNextRequestData();
          if (requestPtr == nullptr) return;
          /* final requestData =
              request.ref.data.toDartString(length: request.ref.len);
          print('Received data from client:\n'
              '---------------------------\n'
              '$requestData'
              '\n'
              '---------------------------\n');
           */
          final ref = requestPtr.ref;
          final clientPtr = ref.client_ptr;
          final contentLength = ref.content_length;

          final Uint8List body;
          /* if (contentLength != 0 && ref.body != nullptr) {
            Pointer<Uint8> bodyPtr = ref.body.cast<Uint8>();
            body =
                UnmodifiableUint8ListView(bodyPtr.asTypedList(contentLength));
          } else {
            body = UnmodifiableUint8ListView(Uint8List(0));
          } */
          body = UnmodifiableUint8ListView(Uint8List(0));
          final request = Request(
            method: ref.method.toDartString(),
            url: ref.path.toDartString(length: ref.path_length),
            version: (
              major: ref.version_major,
              minor: ref.version_minor,
            ),
            headers: <String, String>{},
            contentLength: contentLength,
            body: body,
          );
          final result = await args.handler(request);

          // Вызов функции `send_response_to_client` (например, после обработки данных)
          final responseBody = "<Worker#${args.index}>\n${result}";
          final responseData =
              "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: "
                      "${responseBody.length}\r\n\r\n${responseBody}"
                  .toNativeUtf8();
          sendResponseToClient(
            clientPtr,
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

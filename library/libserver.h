#ifndef libserver_h
#define libserver_h

#include "dart/dart_api_dl.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <uv.h>

#define DEFAULT_THREAD_COUNT 4

// Thread context
typedef struct {
    int16_t index;
} ThreadContext;

// Request data structure for the queue
typedef struct {
    uv_tcp_t *client; // Client socket
    void *data;       // Указатель на данные
    size_t len;       // Data length
} RequestData;

// Request queue node (linked list)
typedef struct RequestQueueNode {
    RequestData *request;
    struct RequestQueueNode *next;
} RequestQueueNode;

// Exported request data structure for Dart Worker through FFI
typedef struct {
    int64_t client_ptr; // Указатель на клиентское соединение
    char *data;         // Данные запроса
    size_t len;         // Длина данных
} ExportedRequestData;

/**
 * Initializes the Dart API with the given data pointer.
 *
 * @param data A pointer to the data needed for initializing the Dart API.
 * @return An intptr_t representing the result of the initialization.
 */
DART_EXPORT intptr_t init_dart_api(void *data);

// Создание сервера
DART_EXPORT void create_server(const char *ip, int16_t port, int16_t backlog, int16_t workers, int64_t send_port);

// Получение следующего запроса на обработку из очереди или NULL
DART_EXPORT ExportedRequestData *get_next_request_data();

// Отправка ответа клиенту
DART_EXPORT int send_response_to_client(int64_t client_ptr, const char *response_data, size_t len);

// Получение метрик
DART_EXPORT void metrics();

// Закрытие сервера
DART_EXPORT void close_server();

#endif

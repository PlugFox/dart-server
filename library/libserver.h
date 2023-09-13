#ifndef libserver_h
#define libserver_h

#include "dart/dart_api_dl.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <uv.h>

#define DEFAULT_THREAD_COUNT 4

/**
 * @brief Struct representing the context of a thread.
 *
 */
typedef struct {
    int16_t index; /**< Index of the thread. */
} ThreadContext;

/**
 * @brief Struct representing a request data object.
 *
 */
typedef struct {
    uv_tcp_t *client; // Client socket
    void *data;       // Указатель на данные
    size_t len;       // Data length
} RequestData;

/**
 * @brief A node in the request queue, containing a pointer to the request data and a pointer to the next node in the
 * queue. Linked List implementation.
 */
typedef struct RequestQueueNode {
    RequestData *request;          /**< Pointer to the request data */
    struct RequestQueueNode *next; /**< Pointer to the next node in the queue */
} RequestQueueNode;

/**
 * @brief Struct representing exported request data for Dart Worker through FFI
 *
 */
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

/**
 * @brief Creates and starts a server with the given IP address, port, backlog, number of workers, and send port.
 *
 * @param ip The IP address to bind the server to.
 * @param port The port number to bind the server to.
 * @param backlog The maximum number of pending connections to queue up.
 * @param workers The number of worker threads to use for handling incoming connections.
 * @param send_port Dart SendPort for sending data to the Dart side.
 */
DART_EXPORT void create_server(const char *ip, int16_t port, int16_t backlog, int16_t workers, int64_t send_port);

/**
 * Dequeues the next request data from the queue and returns it as an ExportedRequestData struct.
 * If the queue is empty, returns NULL.
 *
 * @return ExportedRequestData* - a pointer to the exported request data struct
 */
DART_EXPORT ExportedRequestData *get_next_request_data();

/**
 * Sends a response to a client over a TCP connection.
 *
 * @param client_ptr A pointer to the client's TCP connection.
 * @param response_data The data to be sent as a response.
 * @param len The length of the response data.
 * @return Returns 0 if the response was sent successfully, or an error code if there was an error.
 */
DART_EXPORT int send_response_to_client(int64_t client_ptr, const char *response_data, size_t len);

/**
 * @brief Get metrics
 *
 */
DART_EXPORT void metrics();

/**
 * Closes the server by closing all the loops and freeing the memory allocated for them.
 * Also clears all requests from the queue and destroys the queue mutex and condition variable.
 * @param None
 * @return None
 * @note This function should be called only after all the requests have been processed and the server is no longer
 * needed.
 * @note This function should not be called from any of the worker threads.
 * @note This function is exported to Dart.
 * @see clear_all_requests(), uv_mutex_destroy(), uv_cond_destroy(), uv_barrier_destroy(), uv_loop_close(), free()
 */
DART_EXPORT void close_server();

#endif

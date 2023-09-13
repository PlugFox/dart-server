/**
 * @file libserver.c
 * @brief Implementation of a multi-threaded TCP server using libuv library.
 *
 * This file contains the implementation of a multi-threaded TCP server using the libuv library.
 * The server listens on a specified IP address and port, and can handle multiple client connections
 * simultaneously using multiple threads.
 */

#include "libserver.h"
#include "llhttp/llhttp.h"

int thread_count;
uv_barrier_t barrier;
uv_loop_t **loops = NULL;
uv_tcp_t *servers = NULL;
struct sockaddr_in addr;

// Request queue
RequestQueueNode *head = NULL;
RequestQueueNode *tail = NULL;
uv_mutex_t queue_mutex; // Mutex
uv_cond_t queue_cond;   // Condition variable, used to signal that new data is available in the queue

// HTTP parser
llhttp_settings_t settings;

/**
 * Adds a new request to the request queue.
 *
 * @param request The request to be added to the queue.
 */
void enqueue(Request *request) {
    // Allocate memory for a new request node
    RequestQueueNode *new_request = malloc(sizeof(RequestQueueNode));
    if (!new_request) {
        fprintf(stderr, "Failed to allocate memory for new request\n");
        exit(1);
    }

    // Initialize the new request node
    new_request->request = request;
    new_request->next = NULL;

    // Lock the queue mutex and add the new request to the queue
    uv_mutex_lock(&queue_mutex);
    if (!head) {
        head = new_request;
        tail = new_request;
    } else {
        tail->next = new_request;
        tail = new_request;
    }

    // Signal the queue condition variable to notify waiting threads of the new request
    uv_cond_signal(&queue_cond);
    uv_mutex_unlock(&queue_mutex);
}

/**
 * @brief Callback function to free the memory allocated for a handle when it is closed.
 *
 * @param handle The handle to be closed.
 */
void on_connection_close(uv_handle_t *handle) {
    if (!handle) return;
    llhttp_t *parser = handle->data;
    free(parser);
    free(handle);
}

// TODO(plugfox): Вызывать эту функцию при send_response
void free_request(Request *request) {
    if (!request) return;
    free(request->path);
    free(request->body);
    free(request);
}

/**
 * Dequeues a request from the head of the queue.
 * dequeue(1) to wait for a new request
 * dequeue(0) to simply return NULL if the queue is empty.
 *
 * @param shouldWait Determines whether to wait for a new request if the queue is empty.
 *                   Pass 1 to wait for a new request or 0 to simply return NULL if the queue is empty.
 * @return The dequeued request or NULL if the queue is empty and waiting is not required.
 */
Request *dequeue(int shouldWait) {
    uv_mutex_lock(&queue_mutex);

    while (1) {
        if (!head) {
            if (shouldWait) {
                uv_cond_wait(&queue_cond, &queue_mutex); // Ждем нового запроса
                continue; // Начнем сначала после того, как проснемся
            } else {
                uv_mutex_unlock(&queue_mutex);
                return NULL; // Возвращаем NULL, если очередь пуста и ожидание не требуется
            }
        }

        RequestQueueNode *temp = head;
        Request *request = temp->request;

        head = head->next;
        if (!head) {
            tail = NULL;
        }

        // Проверяем, закрыто ли соединение
        // Если соединение закрыто, освобождаем память от запроса и узла списка
        if (uv_is_closing((uv_handle_t *)request->client_ptr)) {
            free_request(request); // Освободим память от этого запроса
            free(temp);            // Освободим память от узла списка
            continue;              // Перейдем к следующему элементу в списке
        }

        uv_mutex_unlock(&queue_mutex);
        free(temp);     // Освободим память от узла списка, но не от запроса
        return request; // Возвращаем действительный запрос
    }
}

/**
 * @brief Allocates memory for a buffer to be used for reading data from a handle.
 *
 * @param handle The handle to read data from.
 * @param suggested_size The suggested size of the buffer to allocate.
 * @param buf The buffer to allocate memory for.
 */
void alloc_buffer(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) {
    /* buf->base = (char *)malloc(suggested_size);
    buf->len = suggested_size;
    if (!buf->base) {
        fprintf(stderr, "Failed to allocate memory for read buffer\n");
        exit(1);
    } */
    *buf = uv_buf_init((char *)malloc(suggested_size), suggested_size);
}

/**
 * @brief Callback function for reading data from a client connection.
 *
 * @param client The client connection stream.
 * @param nread The number of bytes read.
 * @param buf The buffer containing the read data.
 */
void on_read(uv_stream_t *client, ssize_t nread, const uv_buf_t *buf) {
    if (nread <= 0) {
        if (nread == UV_EOF) {
            // Клиент закрыл соединение
            uv_close((uv_handle_t *)client, on_connection_close);
        } else {
            fprintf(stderr, "Read error: %s\n", uv_strerror(nread));
        }
        free(buf->base);
        return;
    }

    // Initialize ParsedRequest
    Request *request = malloc(sizeof(Request));
    if (!request) {
        fprintf(stderr, "Failed to allocate memory for ParsedRequest\n");
        free(buf->base);
        return;
    }
    request->client_ptr = (int64_t)client;

    llhttp_t *parser = client->data;
    if (parser == NULL) {
        fprintf(stderr, "Failed to get parser\n");
        free_request(request);
        free(buf->base);
        return;
    }
    parser->data = request;

    llhttp_errno_t err = llhttp_execute(parser, buf->base, nread);
    if (err != HPE_OK) {
        fprintf(stderr, "HTTP parsing error: %s\n", llhttp_errno_name(err));
        free_request(request);
        free(buf->base);
        uv_close((uv_handle_t *)client, on_connection_close); // Close connection and free parser
        return;
    }

    // Check if the required fields are present and valid
    if (request && request->path && request->method) {
        if (request->body_length != request->content_length) {
            fprintf(stderr, "Body length does not match content length\n");
            request->body_length = 0;
            request->content_length = 0;
            free(request->body);
        }
        enqueue(request);
    } else {
        // Handle invalid request (maybe close the connection or send an error response)
        free_request(request);
        // Close connection if the request is not valid
        uv_close((uv_handle_t *)client, on_connection_close);
    }

    // Освобождаем буфер после того, как обработали его содержимое
    free(buf->base);
}

/**
 * This function is called when a new connection is made to the server.
 * It initializes a new client socket and starts reading data from the client.
 * If there's an error, it closes the client connection.
 *
 * @param server The server stream.
 * @param status The status of the connection.
 */
void on_new_connection(uv_stream_t *server, int status) {
    if (status < 0) {
        fprintf(stderr, "New connection error: %s\n", uv_strerror(status));
        return;
    }

    uv_tcp_t *client = (uv_tcp_t *)malloc(sizeof(uv_tcp_t));
    if (!client) {
        fprintf(stderr, "Failed to allocate memory for client\n");
        return;
    }

    uv_tcp_init(server->loop, client);
    if (uv_accept(server, (uv_stream_t *)client) != 0) {
        uv_close((uv_handle_t *)client, on_connection_close);
        return;
    }

    // Initialize HTTP parser
    llhttp_t *parser = malloc(sizeof(llhttp_t));
    if (!parser) {
        fprintf(stderr, "Failed to allocate memory for llhttp parser\n");
        uv_close((uv_handle_t *)client, on_connection_close);
        return;
    }

    llhttp_init(parser, HTTP_REQUEST, &settings);
    client->data = parser;

    // Start reading from the client
    if (uv_read_start((uv_stream_t *)client, alloc_buffer, on_read) != 0) {
        uv_close((uv_handle_t *)client, on_connection_close);
    }
}

int on_method(llhttp_t *parser, const char *at, size_t length) {
    Request *request = (Request *)parser->data;
    if (!request) return -1;
    request->method = llhttp_method_name(parser->method);
    return 0;
}

int on_url(llhttp_t *parser, const char *at, size_t length) {
    Request *request = (Request *)parser->data;
    if (!request) return -1;
    request->path = strndup(at, length);
    request->path_length = length;
    if (!request->path) {
        fprintf(stderr, "Failed to allocate memory for path\n");
        return -1;
    }
    return 0;
}

int on_version_complete(llhttp_t *parser) {
    Request *request = (Request *)parser->data;
    if (!request) return -1;
    request->version_major = parser->http_major;
    request->version_minor = parser->http_minor;
    return 0;
}

int on_header_field(llhttp_t *parser, const char *at, size_t length) {
    // TODO: Добавьте обработку полей заголовков (если необходимо)
    return 0;
}

int on_header_value(llhttp_t *parser, const char *at, size_t length) {
    // TODO: Добавьте обработку значений заголовков (если необходимо)
    return 0;
}

int on_headers_complete(llhttp_t *parser) {
    Request *request = (Request *)parser->data;
    if (!request) return -1;
    // Устанавливаем общую длину тела из заголовков (если она предоставлена)
    request->content_length = parser->content_length;
    request->body_length = 0;
    return 0;
}

int on_body(llhttp_t *parser, const char *at, size_t length) {
    Request *request = (Request *)parser->data;
    if (!request) return -1;

    // Если заголовок Content-Length не предоставлен, не обрабатываем тело
    if (request->content_length < 1) return -1;

    // Убедитесь, что у вас достаточно места для новых данных.
    if (request->content_length > MAX_BODY_CAPACITY || request->body_length + length > request->content_length) {
        fprintf(stderr, "Body is too large\n");
        return -1;
    }

    // Если это первый блок тела, инициализируем буфер
    if (!request->body) {
        request->body = malloc(request->content_length);
        if (!request->body) {
            fprintf(stderr, "Failed to allocate memory for body\n");
            return -1;
        }
        request->body_length = 0;
    }

    // Копируем данные из `at` в наш буфер тела.
    memcpy(request->body + request->body_length, at, length);
    request->body_length += length;

    return 0;
}

// Setups callbacks for llhttp_settings
void setup_parser_settings() {
    llhttp_settings_init(&settings);
    settings.on_method = on_method;
    settings.on_url = on_url;
    settings.on_version_complete = on_version_complete;
    settings.on_header_field = on_header_field;
    settings.on_header_value = on_header_value;
    settings.on_headers_complete = on_headers_complete;
    settings.on_body = on_body;
    // settings.on_message_complete = on_message_complete;
}

/**
 * @brief This function is the entry point for the worker thread.
 * This function is called by each worker thread
 * It runs the event loop for the thread's UV loop
 *
 * @param arg A void pointer to the argument passed to the thread.
 * @return void
 */
void worker_thread(void *arg) {
    int thread_index = (int)(intptr_t)arg;

    ThreadContext *ctx = loops[thread_index]->data;

    uv_run(loops[thread_index], UV_RUN_DEFAULT);
    uv_loop_close(loops[thread_index]);
    free(loops[thread_index]);
    uv_barrier_wait(&barrier);
}

/**
 * Initializes a barrier and starts multiple threads to listen on the given address and port.
 *
 * @param addr The socket address to listen on.
 * @param backlog The maximum length of the queue of pending connections.
 */
void start_threads(struct sockaddr_in addr, int backlog) {
    // Initializes a barrier with the number of threads plus one.
    uv_barrier_init(&barrier, thread_count + 1);

    // Loops through the number of threads and initializes a new loop for each thread.
    for (int i = 0; i < thread_count; i++) {
        // Creates a new context for the thread.
        ThreadContext *ctx = malloc(sizeof(ThreadContext));
        ctx->index = i;

        // Allocates memory for the loop.
        loops[i] = malloc(sizeof(uv_loop_t)); // uv_loop_new();

        // Stores the context in the loop's data field.
        loops[i]->data = ctx;

        // Initializes the loop.
        // uv_tcp_init(loops[index], &servers[index]);
        uv_loop_init(loops[i]);

        // Initializes a new TCP handle for the loop and binds it to the given address and port.
        uv_tcp_init_ex(loops[i], &servers[i], AF_INET);
        uv_tcp_bind(&servers[i], (const struct sockaddr *)&addr, 0);

        // Starts listening for incoming connections on the TCP handle.
        uv_listen((uv_stream_t *)&servers[i], backlog, on_new_connection);

        // Run the loop in the current thread.
        // uv_run(loops[index], UV_RUN_DEFAULT);

        // Creates a new thread to handle the loop.
        uv_thread_t tid;
        uv_thread_create(&tid, worker_thread, (void *)(intptr_t)i);
    }

    // Waits for all threads to complete before continuing.
    // uv_barrier_wait(&barrier);

    // Destroys the barrier.
    // uv_barrier_destroy(&barrier);
}

/**
 * Initializes the Dart API with the given data pointer.
 *
 * @param data A pointer to the data needed for initializing the Dart API.
 * @return An intptr_t representing the result of the initialization.
 */
DART_EXPORT intptr_t init_dart_api(void *data) {
    return Dart_InitializeApiDL(data);
}

/**
 * @brief Creates and starts a server with the given IP address, port, backlog, number of workers, and send port.
 *
 * @param ip The IP address to bind the server to.
 * @param port The port number to bind the server to.
 * @param backlog The maximum number of pending connections to queue up.
 * @param workers The number of worker threads to use for handling incoming connections.
 * @param send_port Dart SendPort for sending data to the Dart side.
 */
DART_EXPORT void create_server(const char *ip, int16_t port, int16_t backlog, int16_t workers, int64_t send_port) {
    // fprintf(stderr, "Create and start server\n");

    // Инициализация мьютекса и условной переменной
    uv_mutex_init(&queue_mutex);
    uv_cond_init(&queue_cond);

    // Create address
    uv_ip4_addr(ip, port, &addr);

    // If backlog is less than 1 or greater than SOMAXCONN, use the default backlog.
    if (backlog < 1 || backlog > SOMAXCONN) {
        backlog = SOMAXCONN;
    }

    // If workers is less than 1, use the default thread count.
    if (workers < 1) {
        workers = 2;
    }
    thread_count = workers;

    // Динамическое выделение памяти для loops и servers
    loops = (uv_loop_t **)malloc(sizeof(uv_loop_t *) * thread_count);
    servers = (uv_tcp_t *)malloc(sizeof(uv_tcp_t) * thread_count);

    // Initialize HTTP parser
    setup_parser_settings();

    // Start threads
    start_threads(addr, backlog);

    // Emulate some work
    // while (1) {
    //    uv_sleep(1000);
    // }
    // exit(0);
}

/**
 * @brief Clears all requests from the request queue and frees the associated memory.
 *
 * This function locks the queue_mutex and iterates through the request queue, closing any open connections
 * and freeing the memory associated with each request. Once all requests have been cleared, the tail of the
 * queue is set to NULL.
 *
 * @param None
 * @return None
 *
 * @note This function assumes that the queue_mutex has already been initialized.
 * @note This function should be called when the server is shutting down to ensure that all requests are cleared
 * and no memory leaks occur.
 */
void clear_all_requests() {
    uv_mutex_lock(&queue_mutex);

    while (head) {
        RequestQueueNode *temp = head;
        Request *request = temp->request;

        // Закрываем соединение, если оно еще открыто
        if (!uv_is_closing((uv_handle_t *)request->client_ptr)) {
            uv_close((uv_handle_t *)request->client_ptr, on_connection_close);
        }

        // Освобождаем память запроса
        free_request(request);

        head = head->next;
        free(temp);
    }

    tail = NULL; // Поскольку список теперь пуст, tail также должен быть NULL

    uv_mutex_unlock(&queue_mutex);
}

/**
 * Dequeues the next request data from the queue and returns it as an ExportedRequestData struct.
 * If the queue is empty, returns NULL.
 *
 * @return ExportedRequestData* - a pointer to the exported request data struct
 */
DART_EXPORT Request *get_request() {
    return dequeue(0);
}

/**
 * Callback function called after a write operation is completed.
 * Frees the memory allocated for the write request and prints an error message if the status is not successful.
 *
 * @param req The write request.
 * @param status The status of the write operation.
 */
void after_write(uv_write_t *req, int status) {
    fprintf(stderr, "after_write\n");
    if (status) {
        fprintf(stderr, "uv_write error: %s\n", uv_strerror(status));
    }
    free(req);
}

/**
 * Sends a response to a client over a TCP connection.
 *
 * @param client_ptr A pointer to the client's TCP connection.
 * @param response_data The data to be sent as a response.
 * @param len The length of the response data.
 * @return Returns 0 if the response was sent successfully, or an error code if there was an error.
 */
DART_EXPORT int send_response(int64_t client_ptr, const char *response, size_t len) {
    uv_tcp_t *client = (uv_tcp_t *)client_ptr;

    if (!client) {
        fprintf(stderr, "Client is NULL\n");
        return -1;
    }

    if (uv_is_closing((uv_handle_t *)client)) {
        fprintf(stderr, "Client connection is closed\n");
        return -1;
    }

    uv_buf_t buffer = uv_buf_init((char *)response, len);

    // Отправка данных
    int status = uv_write((uv_write_t *)malloc(sizeof(uv_write_t)), (uv_stream_t *)client, &buffer, 1, after_write);

    return status; // Returns 0 on success or an error code
}

/**
 * @brief Get metrics
 *
 */
DART_EXPORT void metrics() {
    printf("Metrics\n");
}

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
DART_EXPORT void close_server() {
    for (int i = 0; i < thread_count; i++) {
        uv_loop_close(loops[i]);
        free(loops[i]);
    }

    // Waits for all threads to complete before continuing.
    // uv_barrier_wait(&barrier);

    // Destroys the barrier.
    uv_barrier_destroy(&barrier);

    free(loops);
    free(servers);
    thread_count = 0;

    // Clears all requests from the queue.
    clear_all_requests();

    uv_mutex_destroy(&queue_mutex);
    uv_cond_destroy(&queue_cond);
}
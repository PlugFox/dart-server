#include "libserver.h"

// Настраиваемая многопоточность

#define DEFAULT_THREAD_COUNT 4

uv_barrier_t barrier;
int thread_count = DEFAULT_THREAD_COUNT;
uv_loop_t *loops[DEFAULT_THREAD_COUNT];
uv_tcp_t servers[DEFAULT_THREAD_COUNT];

// Close handle
void close_cb(uv_handle_t *handle) {
    free(handle);
}

// Allocate buffer
void alloc_buffer(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) {
    *buf = uv_buf_init((char *)malloc(suggested_size), suggested_size);
}

// Write data
void echo_write(uv_write_t *req, int status) {
    if (status < 0) {
        fprintf(stderr, "Write error: %s\n", uv_strerror(status));
    }
    free(req);
}

// On read data
void echo_read(uv_stream_t *client, ssize_t nread, const uv_buf_t *buf) {
    if (nread < 0) {
        if (nread != UV_EOF) {
            fprintf(stderr, "Read error: %s\n", uv_err_name(nread));
        }
        uv_close((uv_handle_t *)client, close_cb);
        return;
    }

    uv_write_t *req = (uv_write_t *)malloc(sizeof(uv_write_t));
    char http_response[] = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: "
                           "12\r\n\r\nHello, world!";
    uv_buf_t wrbuf = uv_buf_init(http_response, strlen(http_response));
    uv_write(req, client, &wrbuf, 1, echo_write);
    free(buf->base);
}

// On new connection
void on_new_connection(uv_stream_t *server, int status) {
    if (status < 0) {
        fprintf(stderr, "New connection error: %s\n", uv_strerror(status));
        return;
    }

    uv_tcp_t *client = (uv_tcp_t *)malloc(sizeof(uv_tcp_t));
    // Здесь мы явно указываем, что новый клиентский сокет
    // должен использовать тот же цикл событий, что и сервер.
    uv_tcp_init(server->loop, client);
    if (uv_accept(server, (uv_stream_t *)client) != 0) {
        uv_close((uv_handle_t *)client, close_cb);
        return;
    }
    if (uv_read_start((uv_stream_t *)client, alloc_buffer, echo_read) != 0) {
        uv_close((uv_handle_t *)client, close_cb);
    }
}

// Worker thread
void worker_thread(void *arg) {
    int thread_index = (int)(intptr_t)arg;
    uv_run(loops[thread_index], UV_RUN_DEFAULT);
    uv_loop_close(loops[thread_index]);
    free(loops[thread_index]);
    uv_barrier_wait(&barrier);
}

// Start threads
// Init barrier and threads, start threads, wait for barrier
void start_threads(struct sockaddr_in addr, int backlog) {
    uv_barrier_init(&barrier, thread_count + 1);
    for (int i = 0; i < thread_count; i++) {
        loops[i] = malloc(sizeof(uv_loop_t));
        uv_loop_init(loops[i]);

        uv_tcp_init_ex(loops[i], &servers[i], AF_INET);
        uv_tcp_bind(&servers[i], (const struct sockaddr *)&addr, 0);
        uv_listen((uv_stream_t *)&servers[i], backlog, on_new_connection);

        uv_thread_t tid;
        uv_thread_create(&tid, worker_thread, (void *)(intptr_t)i);
    }
    uv_barrier_wait(&barrier);
    uv_barrier_destroy(&barrier);
}

/* void start_threads_with_default_backlog(struct sockaddr_in addr) {
    start_threads(addr, SOMAXCONN);
} */

// Send message to Dart through SendPort
void send_data_message(uint64_t port, char *message) {
    /* size_t memsize = sizeof(Request) + strlen(message) + 1 - sizeof(char *);
    Request *ptr = malloc(memsize);
    ptr->subject = port;
    ptr->length = memsize;
    char *s = (char *)ptr + 16;
    strcpy(s, message); */

#ifdef TEST
    printf("Start sending message: %s\n", message);
#endif
    Dart_CObject msg;
    msg.type = Dart_CObject_kString;
    msg.value.as_string = (char *)message;
    /* msg.type = Dart_CObject_kTypedData;
    msg.value.as_typed_data.type = Dart_CObject_kInt64;
    msg.value.as_typed_data.length = memsize - 1;
    msg.value.as_typed_data.values = (uint8_t *)ptr; */

    // Send message
    bool result = Dart_PostCObject_DL(port, &msg);
    if (!result) {
        fprintf(stderr, "Error send to port %ld\n", port);
    }

    /* free(ptr); */
}

// Init Dart API
DART_EXPORT intptr_t init_dart_api(void *data) {
    return Dart_InitializeApiDL(data);
}

// Start server
// ip - address to listen, e.g. 0.0.0.0
// port - port to listen, e.g. 8080
// backlog - max number of connections, e.g. 128
DART_EXPORT void start_server(const char *ip, int port, int backlog, int64_t *ports, int ports_length) {
    fprintf(stderr, "Received %d ports\n", ports_length);
    for (int i = 0; i < ports_length; i++) {
        fprintf(stderr, "Port %d: %ld\n", i + 1, ports[i]);
        send_data_message(ports[i], "Hello from C");
    }

    // Create address
    struct sockaddr_in addr;
    uv_ip4_addr(ip, port, &addr);

    // Start threads
    if (backlog < 1) {
        backlog = SOMAXCONN;
    }
    start_threads(addr, backlog);

    // Just avoid exit and keep server running
    // Emulate some work
    while (1) {
        uv_sleep(1000);
    }
}

void callback(void (*fn)(void)) {
    fn();
}

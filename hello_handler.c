#include "civetweb.h"
#include <string.h>
#include <unistd.h>

int hello_handler(struct mg_connection *conn, void *cbdata) {
    mg_printf(conn, "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nHello World");
    return 200; // Не забывайте возвращать код ответа
}

int main(void) {
    const char *options[] = {
        "document_root", ".", "listening_ports", "8080", "request_timeout_ms", "10000", "error_log_file",
        "error.log",     NULL};

    struct mg_callbacks callbacks;
    struct mg_context *ctx;

    memset(&callbacks, 0, sizeof(callbacks));

    ctx = mg_start(&callbacks, 0, options);

    mg_set_request_handler(ctx, "**", hello_handler, 0);

    while (1) {
        sleep(10);
    }

    mg_stop(ctx);

    return 0;
}

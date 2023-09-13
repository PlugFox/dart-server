
/* fprintf(stderr, "Received %d ports\n", ports_length);
for (int i = 0; i < ports_length; i++) {
    fprintf(stderr, "Port %d: %ld\n", i + 1, ports[i]);
    send_data_message(ports[i], "Hello from C");
} */

// // Send message to Dart through SendPort
// void send_data_message(uint64_t port, char *message) {
//     /* size_t memsize = sizeof(Request) + strlen(message) + 1 - sizeof(char *);
//     Request *ptr = malloc(memsize);
//     ptr->subject = port;
//     ptr->length = memsize;
//     char *s = (char *)ptr + 16;
//     strcpy(s, message); */
//
// #ifdef TEST
//     printf("Start sending message: %s\n", message);
// #endif
//     Dart_CObject msg;
//     msg.type = Dart_CObject_kString;
//     msg.value.as_string = (char *)message;
//     /* msg.type = Dart_CObject_kTypedData;
//     msg.value.as_typed_data.type = Dart_CObject_kInt64;
//     msg.value.as_typed_data.length = memsize - 1;
//     msg.value.as_typed_data.values = (uint8_t *)ptr; */
//
//     // Send message
//     bool result = Dart_PostCObject_DL(port, &msg);
//     if (!result) {
//         fprintf(stderr, "Error send to port %ld\n", port);
//     }
//
//     /* free(ptr); */
// }

// Save the request data
/* ParsedRequest *request = malloc(sizeof(ParsedRequest));
if (!request) {
    fprintf(stderr, "Failed to allocate memory for request data\n");
    exit(1);
}
request->client = (uv_tcp_t *)client;
request->data = buf->base;
request->len = nread;


// ThreadContext *ctx = server->loop->data;

// This function starts reading data from the client
// If there's an error, it closes the client connection
if (uv_read_start((uv_stream_t *)client, alloc_buffer, on_read) != 0) {
    uv_close((uv_handle_t *)client, close_cb);
}
*/

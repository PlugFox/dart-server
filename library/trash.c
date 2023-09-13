
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
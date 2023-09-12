#ifndef libserver_h
#define libserver_h

#include "dart/dart_api_dl.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <uv.h>

/* typedef struct {
  uint64_t subject;
  uint64_t length;
  char *message;
} Request; */

void start_server(const char *ip, int port, int backlog, int64_t *ports, int ports_length);

#endif

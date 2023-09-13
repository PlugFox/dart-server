#include "libserver.h"

const int workers = 4;

// Entry point
int main() {
    create_server("0.0.0.0", 5050, 128, workers, -1);
    // close_server();
    return 0;
}
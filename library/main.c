#include "libserver.h"

// Entry point
int main() {
    start_server("0.0.0.0", 5050, 128, NULL, 0);
    return 0;
}
cmake_minimum_required(VERSION 3.10)

project(MyLibuvServer LANGUAGES C)

# Настройка компиляции с использованием c11
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_FLAGS_DEBUG "-g")
set(CMAKE_C_FLAGS_RELEASE "-O3")

# Находим необходимые библиотеки
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBUV REQUIRED IMPORTED_TARGET libuv)

# Добавляем наш исходный файл
add_executable(server library/server.c)

# Линкуем наш исполняемый файл с библиотекой libuv
target_link_libraries(server PRIVATE PkgConfig::LIBUV)

# Устанавливаем целевую директорию для компиляции в build/
set_target_properties(server PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build")

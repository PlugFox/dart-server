cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

project(LibuvServer VERSION 1.0.0 LANGUAGES C)

# Настройка компиляции с использованием c11
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON) # -fPIC
set(CMAKE_C_FLAGS_DEBUG "-g")
set(CMAKE_C_FLAGS_RELEASE "-O3")

include_directories($ENV{DART_SDK}/include/)

# Находим необходимые библиотеки
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBUV REQUIRED IMPORTED_TARGET libuv)

# Добавляем наш исходный файл
#add_executable(server library/server.c)
add_library(server SHARED library/libserver.c)

# Линкуем наш исполняемый файл с библиотекой libuv
target_link_libraries(server PRIVATE PkgConfig::LIBUV)

# Устанавливаем целевую директорию для компиляции в build/
set_target_properties(server PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build"
)

# Настройка имени библиотеки в зависимости от платформы
if(WIN32)
    set_target_properties(server PROPERTIES OUTPUT_NAME "server")
elseif(APPLE)
    set_target_properties(server PROPERTIES OUTPUT_NAME "server")
else()
    set_target_properties(server PROPERTIES OUTPUT_NAME "server")
endif()
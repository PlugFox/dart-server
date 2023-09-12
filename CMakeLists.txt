cmake_minimum_required(VERSION 3.22 FATAL_ERROR)

project(LibuvServer VERSION 1.0.0 LANGUAGES C)

# Настройка компиляции с использованием c11
set(CC clang)
set(CXX clang++)
set(CMAKE_C_COMPILER clang)
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON) # -fPIC
#set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_C_FLAGS_DEBUG "-g")
set(CMAKE_C_FLAGS_RELEASE "-O3")

# Находим необходимые библиотеки
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBUV REQUIRED IMPORTED_TARGET libuv)

# Добавляем наш исходный файл
add_library(libserver SHARED library/libserver.c library/libserver.def library/dart/dart_api_dl.c)
#target_include_directories(libserver PUBLIC library/dart/)

# Линкуем наш исполняемый файл с библиотекой libuv
target_link_libraries(libserver PRIVATE PkgConfig::LIBUV)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/library)

target_compile_options(libserver PRIVATE
  -std=c17
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  target_compile_options(libserver PRIVATE
    -fcolor-diagnostics
    -fansi-escape-codes
    -O0
    -g
  )
else()
  target_compile_options(libserver PRIVATE
    -O3
    -Wall
    -Wextra
    -pedantic
    -Werror
  )
endif()

# Добавляем исполняемый файл
add_executable(server library/main.c)
target_link_libraries(server libserver)

# Устанавливаем целевую директорию для компиляции в build/
set_target_properties(libserver PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build"
)

#find_package(Threads REQUIRED)

#set_target_properties(libserver PROPERTIES
#    FRAMEWORK TRUE
#    PUBLIC_HEADER libserver.h
#    OUTPUT_NAME libserver
#    VERSION ${PROJECT_VERSION}
#    SOVERSION 1
#    OUTPUT_NAME "libserver"
#)

# Настройка имени библиотеки в зависимости от платформы
if(WIN32)
    set_target_properties(libserver PROPERTIES OUTPUT_NAME "server")
elseif(APPLE)
    set_target_properties(libserver PROPERTIES OUTPUT_NAME "server")
else()
    set_target_properties(libserver PROPERTIES OUTPUT_NAME "server")
endif()

# Testing:
#add_executable(test_runner test/test_runner.c test/unity/unity.c)
#target_link_libraries(test_runner libserver ${CMAKE_THREAD_LIBS_INIT})
#enable_testing()
#add_test(NAME test_runner COMMAND test_runner)
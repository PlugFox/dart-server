import 'dart:ffi';
import 'dart:io' as io;

/// Returns the path to the dynamic library.
String _getDynamicLibraryPath() {
  const path = String.fromEnvironment('DYLIB_PATH');
  if (path.isNotEmpty) {
    return path;
  } else if (io.Platform.isLinux) {
    return 'build/libserver.so';
  } else if (io.Platform.isMacOS) {
    return 'build/libserver.dylib';
  } else if (io.Platform.isWindows) {
    return 'build/server.dll';
  } else {
    throw Exception('Platform not supported');
  }
}

/// Shared dynamic library across isolates.
final DynamicLibrary dylib = DynamicLibrary.open(_getDynamicLibraryPath());

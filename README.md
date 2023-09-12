## libuv

- [libuv](https://github.com/libuv/libuv)
- [documentation](https://docs.libuv.org/en/v1.x/guide/introduction.html)

## Dependencies

Install dependencies:

- `make`: Build management tool.
- `cmake`: Cross-platform build automation system.
- `clang`: Compiler for C, C++, and Objective-C.
- `ninja-build`: Small build system focused on speed.
- `llvm`: Collection of modular and reusable compilers and toolchains.
- `libuv1-dev`: Cross-platform asynchronous I/O support library.
- `pkg-config`: Tool that helps build scripts determine libraries and their locations.
- `gdb`: GNU Debugger.
- `clang-format`: Tool for automatic code formatting.

### Linux
```bash
sudo apt-get update
sudo apt-get install -y make cmake clang ninja-build llvm libuv1-dev pkg-config gdb clang-format
```

### Windows
```bash
choco install -y make cmake clang ninja llvm mingw libuv pkgconfig
```

### macOS
```bash
brew install make cmake ninja llvm pre-commit clang-format libuv pkg-config
```

Setup the [Dart SDK](https://dart.dev/get-dart) path, e.g.:

```bash
sudo apt-get update
sudo apt-get install apt-transport-https
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.g
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.g/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
sudo apt-get update
sudo apt-get install dart
echo 'PATH="$PATH:/usr/lib/dart/bin"' >> ~/.zshrc
echo 'PATH="$PATH:/usr/lib/dart/bin"' >> ~/.profile
```

Copy the `include` from the Dart SDK to the `library/dart` directory:

```bash
cp -r /usr/lib/dart/include library/dart
```

* If you have a problem with header imports in your IDE, you can try to one-time build with `make`.

## Build

```bash
make debug
```

or

```bash
make release
```

## Format

```bash
make format
```

## Test

```bash
make test
```
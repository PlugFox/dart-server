## libuv

- [libuv](https://github.com/libuv/libuv)
- [documentation](https://docs.libuv.org/en/v1.x/guide/introduction.html)

## Dependencies

Install dependencies:

```bash
sudo apt-get update
sudo apt-get install -y gcc make cmake g++ libuv1-dev pkg-config gdb clang-format
```

Specify the [Dart SDK](https://dart.dev/get-dart) path, e.g.:

```bash
sudo apt-get update
sudo apt-get install apt-transport-https
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.g
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.g/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
sudo apt-get update
sudo apt-get install dart
echo 'PATH="$PATH:/usr/lib/dart/bin"' >> ~/.zshrc
echo 'export DART_SDK=/usr/lib/dart' >> ~/.zshrc
echo 'PATH="$PATH:/usr/lib/dart/bin"' >> ~/.profile
echo 'export DART_SDK=/usr/lib/dart' >> ~/.profile
```
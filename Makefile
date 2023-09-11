.PHONY: debug release clean

# Build server library
#
# Requires:
# sudo apt-get update && sudo apt-get install -y gcc make cmake g++ libuv1-dev pkg-config gdb
debug:
	@echo "Building..."
	@mkdir -p build
	@cd build && cmake .. -DCMAKE_BUILD_TYPE=Debug
	@cd build && make --no-print-directory
	@echo "Build done. Result located at build/server"

# Build server library
#
# Requires:
# sudo apt-get update && sudo apt-get install -y gcc make cmake g++ libuv1-dev pkg-config gdb
release:
	@echo "Building release..."
	@mkdir -p build
	@cd build && cmake .. -DCMAKE_BUILD_TYPE=Release
	@cd build && make --no-print-directory
	@echo "Build done. Result located at build/server"

# Clean build
clean:
	@rm -rf build/
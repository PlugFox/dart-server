.PHONY: setup debug release clean

BUILD_DIR := build

# Prepare
setup:
	@pre-commit install

# Build server library
debug: _prepare-build-dir
	@echo "Building debug..."
	@cd $(BUILD_DIR) && cmake -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug .. && ninja
	@echo "Make a link to compile_commands.json"
	@rm -f compile_commands.json && ln -s build/compile_commands.json compile_commands.json

# Build server library
release: _prepare-build-dir
	@echo "Building release..."
	@cd $(BUILD_DIR) && cmake -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Release .. && ninja
	@echo "Make a link to compile_commands.json"
	@rm -f compile_commands.json && ln -s build/compile_commands.json compile_commands.json

# Clean build
clean:
	@rm -rf build/

#test: debug
#	@echo "Running tests..."
#	@(cd $(BUILD_DIR) && ctest --verbose)

#format:
#	@clang-format -i -style=file bin/*.c
#	@clang-format -i -style=file lib/src/*.c
#	@clang-format -i -style=file lib/include/*.h
#	@clang-format -i -style=file test/*.c

_prepare-build-dir:
	@mkdir $(BUILD_DIR) || true
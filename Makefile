ODIN=odin
ODIN_PATH=$(shell $(ODIN) root)
SRC=src

# Desktop
SRC_DESKTOP=$(SRC)/main_desktop
OUT_DIR=build
OUT_DIR_DESKTOP=$(OUT_DIR)/desktop
DEBUG_BINARY=app-debug.bin
RELEASE_BINARY=app.bin
ODIN_FLAGS=-vet -strict-style -vet-tabs -disallow-do -warnings-as-errors

# Web
SRC_WEB=$(SRC)/main_web
OUT_DIR_WEB=$(OUT_DIR)/web
OUT_APP_WEB=$(OUT_DIR_WEB)/app
ODIN_JS_PATH=$(ODIN_PATH)core/sys/wasm/js/odin.js
RAYLIB_WASM_LIB=env.o
FILES_WEB=$(OUT_APP_WEB).wasm.o \
           $(ODIN_PATH)vendor/raylib/wasm/libraylib.a \
           $(ODIN_PATH)vendor/raylib/wasm/libraygui.a
EMCC_FLAGS=-sUSE_GLFW=3 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS \
           --shell-file $(SRC_WEB)/index_template.html --preload-file roms

all: build-desktop build-web

build-desktop:
	@mkdir -p $(OUT_DIR_DESKTOP)
	odin build $(SRC_DESKTOP) -out:$(OUT_DIR_DESKTOP)/$(RELEASE_BINARY) $(ODIN_FLAGS)

run-desktop:
	@mkdir -p $(OUT_DIR_DESKTOP)
	odin run $(SRC_DESKTOP) -debug -out:$(OUT_DIR_DESKTOP)/$(DEBUG_BINARY) $(ODIN_FLAGS) -- ../../roms/tests/1-chip8-logo.ch8

build-web: $(OUT_APP_WEB) copy-odin-js link-web

$(OUT_APP_WEB):
	@mkdir -p $(OUT_DIR_WEB)
	$(ODIN) build $(SRC_WEB) -target:js_wasm32 -build-mode:obj \
		-define:RAYLIB_WASM_LIB=$(RAYLIB_WASM_LIB) \
		-define:RAYGUI_WASM_LIB=$(RAYLIB_WASM_LIB) \
		-vet -strict-style -out:$(OUT_APP_WEB)

copy-odin-js:
	cp $(ODIN_JS_PATH) $(OUT_DIR_WEB)/

link-web:
	emcc -o $(OUT_DIR_WEB)/index.html $(FILES_WEB) $(EMCC_FLAGS)
	rm $(OUT_APP_WEB).wasm.o

clean:
	rm -rf $(OUT_DIR)

.PHONY: all build-desktop run-desktop build-web copy-odin-js link-web clean

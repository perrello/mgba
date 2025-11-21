#!/bin/bash
set -e

CORE_NAME="mgba"
BUILD_DIR="build-emscripten"
OUTPUT_DIR="dist-wasm"

echo "======== 1. Cleaning old builds ========"
rm -rf $BUILD_DIR $OUTPUT_DIR
mkdir -p $BUILD_DIR
mkdir -p $OUTPUT_DIR

echo "Removing old object files and bc archives..."
find ./src -name "*.o" -delete
rm -f ${CORE_NAME}_libretro_emscripten.bc

echo "======== 2. Building LLVM archive via Makefile.libretro ========"
emmake make -f Makefile.libretro platform=emscripten clean
emmake make -f Makefile.libretro platform=emscripten -j8

echo "======== 3. Extracting .bc objects ========"
mkdir -p $BUILD_DIR/objs
cd $BUILD_DIR/objs
emar x ../../${CORE_NAME}_libretro_emscripten.bc

echo "======== 4. Linking to WASM + JS ========"
emcc *.o \
  -O3 \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s WASM=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s FILESYSTEM=1 \
  -s ASSERTIONS=0 \
  -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
  -o ../../$OUTPUT_DIR/${CORE_NAME}_libretro.js

cd ../../

echo "======== 5. Build complete! ========"
echo "Generated files:"
echo " - $OUTPUT_DIR/${CORE_NAME}_libretro.js"
echo " - $OUTPUT_DIR/${CORE_NAME}_libretro.wasm"
echo ""
echo "DONE!"
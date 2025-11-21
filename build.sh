#!/bin/bash
set -e

CORE_NAME="mgba"
BUILD_DIR="build-emscripten"
OUTPUT_DIR="dist-wasm"

RETROARCH_DIR="./retroarch-linker"   # RetroArch komt lokaal hier
CORE_BC="${CORE_NAME}_libretro_emscripten.bc"

echo "======== 1. Prepare RetroArch linker ========"
if [ ! -d "$RETROARCH_DIR" ]; then
  echo "Cloning RetroArch once..."
  git clone https://github.com/libretro/RetroArch.git "$RETROARCH_DIR"
fi

echo "======== 2. Clean old builds ========"
rm -rf $BUILD_DIR $OUTPUT_DIR
mkdir -p $BUILD_DIR/objs
mkdir -p $OUTPUT_DIR

echo "======== 3. Build LLVM BC (core) ========"
emmake make -f Makefile.libretro platform=emscripten clean
emmake make -f Makefile.libretro platform=emscripten -j8

if [ ! -f "$CORE_BC" ]; then
  echo "ERROR: $CORE_BC not found!"
  exit 1
fi

echo "======== 4. Copy BC into RetroArch linker ========"
cp "$CORE_BC" "$RETROARCH_DIR/libretro_emscripten.bc"

echo "======== 5. Link using RetroArch Makefile.emscripten ========"
cd "$RETROARCH_DIR"

# Build frontend + wasm core using RetroArch linker
emmake make -f Makefile.emscripten LIBRETRO=${CORE_NAME} -j all

echo "======== 6. Rename output to remove libretro prefix ========"
cp ${CORE_NAME}_libretro.js   "../$OUTPUT_DIR/${CORE_NAME}.js"
cp ${CORE_NAME}_libretro.wasm "../$OUTPUT_DIR/${CORE_NAME}.wasm"

cd ..

echo "======== DONE ========"
echo "Built:"
echo "  $OUTPUT_DIR/${CORE_NAME}.js"
echo "  $OUTPUT_DIR/${CORE_NAME}.wasm"
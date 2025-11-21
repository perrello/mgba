#!/bin/bash
set -e

CORE_NAME="mgba"
BUILD_DIR="build-emscripten"
OUTPUT_DIR="dist-wasm"

RETROARCH_DIR="./retroarch-linker"   # Neem deze zelf op in je eigen repo
CORE_BC="${CORE_NAME}_libretro_emscripten.bc"

echo "======== 1. Ensure RetroArch linker directory exists ========"
if [ ! -d "$RETROARCH_DIR" ]; then
  echo "ERROR: retroarch-linker directory missing!"
  echo "Kopieer de RetroArch linker map 1-op-1 in je eigen repo."
  exit 1
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

echo "======== 4. Inject custom SGB border INTO MGBA CORE ========"
CUSTOM_BORDER="./custom-assets/sgb-border.png"
MGBA_BORDER="./src/platform/libretro/assets/sgb-border.png"

if [ -f "$CUSTOM_BORDER" ]; then
  if [ -f "$MGBA_BORDER" ]; then
    cp "$CUSTOM_BORDER" "$MGBA_BORDER"
    echo "Custom border applied to mGBA"
  else
    echo "WARNING: mGBA border path not found: $MGBA_BORDER"
  fi
else
  echo "No custom border provided"
fi

echo "======== 5. Copy core BC into RetroArch linker ========"
cp "$CORE_BC" "$RETROARCH_DIR/libretro_emscripten.bc"

echo "======== 6. Build RetroArch WASM linker ========"
cd "$RETROARCH_DIR"

emmake make -f Makefile.emscripten LIBRETRO=${CORE_NAME} clean
emmake make -f Makefile.emscripten LIBRETRO=${CORE_NAME} -j all

echo "======== 7. Export output ========"
cp ${CORE_NAME}_libretro.js   "../$OUTPUT_DIR/${CORE_NAME}.js"
cp ${CORE_NAME}_libretro.wasm "../$OUTPUT_DIR/${CORE_NAME}.wasm"

cd ..

echo "======== DONE ========"
echo "Built:"
echo "  $OUTPUT_DIR/${CORE_NAME}.js"
echo "  $OUTPUT_DIR/${CORE_NAME}.wasm"
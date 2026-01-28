#!/bin/bash
set -e

CORE_NAME="mgba"
BUILD_DIR="build-emscripten"
OUTPUT_DIR="dist-wasm"
HAVE_THREADS=0
PROXY_TO_PTHREAD=0
HAVE_RWEBAUDIO=1

RETROARCH_DIR="./retroarch-linker"   # Add this yourself in your own repo
CORE_BC="${CORE_NAME}_libretro_emscripten.bc"

while [ $# -gt 0 ]; do
  case "$1" in
    --pthreads)
      HAVE_THREADS=1
      PROXY_TO_PTHREAD=1
      HAVE_RWEBAUDIO=0
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--pthreads]"
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1"
      exit 1
      ;;
  esac
done

echo "======== 1. Ensure RetroArch linker directory exists ========"
if [ ! -d "$RETROARCH_DIR" ]; then
  echo "ERROR: retroarch-linker directory missing!"
  echo "Copy the RetroArch linker folder 1-to-1 into your own repo."
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
emmake make -f Makefile.emscripten LIBRETRO=${CORE_NAME} HAVE_AL=0 HAVE_THREADS=${HAVE_THREADS} PROXY_TO_PTHREAD=${PROXY_TO_PTHREAD} HAVE_RWEBAUDIO=${HAVE_RWEBAUDIO} -j all VERBOSE=1

echo "======== 7. Export output ========"
cp ${CORE_NAME}_libretro.js   "../$OUTPUT_DIR/${CORE_NAME}.js"
cp ${CORE_NAME}_libretro.wasm "../$OUTPUT_DIR/${CORE_NAME}.wasm"
if [ -f "${CORE_NAME}_libretro.worker.js" ]; then
  cp "${CORE_NAME}_libretro.worker.js" "../$OUTPUT_DIR/${CORE_NAME}.worker.js"
fi

cd ..

echo "======== DONE ========"
echo "Built:"
echo "  $OUTPUT_DIR/${CORE_NAME}.js"
echo "  $OUTPUT_DIR/${CORE_NAME}.wasm"
if [ -f "$OUTPUT_DIR/${CORE_NAME}.worker.js" ]; then
  echo "  $OUTPUT_DIR/${CORE_NAME}.worker.js"
fi

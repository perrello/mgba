#include <stdint.h>
#include <emscripten/emscripten.h>

// Forward declarations (opaque types)
struct GBA;
struct GBASIO;

// Externe functies uit mGBA die al in de core zitten
extern uint16_t GBAIORead(struct GBA *gba, uint32_t address);
extern void     GBAIOWrite(struct GBA *gba, uint32_t address, uint16_t value);
extern uint16_t GBASIOWriteRegister(struct GBASIO *sio, uint32_t address, uint16_t value);

// ---- JS-exported wrappers ----

EMSCRIPTEN_KEEPALIVE
uint16_t wasm_link_gba_read(struct GBA* gba, uint32_t address) {
    return GBAIORead(gba, address);
}

EMSCRIPTEN_KEEPALIVE
void wasm_link_gba_write(struct GBA* gba, uint32_t address, uint16_t value) {
    GBAIOWrite(gba, address, value);
}

EMSCRIPTEN_KEEPALIVE
uint16_t wasm_link_gba_sio_write(struct GBASIO* sio, uint32_t address, uint16_t value) {
    return GBASIOWriteRegister(sio, address, value);
}
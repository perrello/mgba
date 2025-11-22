#include <stdint.h>
#include <emscripten/emscripten.h>

// Forward declarations (opaque structs)
struct GB;

// External mGBA API (already compiled in core)
extern uint8_t GBIORead(struct GB *gb, uint32_t address);
extern void    GBIOWrite(struct GB *gb, uint32_t address, uint8_t value);

// ---- Exported for JS ----

EMSCRIPTEN_KEEPALIVE
uint8_t wasm_link_gb_read(struct GB* gb, uint32_t address) {
    return GBIORead(gb, address);
}

EMSCRIPTEN_KEEPALIVE
void wasm_link_gb_write(struct GB* gb, uint32_t address, uint8_t value) {
    GBIOWrite(gb, address, value);
}
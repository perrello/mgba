#include "link_cable.h"
#include <stdio.h>

struct LinkCableCallbacks g_link_cable_callbacks = {0};

void link_cable_set_callbacks(const struct LinkCableCallbacks* cb) {
    g_link_cable_callbacks = *cb;
}

// ==============================
// GBA
// ==============================

// CPU writes data -> OUTGOING
void gba_link_cable_write(int playerId, uint32_t value, int bits) {
    fprintf(stderr, "[CORE][GBA] WRITE pid=%d val=%u bits=%d\n", playerId, value, bits);
    if (g_link_cable_callbacks.on_write)
        g_link_cable_callbacks.on_write(LINK_SYS_GBA, playerId, value, bits);
}

// CPU receives data -> INCOMING
void gba_link_cable_read(int playerId, uint32_t value, int bits) {
    fprintf(stderr, "[CORE][GBA] READ pid=%d val=%u bits=%d\n", playerId, value, bits);
    if (g_link_cable_callbacks.on_read)
        g_link_cable_callbacks.on_read(LINK_SYS_GBA, playerId, value, bits);
}

// ==============================
// GB
// ==============================

void gb_link_cable_write(int playerId, uint32_t value, int bits) {
    fprintf(stderr, "[CORE][GB] WRITE pid=%d val=%u bits=%d\n", playerId, value, bits);
    if (g_link_cable_callbacks.on_write)
        g_link_cable_callbacks.on_write(LINK_SYS_GB, playerId, value, bits);
}

void gb_link_cable_read(int playerId, uint32_t value, int bits) {
    fprintf(stderr, "[CORE][GB] READ pid=%d val=%u bits=%d\n", playerId, value, bits);
    if (g_link_cable_callbacks.on_read)
        g_link_cable_callbacks.on_read(LINK_SYS_GB, playerId, value, bits);
}
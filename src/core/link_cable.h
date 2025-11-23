#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define LINK_SYS_GB   0
#define LINK_SYS_GBA  1

typedef void (*LinkSessionStartCallback)(int system, int playerId);
typedef void (*LinkWriteCallback)(int system, int playerId, uint32_t value, int bits);
typedef void (*LinkReadCallback)(int system, int playerId, uint32_t value, int bits);

struct LinkCableCallbacks {
    LinkSessionStartCallback on_session_start;
    LinkWriteCallback        on_write;   // CPU writes OUTGOING data
    LinkReadCallback         on_read;    // CPU receives INCOMING data
};

extern struct LinkCableCallbacks g_link_cable_callbacks;

void link_cable_set_callbacks(const struct LinkCableCallbacks* cb);

// GBA
void gba_link_cable_write(int playerId, uint32_t value, int bits);
void gba_link_cable_read (int playerId, uint32_t value, int bits);

// GB
void gb_link_cable_write(int playerId, uint32_t value, int bits);
void gb_link_cable_read (int playerId, uint32_t value, int bits);

#ifdef __cplusplus
}
#endif
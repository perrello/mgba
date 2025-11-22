#include <emscripten/emscripten.h>
#include <string.h>

#include "../deps/rcheevos/include/rc_client.h"
#include "../deps/rcheevos/include/rc_api_request.h"

static rc_client_t* g_client = NULL;
static uint8_t* g_ram = NULL;
static uint32_t g_ram_size = 0;

/* Because rcheevos gives us a callback pointer, we store it */
#define MAX_PENDING 128

static rc_client_server_callback_t g_callbacks[MAX_PENDING];
static void* g_callback_userdata[MAX_PENDING];
static int g_callback_used[MAX_PENDING];

/* exposed functions from JS */
extern void js_rcheevos_server_request(int request_id, const char* url, const char* post);
extern void js_rcheevos_event_achievement(uint32_t achievement_id);

static uint32_t RC_CCONV wasm_memory_read(uint32_t address, uint8_t* buffer, uint32_t num_bytes, rc_client_t* client)
{
    if (!g_ram || address >= g_ram_size)
        return 0;

    uint32_t max_read = g_ram_size - address;
    if (num_bytes > max_read)
        num_bytes = max_read;

    memcpy(buffer, g_ram + address, num_bytes);
    return num_bytes;
}

static void RC_CCONV wasm_event_handler(const rc_client_event_t* event, rc_client_t* client)
{
    if (event->type == RC_CLIENT_EVENT_ACHIEVEMENT_TRIGGERED)
    {
        if (event->achievement)
            js_rcheevos_event_achievement(event->achievement->id);
    }
}

static int alloc_request_slot(void)
{
    for (int i = 0; i < MAX_PENDING; i++)
    {
        if (!g_callback_used[i])
        {
            g_callback_used[i] = 1;
            return i;
        }
    }
    return -1;
}

static void RC_CCONV wasm_server_call(
    const rc_api_request_t* request,
    rc_client_server_callback_t callback,
    void* callback_data,
    rc_client_t* client)
{
    int slot = alloc_request_slot();
    if (slot < 0)
        return;

    g_callbacks[slot] = callback;
    g_callback_userdata[slot] = callback_data;

    js_rcheevos_server_request(
        slot,
        request->url,
        request->post_data
    );
}

EMSCRIPTEN_KEEPALIVE
void wasm_rcheevos_process_server_response(int request_id, const char* body, int http_status)
{
    if (request_id < 0 || request_id >= MAX_PENDING || !g_callback_used[request_id])
        return;

    rc_api_server_response_t resp;
    resp.body = body;
    resp.body_length = strlen(body);
    resp.http_status_code = http_status;

    g_callbacks[request_id](&resp, g_callback_userdata[request_id]);

    g_callback_used[request_id] = 0;
}

EMSCRIPTEN_KEEPALIVE
void wasm_rcheevos_init(uint8_t* ram, uint32_t ram_size)
{
    g_ram = ram;
    g_ram_size = ram_size;

    memset(g_callback_used, 0, sizeof(g_callback_used));

    g_client = rc_client_create(wasm_memory_read, wasm_server_call);
    rc_client_set_event_handler(g_client, wasm_event_handler);
    rc_client_set_allow_background_memory_reads(g_client, 1);
}

static void RC_CCONV load_cb(int result, const char* error, rc_client_t* client, void* userdata)
{
    /* optional: expose to JS */
}

EMSCRIPTEN_KEEPALIVE
void wasm_rcheevos_load_game(const char* hash)
{
    rc_client_begin_load_game(g_client, hash, load_cb, NULL);
}

EMSCRIPTEN_KEEPALIVE
void wasm_rcheevos_do_frame(void)
{
    if (rc_client_is_processing_required(g_client))
        rc_client_do_frame(g_client);
}
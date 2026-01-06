#pragma once

#include <dmsdk/sdk.h>

enum MESSAGE_ID
{
    MSG_SIGN_IN = 1,
    MSG_SIGN_OUT = 2,
};

enum STATUS
{
    STATUS_SUCCESS = 1,
    STATUS_FAILED = 2
};

struct gsi_callback
{
    gsi_callback() : m_L(0), m_Callback(LUA_NOREF), m_Self(LUA_NOREF) {}
    lua_State* m_L;
    int m_Callback;
    int m_Self;
};


struct CallbackData
{
    MESSAGE_ID msg;
    char* json;
};

void gsi_set_callback(lua_State* L, int pos);
void gsi_callback_initialize();
void gsi_callback_finalize();
void gsi_callback_update();
void gsi_add_to_queue(MESSAGE_ID msg, const char* json);
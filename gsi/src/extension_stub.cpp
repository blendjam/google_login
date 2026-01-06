#if !defined(DM_PLATFORM_IOS) && ! defined(DM_PLATFORM_ANDROID)

#include "extension.h"

int EXTENSION_LOGIN(lua_State* L) {
    dmLogInfo("GSI: login (stub)");
    return 0;
}

int EXTENSION_GET_SERVER_AUTH_CODE(lua_State* L) {
    dmLogInfo("GSI: get server auth code");
    return 0;
}

int EXTENSION_LOGOUT(lua_State* L) {
    dmLogInfo("GSI: logout (stub)");
    return 0;
}

void EXTENSION_INITIALIZE(lua_State* L, const char* client_id) {
    dmLogInfo("GSI: initialized (stub)");
}

void EXTENSION_UPDATE(lua_State* L) {
}

void EXTENSION_APP_ACTIVATE(lua_State* L) {
}

void EXTENSION_APP_DEACTIVATE(lua_State* L) {
}

void EXTENSION_FINALIZE(lua_State* L) {
}

#endif
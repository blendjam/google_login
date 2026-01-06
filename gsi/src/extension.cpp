#include "extension.h"
#include "gsi_callback.h"

// This is the entry point of the extension. It defines Lua API of the extension.

static int Lua_SetCallback(lua_State* L) {
    gsi_set_callback(L, 1);
    return 0;
}

static const luaL_reg lua_functions[] = {
    {"login", EXTENSION_LOGIN},
    {"logout", EXTENSION_LOGOUT},
    {"get_server_auth_code", EXTENSION_GET_SERVER_AUTH_CODE},
    {"set_callback", Lua_SetCallback},
    {0, 0}
};

static void LuaInit(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    luaL_register(L, EXTENSION_NAME_STRING, lua_functions);

#define SETCONSTANT(name) \
    lua_pushnumber(L, (lua_Number) name); \
    lua_setfield(L, -2, #name); \

    SETCONSTANT(MSG_SIGN_IN)
    SETCONSTANT(MSG_SIGN_OUT)

    SETCONSTANT(STATUS_SUCCESS)
    SETCONSTANT(STATUS_FAILED)
#undef SETCONSTANT

        lua_pop(L, 1);
}

dmExtension::Result APP_INITIALIZE(dmExtension::AppParams* params) {
    return dmExtension::RESULT_OK;
}

dmExtension::Result APP_FINALIZE(dmExtension::AppParams* params) {
    return dmExtension::RESULT_OK;
}

dmExtension::Result INITIALIZE(dmExtension::Params* params) {
    LuaInit(params->m_L);
    const char* client_id = dmConfigFile::GetString(params->m_ConfigFile, "gsi.client_id", 0);
    gsi_callback_initialize();
    EXTENSION_INITIALIZE(params->m_L, client_id);
    return dmExtension::RESULT_OK;
}

dmExtension::Result UPDATE(dmExtension::Params* params) {
    gsi_callback_update();
    EXTENSION_UPDATE(params->m_L);
    return dmExtension::RESULT_OK;
}

void EXTENSION_ON_EVENT(dmExtension::Params* params, const dmExtension::Event* event) {
    switch (event->m_Event) {
    case dmExtension::EVENT_ID_ACTIVATEAPP:
        EXTENSION_APP_ACTIVATE(params->m_L);
        break;
    case dmExtension::EVENT_ID_DEACTIVATEAPP:
        EXTENSION_APP_DEACTIVATE(params->m_L);
        break;
    }
}

dmExtension::Result FINALIZE(dmExtension::Params* params) {
    gsi_callback_finalize();
    EXTENSION_FINALIZE(params->m_L);
    return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(EXTENSION_NAME, EXTENSION_NAME_STRING, APP_INITIALIZE, APP_FINALIZE, INITIALIZE, UPDATE, EXTENSION_ON_EVENT, FINALIZE)
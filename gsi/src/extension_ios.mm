#include <dmsdk/sdk.h>

#if defined(DM_PLATFORM_IOS)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>

#include "extension.h"
#include "gsi_callback.h"

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

static lua_State* g_LuaState = 0;
static dmScript::LuaCallbackInfo* g_Callback = 0;

static NSString* g_ClientId = nil;
static NSString* g_ServerAuthCode = nil;


// -----------------------------------------------------------------------------
// Utility
// -----------------------------------------------------------------------------

static void SendSimpleMessage(int msg, id obj) {
    NSError* error;
    NSData* jsonData =
        [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];

    if (jsonData) {
        NSString* str =
            [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        gsi_add_to_queue(msg, [str UTF8String]);
        [str release];
    } else {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [dict setObject:error.localizedDescription ?: @"JSON error"
                 forKey:@"error"];

        NSData* errorData =
            [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];

        if (errorData) {
            NSString* str =
                [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
            gsi_add_to_queue(msg, [str UTF8String]);
            [str release];
        } else {
            gsi_add_to_queue(
                msg,
                "{ \"error\": \"Error while converting message to JSON\" }");
        }
    }
}

// -----------------------------------------------------------------------------
// Lua API
// -----------------------------------------------------------------------------

int EXTENSION_SET_CALLBACK(lua_State* L) {
    DM_LUA_STACK_CHECK(L, 0);

    if (g_Callback) {
        dmScript::DestroyCallback(g_Callback);
        g_Callback = 0;
    }

    g_Callback = dmScript::CreateCallback(L, 1);

    return 0;
}

int EXTENSION_LOGIN(lua_State* L) {
    if (!g_ClientId) {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [dict setObject:@(STATUS_FAILED) forKey:@"status"];
        [dict setObject:@"Client ID not set" forKey:@"error"];
        SendSimpleMessage(MSG_SIGN_IN, dict);
        return 0;
    }

    UIViewController* rootVC =
        UIApplication.sharedApplication.keyWindow.rootViewController;

    GIDConfiguration* config =
        [[GIDConfiguration alloc] initWithClientID:g_ClientId];

    [GIDSignIn.sharedInstance
        signInWithConfiguration:config
        presentingViewController:rootVC
        callback:^(GIDGoogleUser* user, NSError* error) {

        if (error) {
            NSMutableDictionary* dict = [NSMutableDictionary dictionary];
            [dict setObject:@(STATUS_FAILED) forKey:@"status"];
            [dict setObject:error.localizedDescription ?: @"Unknown error"
                     forKey:@"error"];
            SendSimpleMessage(MSG_SIGN_IN, dict);
            return;
        }

        if (g_ServerAuthCode) {
            [g_ServerAuthCode release];
            g_ServerAuthCode = nil;
        }

        g_ServerAuthCode = [user.idToken.tokenString copy];

        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [dict setObject:@(STATUS_SUCCESS) forKey:@"status"];
        [dict setObject:g_ServerAuthCode ?: @""
                 forKey:@"auth_token"];

        SendSimpleMessage(MSG_SIGN_IN, dict);
    }];

    [config release];
    return 0;
}

int EXTENSION_LOGOUT(lua_State* L) {
    [GIDSignIn.sharedInstance signOut];

    if (g_ServerAuthCode) {
        [g_ServerAuthCode release];
        g_ServerAuthCode = nil;
    }

    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:@(STATUS_SUCCESS) forKey:@"status"];
    SendSimpleMessage(MSG_SIGN_OUT, dict);

    return 0;
}

int EXTENSION_GET_SERVER_AUTH_CODE(lua_State* L) {
    if (g_ServerAuthCode) {
        lua_pushstring(L, [g_ServerAuthCode UTF8String]);
    } else {
        lua_pushnil(L);
    }
    return 1;
}

// -----------------------------------------------------------------------------
// Extension lifecycle
// -----------------------------------------------------------------------------

void EXTENSION_INITIALIZE(lua_State* L, const char* client_id) {
    g_LuaState = L;

    if (g_ClientId) {
        [g_ClientId release];
    }
    g_ClientId = [[NSString alloc] initWithUTF8String:client_id];
}

void EXTENSION_UPDATE(lua_State* L) {
    gsi_callback_update();
}
void EXTENSION_APP_ACTIVATE(lua_State* L) {}
void EXTENSION_APP_DEACTIVATE(lua_State* L) {}

void EXTENSION_FINALIZE(lua_State* L) {
    if (g_Callback) {
        dmScript::DestroyCallback(g_Callback);
        g_Callback = 0;
    }

    if (g_ClientId) {
        [g_ClientId release];
        g_ClientId = nil;
    }

    if (g_ServerAuthCode) {
        [g_ServerAuthCode release];
        g_ServerAuthCode = nil;
    }
}

#endif // DM_PLATFORM_IOS

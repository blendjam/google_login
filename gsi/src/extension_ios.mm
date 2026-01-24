#if defined(DM_PLATFORM_IOS) 

#include <GoogleSignIn/GoogleSignIn.h>
#include <UiKit/UiKit.h>
#include "extension.h"
#include "gsi_callback.h"

static NSString* g_serverAuthCode = nil;

void SendSimpleMessage(MESSAGE_ID msg, id obj) {
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:obj options:(NSJSONWritingOptions)0 error:&error];

    if (jsonData)
    {
        NSString* nsstring = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        gsi_add_to_queue(msg, (const char*)[nsstring UTF8String]);
        [nsstring release];
    }
    else
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:error.localizedDescription forKey:@"error"];
        NSError* error2;
        NSData* errorJsonData = [NSJSONSerialization dataWithJSONObject:dict options:(NSJSONWritingOptions)0 error:&error2];
        if (errorJsonData)
        {
            NSString* nsstringError = [[NSString alloc] initWithData:errorJsonData encoding:NSUTF8StringEncoding];
            gsi_add_to_queue(MSG_ERROR, (const char*)[nsstringError UTF8String]);
            [nsstringError release];
        }
        else
        {
            gsi_add_to_queue(MSG_ERROR, [[NSString stringWithFormat:@"{ \"error\": \"Error while converting simple message to JSON.\"}"] UTF8String]);
        }
    }
}

void SendSimpleMessage(MESSAGE_ID msg, NSString *key, id value) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:value forKey:key];
    SendSimpleMessage(msg, dict);
}

void SendSimpleMessage(MESSAGE_ID msg, NSString *key1, id value1, NSString *key2, id value2) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:value1 forKey:key1]; 
    [dict setObject:value2 forKey:key2];
    SendSimpleMessage(msg, dict);
}
#pragma mark - Lua Functions -
int EXTENSION_LOGIN(lua_State* L) {
    dmLogInfo("GSI: Login Started");
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [GIDSignIn.sharedInstance signInWithPresentingViewController:rootVC
        completion:^(GIDSignInResult *_Nullable result, NSError *_Nullable error ){
            if (error){
                dmLogInfo("GSI: Unable to sign in");
                SendSimpleMessage(MSG_SIGN_IN, @"status", @(STATUS_FAILED));
                return;
            }
            [result.user refreshTokensIfNeededWithCompletion: ^(GIDGoogleUser * _Nullable user, NSError* _Nullable tokenError){
                if (tokenError || user == nil){
                    dmLogInfo("GSI: Unable to fetch user token");
                    return;
                }
                g_serverAuthCode  = [user.idToken tokenString];
                SendSimpleMessage(MSG_SIGN_IN, @"status", @(STATUS_SUCCESS), @"auth_token", g_serverAuthCode);
            }];
        }];
    return 0;
}

int EXTENSION_GET_SERVER_AUTH_CODE(lua_State* L) {
    dmLogInfo("GSI: get server auth code");
    
    if (g_serverAuthCode == nil) {
        dmLogInfo("GSI: No ID token stored - user might not be logged in");
        lua_pushnil(L);
        return 1; 
    }
    
    lua_pushstring(L, [g_serverAuthCode UTF8String]);
    dmLogInfo("GSI: Returning stored ID token to Lua");
    
    return 1; 
}

int EXTENSION_LOGOUT(lua_State* L) {
    [GIDSignIn.sharedInstance signOut];
    SendSimpleMessage(MSG_SIGN_OUT, @"status", @(STATUS_SUCCESS));
    dmLogInfo("GSI: logout");
    return 0;
}

#pragma mark - Defold lifecycle -
void EXTENSION_INITIALIZE(lua_State* L, const char* ios_client_id) {
    if (ios_client_id){
        NSString *clientId = [NSString stringWithUTF8String:ios_client_id];
        GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientId];
        GIDSignIn.sharedInstance.configuration = config;
    }
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
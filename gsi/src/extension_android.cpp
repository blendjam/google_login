#if defined(DM_PLATFORM_ANDROID)
#include <dmsdk/dlib/android.h>
#include <string.h>
#include <dmsdk/dlib/android.h>
#include "extension.h"
#include "gsi_callback.h"
#include "com_defold_gsi_GsiJNI.h"

struct GsiJNI
{
    jobject                 m_GsiJNI;

    // Java methods
    jmethodID               m_init;
    jmethodID               m_login;
    jmethodID               m_logout;
    jmethodID               m_getServerAuthCode;
};

static GsiJNI g_gsi;

JNIEXPORT void JNICALL Java_com_defold_gsi_GsiJNI_gsiAddToQueue(JNIEnv* env, jclass cls, jint jmsg, jstring jjson)
{
    const char* json = env->GetStringUTFChars(jjson, 0);
    gsi_add_to_queue((MESSAGE_ID)jmsg, json);
    env->ReleaseStringUTFChars(jjson, json);
}

// void method(char*)
static void CallVoidMethodChar(jobject instance, jmethodID method, const char* cstr)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();
    jstring jstr = env->NewStringUTF(cstr);
    env->CallVoidMethod(instance, method, jstr);
    env->DeleteLocalRef(jstr);
}

// void method()
static int CallVoidMethod(jobject instance, jmethodID method)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();
    env->CallVoidMethod(instance, method);
    return 0;
}

// string method()
static int CallStringMethod(lua_State* L, jobject instance, jmethodID method)
{
    DM_LUA_STACK_CHECK(L, 1);
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();
    jstring return_value = (jstring)env->CallObjectMethod(instance, method);
    if (return_value)
    {
        const char* cstr = env->GetStringUTFChars(return_value, 0);
        lua_pushstring(L, cstr);
        env->ReleaseStringUTFChars(return_value, cstr);
        env->DeleteLocalRef(return_value);
    }
    else
    {
        lua_pushnil(L);
    }
    return 1;
}

// boolean method()
static int CallBooleanMethod(lua_State* L, jobject instance, jmethodID method)
{
    DM_LUA_STACK_CHECK(L, 1);
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();
    jboolean return_value = (jboolean)env->CallBooleanMethod(instance, method);
    lua_pushboolean(L, JNI_TRUE == return_value);
    return 1;
}

// GSI Methods
static void InitJNIMethods(JNIEnv* env, jclass cls)
{
    g_gsi.m_login = env->GetMethodID(cls, "login", "()V");
    g_gsi.m_logout = env->GetMethodID(cls, "logout", "()V");
    g_gsi.m_getServerAuthCode = env->GetMethodID(cls, "getServerAuthCode", "()Ljava/lang/String;");
}

int EXTENSION_LOGIN(lua_State* L) {
    CallVoidMethod(g_gsi.m_GsiJNI, g_gsi.m_login);
    return 0;
}

int EXTENSION_LOGOUT(lua_State* L) {
    CallVoidMethod(g_gsi.m_GsiJNI, g_gsi.m_logout);
    return 0;
}

int EXTENSION_GET_SERVER_AUTH_CODE(lua_State* L) {
    return CallStringMethod(L, g_gsi.m_GsiJNI, g_gsi.m_getServerAuthCode);
}


// EXTENSION Life Cycle Methods
void EXTENSION_INITIALIZE(lua_State* L, const char* client_id) {
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();
    jclass cls = dmAndroid::LoadClass(env, "com.defold.gsi.GsiJNI");

    InitJNIMethods(env, cls);

    jmethodID jni_constructor = env->GetMethodID(cls, "<init>", "(Landroid/app/Activity;Ljava/lang/String;)V");
    jstring java_client_id = env->NewStringUTF(client_id);
    g_gsi.m_GsiJNI = env->NewGlobalRef(env->NewObject(cls, jni_constructor, threadAttacher.GetActivity()->clazz, java_client_id));
    env->DeleteLocalRef(java_client_id);
}

void EXTENSION_UPDATE(lua_State* L) {}

void EXTENSION_APP_ACTIVATE(lua_State* L) {}

void EXTENSION_APP_DEACTIVATE(lua_State* L) {}

void EXTENSION_FINALIZE(lua_State* L) {}


#endif
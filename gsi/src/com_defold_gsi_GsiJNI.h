#include <jni.h>
/* Header for class com_defold_gsi_GsiJNI */

#ifndef COM_DEFOLD_GSI_GSIJNI_H
#define COM_DEFOLD_GSI_GSIJNI_H
#ifdef __cplusplus
extern "C" {
#endif
    /*
    * Class:     com_defold_gsi_GsiJNI
    * Method:    gsiAddToQueue_first_arg
    * Signature: (ILjava/lang/String;I)V
    */
    JNIEXPORT void JNICALL Java_com_defold_gsi_GsiJNI_gsiAddToQueue
    (JNIEnv*, jclass, jint, jstring);

#ifdef __cplusplus
}
#endif
#endif
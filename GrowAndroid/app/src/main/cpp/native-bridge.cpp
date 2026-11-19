#include <jni.h>
#include <string>
#include "GrowCoreEngine.hpp"

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_nkembi_grow_GrowNativeBridge_validateMacros(
    JNIEnv* env,
    jobject /* this */,
    jdouble calories,
    jdouble protein,
    jdouble carbs,
    jdouble fat,
    jdouble fiber,
    jdoubleArray calculatedOut
) {
    double calculated = 0.0;
    bool isValid = grow_core_validate_macros(calories, protein, carbs, fat, fiber, &calculated);

    if (calculatedOut != nullptr) {
        jdouble calcVal = calculated;
        env->SetDoubleArrayRegion(calculatedOut, 0, 1, &calcVal);
    }

    return isValid ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_com_nkembi_grow_GrowNativeBridge_validateExpense(
    JNIEnv* env,
    jobject /* this */,
    jdouble amount,
    jdouble balance,
    jdouble fixedCosts,
    jintArray failedGateOut
) {
    int failedGate = 0;
    bool approved = grow_core_validate_expense(amount, balance, fixedCosts, &failedGate);

    if (failedGateOut != nullptr) {
        jint gateVal = failedGate;
        env->SetIntArrayRegion(failedGateOut, 0, 1, &gateVal);
    }

    return approved ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jdouble JNICALL
Java_com_nkembi_grow_GrowNativeBridge_reconcileWater(
    JNIEnv* env,
    jobject /* this */,
    jdouble localMl,
    jdouble incomingMl
) {
    return grow_core_reconcile_water(localMl, incomingMl);
}

JNIEXPORT jboolean JNICALL
Java_com_nkembi_grow_GrowNativeBridge_isDoseTerminal(
    JNIEnv* env,
    jobject /* this */,
    jboolean currentlyTaken,
    jboolean incomingTaken
) {
    bool current = (currentlyTaken == JNI_TRUE);
    bool incoming = (incomingTaken == JNI_TRUE);
    return grow_core_is_dose_terminal(current, incoming) ? JNI_TRUE : JNI_FALSE;
}

}

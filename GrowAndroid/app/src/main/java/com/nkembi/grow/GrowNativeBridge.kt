package com.nkembi.grow

/**
 * GrowNativeBridge (JNI Binding to Shared C++20 CoreEngine)
 * Zero-copy logic execution identical across iOS (Swift) and Android (Kotlin).
 */
object GrowNativeBridge {
    init {
        try {
            System.loadLibrary("growcore_jni")
        } catch (e: UnsatisfiedLinkError) {
            System.err.println("Native library growcore_jni not found: ${e.message}")
        }
    }

    external fun validateMacros(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double,
        calculatedOut: DoubleArray? = null
    ): Boolean

    external fun validateExpense(
        amount: Double,
        balance: Double,
        fixedCosts: Double,
        failedGateOut: IntArray? = null
    ): Boolean

    external fun reconcileWater(localMl: Double, incomingMl: Double): Double

    external fun isDoseTerminal(currentlyTaken: Boolean, incomingTaken: Boolean): Boolean
}

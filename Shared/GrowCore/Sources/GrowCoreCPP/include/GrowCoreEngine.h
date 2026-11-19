#ifndef GROW_CORE_ENGINE_H
#define GROW_CORE_ENGINE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// C ABI Exports (Directly callable from Swift, C++, and JNI)
bool grow_core_validate_macros(double calories, double protein, double carbs, double fat, double fiber, double* calculated);
bool grow_core_validate_expense(double amount, double balance, double fixedCosts, int* failedGate);
double grow_core_reconcile_water(double localMl, double incomingMl);
bool grow_core_is_dose_terminal(bool currentlyTaken, bool incomingTaken);

#ifdef __cplusplus
}
#endif

#endif // GROW_CORE_ENGINE_H

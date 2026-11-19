#ifndef GROW_CORE_ENGINE_H
#define GROW_CORE_ENGINE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Clinical Contraindication Status Codes (Poka-Yoke Gates)
#define GROW_STATUS_CLEARED 0
#define GROW_BLOCKED_HYPERTENSIVE_INTERACTION 1
#define GROW_BLOCKED_SEROTONIN_SYNDROME 2
#define GROW_BLOCKED_BLEEDING_RISK 3
#define GROW_BLOCKED_RENAL_BURDEN 4

// C ABI Exports (Directly callable from Swift, C++, and JNI)
bool grow_core_validate_macros(double calories, double protein, double carbs, double fat, double fiber, double* calculated);
bool grow_core_validate_expense(double amount, double balance, double fixedCosts, int* failedGate);
double grow_core_reconcile_water(double localMl, double incomingMl);
bool grow_core_is_dose_terminal(bool currentlyTaken, bool incomingTaken);

// Physiological & Clinical Assessment (Mifflin-St Jeor / Sarcopenia / Renal bounds)
double grow_core_calculate_bmr(int sex, int age, double weightKg, double heightCm); // sex: 0=Male, 1=Female
double grow_core_calculate_tdee(int sex, int age, double weightKg, double heightCm, double activityMultiplier);
double grow_core_calculate_target_protein(int age, double weightKg, bool hasSarcopeniaOrOsteopenia);
double grow_core_calculate_target_hydration(double weightKg, int workoutMinutes);

// Poka-Yoke Safety Filters
int grow_core_screen_contraindication(const char* medication, const char* candidateSubstance);
bool grow_core_is_exercise_safe(const char* limitation, const char* candidateExercise);

#ifdef __cplusplus
}
#endif

#endif // GROW_CORE_ENGINE_H

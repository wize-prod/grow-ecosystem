#ifndef GROW_CORE_ENGINE_HPP
#define GROW_CORE_ENGINE_HPP

#include <string>
#include <vector>
#include <cstdint>

namespace Grow {

struct MacroValidationResult {
    bool isValid;
    double calculatedCalories;
    double discrepancyPercent;
};

struct TransactionValidationResult {
    bool isApproved;
    int gateFailed;
    char reason[128];
};

class CoreEngine {
public:
    static MacroValidationResult validateMacros(double calories, double protein, double carbs, double fat, double fiber);
    static TransactionValidationResult validateExpense(double amount, double currentBalance, double fixedCostsRemaining);
    static double reconcileMonotonicWater(double localMl, double incomingMl);
    static bool canTransitionDose(bool currentlyTaken, bool incomingTaken);
};

} // namespace Grow

#ifdef __cplusplus
extern "C" {
#endif

// C ABI Exports (Accessible via Swift C++ interop and Android JNI)
bool grow_core_validate_macros(double calories, double protein, double carbs, double fat, double fiber, double* calculated);
bool grow_core_validate_expense(double amount, double balance, double fixedCosts, int* failedGate);
double grow_core_reconcile_water(double localMl, double incomingMl);
bool grow_core_is_dose_terminal(bool currentlyTaken, bool incomingTaken);

#ifdef __cplusplus
}
#endif

#endif // GROW_CORE_ENGINE_HPP

#include "GrowCoreEngine.hpp"
#include <cmath>
#include <cstring>
#include <algorithm>

namespace Grow {

MacroValidationResult CoreEngine::validateMacros(double calories, double protein, double carbs, double fat, double fiber) {
    // Atwater General Factor System: 4 kcal/g Protein, 4 kcal/g Carbs, 9 kcal/g Fat, 2 kcal/g Fiber
    double calculated = (protein * 4.0) + (carbs * 4.0) + (fat * 9.0) + (fiber * 2.0);
    double base = std::max(calories, 1.0);
    double discrepancy = std::abs(calories - calculated) / base;

    MacroValidationResult result;
    result.calculatedCalories = calculated;
    result.discrepancyPercent = discrepancy * 100.0;
    // Poka-Yoke: Allow max 25% discrepancy due to rounding on commercial labels
    result.isValid = (discrepancy <= 0.25);
    return result;
}

TransactionValidationResult CoreEngine::validateExpense(double amount, double currentBalance, double fixedCostsRemaining) {
    TransactionValidationResult res;
    std::memset(res.reason, 0, sizeof(res.reason));

    if (amount <= 0.0) {
        res.isApproved = false;
        res.gateFailed = 1;
        std::strncpy(res.reason, "Betrag muss groesser als 0 sein", sizeof(res.reason) - 1);
        return res;
    }

    double netAvailable = currentBalance - fixedCostsRemaining;
    if (netAvailable - amount < 100.0) {
        res.isApproved = false;
        res.gateFailed = 2;
        std::strncpy(res.reason, "Gate 2 verletzt: 100 EUR Mindestpuffer unterschritten", sizeof(res.reason) - 1);
        return res;
    }

    res.isApproved = true;
    res.gateFailed = 0;
    std::strncpy(res.reason, "Freigegeben", sizeof(res.reason) - 1);
    return res;
}

double CoreEngine::reconcileMonotonicWater(double localMl, double incomingMl) {
    return std::max(localMl, incomingMl);
}

bool CoreEngine::canTransitionDose(bool currentlyTaken, bool incomingTaken) {
    // Poka-Yoke: A dose marked taken cannot be reset to untaken via out-of-order sync
    if (currentlyTaken && !incomingTaken) {
        return false;
    }
    return true;
}

} // namespace Grow

// C ABI Bindings
extern "C" {

bool grow_core_validate_macros(double calories, double protein, double carbs, double fat, double fiber, double* calculated) {
    auto res = Grow::CoreEngine::validateMacros(calories, protein, carbs, fat, fiber);
    if (calculated) {
        *calculated = res.calculatedCalories;
    }
    return res.isValid;
}

bool grow_core_validate_expense(double amount, double balance, double fixedCosts, int* failedGate) {
    auto res = Grow::CoreEngine::validateExpense(amount, balance, fixedCosts);
    if (failedGate) {
        *failedGate = res.gateFailed;
    }
    return res.isApproved;
}

double grow_core_reconcile_water(double localMl, double incomingMl) {
    return Grow::CoreEngine::reconcileMonotonicWater(localMl, incomingMl);
}

bool grow_core_is_dose_terminal(bool currentlyTaken, bool incomingTaken) {
    return Grow::CoreEngine::canTransitionDose(currentlyTaken, incomingTaken);
}

}

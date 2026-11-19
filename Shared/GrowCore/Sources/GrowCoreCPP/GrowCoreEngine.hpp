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

    // Physiological Calculations
    static double calculateBMR(int sex, int age, double weightKg, double heightCm);
    static double calculateTDEE(int sex, int age, double weightKg, double heightCm, double activityMultiplier);
    static double calculateProteinTarget(int age, double weightKg, bool hasSarcopeniaOrOsteopenia);
    static double calculateHydrationTarget(double weightKg, int workoutMinutes);

    // Poka-Yoke Safety Filters
    static int screenContraindication(const std::string& medication, const std::string& substance);
    static bool isExerciseSafe(const std::string& limitation, const std::string& exercise);
};

} // namespace Grow

#ifdef __cplusplus
extern "C" {
#endif

// Include the C declarations
#include "include/GrowCoreEngine.h"

#ifdef __cplusplus
}
#endif

#endif // GROW_CORE_ENGINE_HPP

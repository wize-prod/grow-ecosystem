#include "GrowCoreEngine.hpp"
#include <cmath>
#include <cstring>
#include <algorithm>
#include <string>

namespace {

std::string toUpper(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return std::toupper(c); });
    return s;
}

bool containsSubstring(const std::string& haystack, const std::string& needle) {
    return haystack.find(needle) != std::string::npos;
}

} // anonymous namespace

namespace Grow {

MacroValidationResult CoreEngine::validateMacros(double calories, double protein, double carbs, double fat, double fiber) {
    // Atwater General Factor System: 4 kcal/g Protein, 4 kcal/g Carbs, 9 kcal/g Fat, 2 kcal/g Fiber
    double calculated = (protein * 4.0) + (carbs * 4.0) + (fat * 9.0) + (fiber * 2.0);
    double base = std::max(calories, 1.0);
    double discrepancy = std::abs(calories - calculated) / base;

    MacroValidationResult result;
    result.calculatedCalories = calculated;
    result.discrepancyPercent = discrepancy * 100.0;
    // Poka-Yoke: Allow max 25% discrepancy due to rounding on commercial food labels
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

double CoreEngine::calculateBMR(int sex, int age, double weightKg, double heightCm) {
    // Mifflin-St Jeor Formula
    // Male: 10 * weight(kg) + 6.25 * height(cm) - 5 * age(y) + 5
    // Female: 10 * weight(kg) + 6.25 * height(cm) - 5 * age(y) - 161
    double base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * static_cast<double>(age));
    if (sex == 0) { // Male
        return base + 5.0;
    } else { // Female
        return base - 161.0;
    }
}

double CoreEngine::calculateTDEE(int sex, int age, double weightKg, double heightCm, double activityMultiplier) {
    double bmr = calculateBMR(sex, age, weightKg, heightCm);
    double multiplier = std::min(std::max(activityMultiplier, 1.0), 2.5);
    return std::round(bmr * multiplier);
}

double CoreEngine::calculateProteinTarget(int age, double weightKg, bool hasSarcopeniaOrOsteopenia) {
    // Sarcopenia / Osteopenia / Senior protocol:
    // 1.3 - 1.4 g/kg is clinically optimal for preserving bone & muscle mass without exceeding GFR thresholds
    if (age >= 55 || hasSarcopeniaOrOsteopenia) {
        return std::round(weightKg * 1.35);
    }
    // High-performance athletic standard: ~2.0 g/kg
    return std::round(weightKg * 2.0);
}

double CoreEngine::calculateHydrationTarget(double weightKg, int workoutMinutes) {
    // Baseline: 32 ml / kg bodyweight + 10 ml per training minute
    double baselineMl = weightKg * 32.0;
    double workoutMl = static_cast<double>(std::max(0, workoutMinutes)) * 10.0;
    return std::round(baselineMl + workoutMl);
}

int CoreEngine::screenContraindication(const std::string& medication, const std::string& substance) {
    std::string med = toUpper(medication);
    std::string sub = toUpper(substance);

    // 1. Blood Pressure / Cardiovascular Interactions
    bool isHypertensiveMed = containsSubstring(med, "AMLODIPINE") ||
                             containsSubstring(med, "RAMIPRIL") ||
                             containsSubstring(med, "LISINOPRIL") ||
                             containsSubstring(med, "ACE_INHIBITOR") ||
                             containsSubstring(med, "METOPROLOL") ||
                             containsSubstring(med, "BISOPROLOL") ||
                             containsSubstring(med, "BETA_BLOCKER") ||
                             containsSubstring(med, "HYPERTENSION");

    if (isHypertensiveMed) {
        if (containsSubstring(sub, "RHODIOLA")) {
            return GROW_BLOCKED_HYPERTENSIVE_INTERACTION; // Sympathomimetic trigger / arrhythmia risk
        }
        if (containsSubstring(sub, "NITRAT") || containsSubstring(sub, "ROTE_BETE") || containsSubstring(sub, "BEETROOT")) {
            return GROW_BLOCKED_HYPERTENSIVE_INTERACTION; // Synergistic vasodilation / severe hypotension risk
        }
    }

    // 2. Serotonin Syndrome Risks
    bool isPsychotropicMed = containsSubstring(med, "SSRI") ||
                             containsSubstring(med, "SERTRALINE") ||
                             containsSubstring(med, "ESCITALOPRAM") ||
                             containsSubstring(med, "FLUOXETINE") ||
                             containsSubstring(med, "CITALOPRAM") ||
                             containsSubstring(med, "MAO");

    if (isPsychotropicMed) {
        if (containsSubstring(sub, "ST_JOHNS_WORT") ||
            containsSubstring(sub, "JOHANNISKRAUT") ||
            containsSubstring(sub, "5_HTP") ||
            containsSubstring(sub, "5HTP") ||
            containsSubstring(sub, "TRYPTOPHAN") ||
            containsSubstring(sub, "RHODIOLA")) {
            return GROW_BLOCKED_SEROTONIN_SYNDROME;
        }
    }

    // 3. Anticoagulant / Bleeding Risks
    bool isAnticoagulant = containsSubstring(med, "WARFARIN") ||
                           containsSubstring(med, "MARCUMAR") ||
                           containsSubstring(med, "ELIQUIS") ||
                           containsSubstring(med, "XARELTO") ||
                           containsSubstring(med, "ASPIRIN") ||
                           containsSubstring(med, "ANTICOAGULANT");

    if (isAnticoagulant) {
        if (containsSubstring(sub, "GINKGO") ||
            containsSubstring(sub, "HIGH_DOSE_VITAMIN_E") ||
            containsSubstring(sub, "HIGH_DOSE_OMEGA3")) {
            return GROW_BLOCKED_BLEEDING_RISK;
        }
    }

    // 4. Renal Clearance Limits
    bool isRenalImpairment = containsSubstring(med, "RENAL") ||
                             containsSubstring(med, "CKD") ||
                             containsSubstring(med, "DIALYSIS");

    if (isRenalImpairment) {
        if (containsSubstring(sub, "CREATINE") || containsSubstring(sub, "KREATIN")) {
            return GROW_BLOCKED_RENAL_BURDEN;
        }
    }

    return GROW_STATUS_CLEARED;
}

bool CoreEngine::isExerciseSafe(const std::string& limitation, const std::string& exercise) {
    std::string lim = toUpper(limitation);
    std::string ex = toUpper(exercise);

    // Spinal Axial Loading Filter
    if (containsSubstring(lim, "NO_AXIAL_SPINAL_LOADING") ||
        containsSubstring(lim, "SPINE_AXIAL") ||
        containsSubstring(lim, "BANDSCHEIBE") ||
        containsSubstring(lim, "LUMBAL")) {
        if (containsSubstring(ex, "BARBELL_SQUAT") ||
            containsSubstring(ex, "KNIEBEUGE_LANGHANTEL") ||
            containsSubstring(ex, "CONVENTIONAL_DEADLIFT") ||
            containsSubstring(ex, "KREUZHEBEN") ||
            containsSubstring(ex, "OVERHEAD_PRESS") ||
            containsSubstring(ex, "SCHULTERDRUECKEN_LANGHANTEL") ||
            containsSubstring(ex, "GOOD_MORNING")) {
            return false;
        }
    }

    // Osteopenia / High Impact Plyometric Filter
    if (containsSubstring(lim, "OSTEOPENIA") ||
        containsSubstring(lim, "OSTEOPOROSIS") ||
        containsSubstring(lim, "NO_HIGH_IMPACT_JUMPS")) {
        if (containsSubstring(ex, "BOX_JUMP") ||
            containsSubstring(ex, "BURPEE") ||
            containsSubstring(ex, "PLYOMETRIC") ||
            containsSubstring(ex, "JUMP_SQUAT") ||
            containsSubstring(ex, "DEPTH_JUMP")) {
            return false;
        }
    }

    // Acute Knee Flexion / Meniscus Filter
    if (containsSubstring(lim, "AVOID_KNEE_FLEXION_90") ||
        containsSubstring(lim, "MENISCUS") ||
        containsSubstring(lim, "PATELLA")) {
        if (containsSubstring(ex, "DEEP_SQUAT") ||
            containsSubstring(ex, "PISTOL_SQUAT") ||
            containsSubstring(ex, "WALKING_LUNGE") ||
            containsSubstring(ex, "SISSY_SQUAT")) {
            return false;
        }
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

double grow_core_calculate_bmr(int sex, int age, double weightKg, double heightCm) {
    return Grow::CoreEngine::calculateBMR(sex, age, weightKg, heightCm);
}

double grow_core_calculate_tdee(int sex, int age, double weightKg, double heightCm, double activityMultiplier) {
    return Grow::CoreEngine::calculateTDEE(sex, age, weightKg, heightCm, activityMultiplier);
}

double grow_core_calculate_target_protein(int age, double weightKg, bool hasSarcopeniaOrOsteopenia) {
    return Grow::CoreEngine::calculateProteinTarget(age, weightKg, hasSarcopeniaOrOsteopenia);
}

double grow_core_calculate_target_hydration(double weightKg, int workoutMinutes) {
    return Grow::CoreEngine::calculateHydrationTarget(weightKg, workoutMinutes);
}

int grow_core_screen_contraindication(const char* medication, const char* candidateSubstance) {
    if (!medication || !candidateSubstance) return GROW_STATUS_CLEARED;
    return Grow::CoreEngine::screenContraindication(std::string(medication), std::string(candidateSubstance));
}

bool grow_core_is_exercise_safe(const char* limitation, const char* candidateExercise) {
    if (!limitation || !candidateExercise) return true;
    return Grow::CoreEngine::isExerciseSafe(std::string(limitation), std::string(candidateExercise));
}

}

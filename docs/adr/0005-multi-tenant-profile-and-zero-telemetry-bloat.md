# ADR 0005: Multi-Tenant Consumer Profile Architecture and Zero-Telemetry Bloat

## Status
Accepted (2026-11-19)

## Context
Initial implementations of the Profile and Settings screen in GymApp suffered from "telemetry bloat" and "status theater":
1. 4 dummy cards displaying pseudo-metrics across all 4 pillars.
2. Duplicate macro summary widgets that duplicated the Heute dashboard.
3. Inauthentic zero metrics for Apple Health sync (0 bpm, 0 steps, 0 active calories).
4. Lack of real consumer multi-tenant account creation (family members could not onboard with their own physiological constraints and macro goals).
5. A prominent red "Reset All" box that took up excessive vertical space and invited accidental data loss.

## Decision
1. **Multi-Tenant Account Switcher & Onboarding:**
   - Every user (owner, family members, testers) has their own distinct identity with dedicated physiological targets:
     - Specific physical goals and conditions (e.g., joint mobility, hypertrophic overload, cardiovascular rehab).
     - Individual daily caloric and macronutrient budgets (kcal, protein, hydration).
     - Sandboxed SQLite WAL and MMKV storage partitions to prevent cross-contamination.
   - 1-tap switching between profiles directly in the settings view.
   - Formal onboarding sheet (`AddProfileSheet`) allowing anyone to create an isolated profile.
2. **Elimination of Status Theater:**
   - Completely remove the 4-pillar telemetry cards, duplicate nutrition widgets, and dummy Health counters.
   - Adopt clean standard iOS Settings rows and switches (Apple Settings / Strava standard).
3. **Discreet Data Hygiene:**
   - Replace the large destructive red banner with a discrete, confirmed text-link in the footer.
   - Include direct local backup trigger into SQLite Write-Ahead Log.

## Consequences
- **Positive:** Pristine, sober user experience adhering to the Zero-Emoji Doctrine. Immediate support for multi-user family scenarios with distinct health constraints. Zero unnecessary I/O or CPU render cycles.
- **Negative:** None. Previous status displays were redundant with the primary Heute and Analytics tabs.

# Grow Ecosystem: High-Performance Autonomous Life & Athletic OS

[![C++20 Standard](https://img.shields.io/badge/Language-C%2B%2B20-blue.svg)](https://en.cppreference.com/w/cpp/20)
[![Swift 5.10](https://img.shields.io/badge/iOS-Swift%205.10-orange.svg)](https://swift.org)
[![Kotlin 2.0](https://img.shields.io/badge/Android-Kotlin%202.0-purple.svg)](https://kotlinlang.org)
[![Architecture](https://img.shields.io/badge/Architecture-Poka--Yoke%20%7C%20Zero--Muda-green.svg)](docs/THE_GROW_ECOSYSTEM_GENESIS_AND_ARCHITECTURE.md)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

> A clinical, data-driven, cross-platform ecosystem engineered for extreme reliability, physiological autoregulation, academic mastery, and multi-tenant family health management. Built strictly according to the **Toyota Production System (TPS)**, **Poka-Yoke error-proofing**, and **Tencent/ByteDance high-throughput architectural patterns**.

---

## 1. Quick Navigation & Core Documentation

- **System Genesis & Architectural Manifesto:** [`docs/THE_GROW_ECOSYSTEM_GENESIS_AND_ARCHITECTURE.md`](docs/THE_GROW_ECOSYSTEM_GENESIS_AND_ARCHITECTURE.md)  
  *First-principles breakdown from physical constraints to high-performance C++20 core engine.*
- **2-Month Evolution & Engineering Changelog:** [`docs/GROW_ECOSYSTEM_2_MONTH_EVOLUTION_AND_CHANGELOG.md`](docs/GROW_ECOSYSTEM_2_MONTH_EVOLUTION_AND_CHANGELOG.md)  
  *Detailed timeline of all developments, pivots, failures, and clinical hardening from September to November 2026.*
- **Architecture Decision Records (ADRs):**
  - [ADR 0001: Portable C++20 Core Engine](docs/adr/0001-cpp20-portable-core-engine.md)
  - [ADR 0002: WeChat SyncKey & Vector Clock Delta Protocol](docs/adr/0002-wechat-synckey-delta-protocol.md)
  - [ADR 0003: Server-Sent Events (SSE) SmartTV Push Stream](docs/adr/0003-server-sent-events-smarttv-sink.md)
  - [ADR 0004: Agentic Code Execution over Naive Sequential MCP](docs/adr/0004-agentic-code-execution-over-naive-mcp.md)
  - [ADR 0005: Multi-Tenant Consumer Profile Architecture & Zero Telemetry Bloat](docs/adr/0005-multi-tenant-profile-and-zero-telemetry-bloat.md)

---

## 2. Core Architectural Principles (East-Asian Engineering Mentality)

### 2.1 Japanese School: Toyota Production System (TPS) & Poka-Yoke
- **Muda-dori (無駄取り - Complete Elimination of Waste):** No fake status theater, no duplicate nutrition widgets, no gamified badges or levels. Interfaces display purely functional, actionable controls.
- **Poka-Yoke (ポカヨケ - Mistake-Proofing by Construction):** Critical operations cannot fail due to user fatigue or distraction. If a financial transaction breaches the 100 EUR safety floor, it is blocked at the model layer (Gate 2 Veto). If a supplement has been logged, vector clocks guarantee it cannot revert on network reconnections.

### 2.2 Chinese School: Tencent / ByteDance High-Throughput Engineering
- **C++20 Single Source of Truth:** Platform-agnostic core logic (Atwater factor validation, physiological tolerances, macro bounds) is compiled from pure C++20 (`GrowCoreEngine.cpp`) and exposed via a C-ABI (`GrowCoreEngine.h`) directly to Swift and Kotlin via JNI. Zero logic duplication across platforms.
- **WeChat SyncKey Delta Protocol:** Devices never exchange full JSON database snapshots over the local network. Devices exchange monotone sequence IDs (`SyncSequenceID`) and transmit atomic operation deltas under 150 bytes.
- **POSIX mmap & SQLite WAL:** High-frequency states (rest timers, water intake) write into memory-mapped structures (MMKV), while historical ledgers append to an ACID-compliant SQLite Write-Ahead Log.

### 2.3 2026 AI Paradigm: Agentic Code Execution ("Code Mode")
- Traditional sequential tool-calling over naive Model Context Protocol (MCP) exhausts token context and triggers dozens of HTTP roundtrips.
- The Grow ecosystem uses sandboxed **Agentic Code Execution**: AI agents generate compact scripts that execute directly on local databases in milliseconds, returning only finalized, mathematically verified schemas.

---

## 3. Hardware Allocation & Device-App Pairing

```
+-----------------------------------------------------------------------------------------------+
|                                  HARDWARE & WORKLOAD TOPOLOGY                                 |
+-----------------------------------------------------------------------------------------------+
|  HARDWARE               | ROLE                         | APPS & WORKLOADS                     |
+-------------------------+------------------------------+--------------------------------------+
|  MacBook Air M4 (16 GB) | Autonomous Engine, Compiler, | Build pipelines, launchd daemons,    |
|                         | Model Sandboxing & Storage   | local SQLite WAL repositories        |
+-------------------------+------------------------------+--------------------------------------+
|  ORICO 1 TB USB-C SSD   | Primary External Storage     | Heavy toolchains, caches, offloading |
|                         | (Preserves 256 GB NVMe SSD)  | to keep internal SSD buffer > 50 GB  |
+-------------------------+------------------------------+--------------------------------------+
|  iPhone 16 Pro Max      | Point-of-Performance         | Grow (GymApp) - Workouts & Timer     |
|                         | Real-Time Sensor Terminal    | Growcery (NutriVault) - Scanner      |
+-------------------------+------------------------------+--------------------------------------+
|  iPad mini (A17 Pro)    | Focus Desk & Deep Work       | GrowStudy - Deep Learning & Certs    |
|                         |                              | GrowFinance - Budgeting & Tilgung    |
+-------------------------+------------------------------+--------------------------------------+
```

---

## 4. Multi-Tenant Architecture & Family Health Support

Every user onboarded to the device operates in an isolated data sandbox:
- **Dedicated Physiological Profiles:** Support for distinct medical conditions (e.g., orthopedic joint mobility, cardiovascular sinus bradycardia, McGill spinal rehab, hypertrophic overload).
- **Individual Nutritional Budgets:** Independent targets for energy (kcal), protein (g), and hydration (ml).
- **Zero Cross-Contamination:** Switching profiles immediately flushes active caches and switches SQLite WAL database contexts.

---

## 5. Repository Layout

```text
.
├── .agents/                    # Universal ecosystem design and deployment doctrines
├── docs/                       # Architectural documentation, ADRs, and 2-month history
│   ├── adr/                    # Architecture Decision Records (0001 - 0005)
│   ├── THE_GROW_ECOSYSTEM_GENESIS_AND_ARCHITECTURE.md
│   └── GROW_ECOSYSTEM_2_MONTH_EVOLUTION_AND_CHANGELOG.md
├── Fitness_Library/            # Athletic training manuals, running guidelines, military PDFs
├── GrowAndroid/                # Android companion client (Kotlin 2.0 / JNI Bridge)
├── GrowCare/                   # Skincare (4C/Pseudofolliculitis Barbae) & chore routines
├── GrowFinance/                # Budget reconciliation, 5-gate purchase audit, debt repayment
├── GrowStudy/                  # Deep study tracking & technical curricula
├── GymApp/                     # iOS Athletic OS (SwiftUI, HealthKit, SSE SmartTV Sink)
├── NutriVaultApp/              # iOS Nutrition OS (Receipt scanning, barcode engine, pantry)
├── Shared/GrowCore/            # C++20 Portable Core Engine (C-ABI header & implementation)
└── telemetry/                  # Normalized historical device logs, audits, and meal ledgers
```

---

## 6. Build & Verification

```bash
# Compile and test C++20 Portable Core Engine
cd Shared/GrowCore
swift test

# Build iOS Ecosystem Workspace for connected device
xcodebuild -workspace GrowSuite.xcworkspace \
           -scheme GymApp \
           -destination "generic/platform=iOS" \
           build
```

---

## 7. License & Governance

Proprietary ecosystem developed by Parris Campbell (`wize-prod`). All machine-wide changes governed by the Antigravity Executive Operating System.

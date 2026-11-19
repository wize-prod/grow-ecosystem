#!/usr/bin/env python3
"""
Grow Ecosystem: Architectural Performance & Speed Auditor
Analyzes all 5 apps for SwiftUI performance bottlenecks, redundant redraws,
and memory/compute leaks to enforce continuous speed acceleration.
"""

import os
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path("/Users/parris-campbellnkembi/Developer/GrowWorkspace")
APPS = ["NutriVaultApp", "GymApp", "GrowCare", "GrowStudy", "GrowFinance"]

class PerformanceAuditor:
    def __init__(self, workspace: Path):
        self.workspace = workspace
        self.violations = []
        self.stats = {"scanned_files": 0, "clean_files": 0, "total_violations": 0}

    def audit_file(self, file_path: Path):
        self.stats["scanned_files"] += 1
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        file_violations = []

        # Rule 1: Non-static dynamic DateFormatter / NumberFormatter allocation inside View
        if "Views" in str(file_path):
            cleaned_content = re.sub(r"static\s+(?:let|var)\s+\w+[\s\S]*?=\s*\{[\s\S]*?\}\(\)", "", content)
            dynamic_formatters = re.findall(r"(DateFormatter\(\)|NumberFormatter\(\))", cleaned_content)
            if dynamic_formatters:
                file_violations.append({
                    "severity": "CRITICAL",
                    "code": "PERF-01",
                    "message": f"Found {len(dynamic_formatters)} dynamic/inline formatter allocation(s) in View. Use static pool or GrowFormatters.",
                })

        # Rule 2: Non-lazy dynamic VStack inside ScrollView
        if re.search(r"ScrollView\s*\{[^}]*VStack\s*\{[^}]*ForEach", content, re.DOTALL):
            file_violations.append({
                "severity": "HIGH",
                "code": "PERF-02",
                "message": "Dynamic ForEach inside non-lazy VStack in ScrollView. Use LazyVStack to prevent layout stalls.",
            })

        # Rule 3: Heavy array filtering or sorting inside computed View properties
        body_filter_matches = re.findall(r"var\s+body\s*:\s*some\s+View\s*\{[^}]*\.(filter|sorted)\s*\{", content, re.DOTALL)
        if body_filter_matches:
            file_violations.append({
                "severity": "HIGH",
                "code": "PERF-03",
                "message": "Array filtering/sorting detected inside body pass. Pre-calculate or memoize in ViewModel/State.",
            })

        # Rule 4: Ephemeral UUID in ForEach
        if re.search(r"ForEach\([^)]*id:\s*\\\.id\)\s*\{[^}]*UUID\(\)", content):
            file_violations.append({
                "severity": "CRITICAL",
                "code": "PERF-04",
                "message": "Generating transient UUID() inside ForEach breaks SwiftUI identity and forces 100% full redraws.",
            })

        # Rule 5: ScrollView missing interactive keyboard dismissal
        if "ScrollView" in content and "TextField" in content and "scrollDismissesKeyboard" not in content:
            file_violations.append({
                "severity": "MEDIUM",
                "code": "PERF-05",
                "message": "ScrollView with TextField is missing .scrollDismissesKeyboard(.interactively).",
            })

        # Rule 6: Heavy unclipped Gaussian blur
        blur_matches = re.findall(r"\.blur\(radius:\s*([0-9.]+)\)", content)
        for b in blur_matches:
            if float(b) > 20:
                file_violations.append({
                    "severity": "LOW",
                    "code": "PERF-06",
                    "message": f"Excessive blur radius ({b}pt) can saturate GPU fill rate. Consider material background.",
                })

        if file_violations:
            self.violations.append((file_path, file_violations))
            self.stats["total_violations"] += len(file_violations)
        else:
            self.stats["clean_files"] += 1

    def run(self):
        print("=" * 72)
        print("GROW ECOSYSTEM: ARCHITECTURAL PERFORMANCE & SPEED AUDIT")
        print("=" * 72)

        app_results = {}
        for app in APPS:
            app_dir = self.workspace / app
            if not app_dir.exists():
                continue

            app_violations_count = 0
            app_files_count = 0

            for p in app_dir.rglob("*.swift"):
                if "/." in str(p) or "Tests" in str(p):
                    continue
                before_count = self.stats["total_violations"]
                self.audit_file(p)
                app_files_count += 1
                app_violations_count += (self.stats["total_violations"] - before_count)

            score = max(0, 100 - (app_violations_count * 4))
            app_results[app] = {
                "files": app_files_count,
                "violations": app_violations_count,
                "score": score,
            }

        print(f"\n{'APP TARGET':<20} | {'FILES':<8} | {'ISSUES':<8} | {'PERF SCORE':<12}")
        print("-" * 56)
        for app, res in app_results.items():
            print(f"{app:<20} | {res['files']:<8} | {res['violations']:<8} | {res['score']:>3}% Index")

        print("-" * 56)
        print(f"Total Scanned Files: {self.stats['scanned_files']}")
        print(f"Clean High-Velocity Files: {self.stats['clean_files']}")
        print(f"Total Optimization Candidates: {self.stats['total_violations']}")
        print("=" * 72)

        if self.violations:
            print("\nPRIORITY REFACTORING TARGETS (TOP 10):")
            for file_path, v_list in self.violations[:10]:
                rel_path = file_path.relative_to(self.workspace)
                print(f"\n* {rel_path}:")
                for v in v_list:
                    print(f"  [{v['severity']}] {v['code']}: {v['message']}")

        print("\nAudit Complete.")

if __name__ == "__main__":
    auditor = PerformanceAuditor(WORKSPACE_ROOT)
    auditor.run()

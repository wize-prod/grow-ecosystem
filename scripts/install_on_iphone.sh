#!/bin/bash
set -e

DEVICE_ID="00008140-001E292E0062201C"
echo "=== Installing Ecosystem Apps on iPhone ($DEVICE_ID) ==="

xcrun devicectl device install app --device "$DEVICE_ID" /Users/parris-campbellnkembi/Library/Developer/Xcode/DerivedData/GymApp-egrazisgomuiudgtmhvkljzaejrc/Build/Products/Debug-iphoneos/GymApp.app
echo "Grow (GymApp) installed."

xcrun devicectl device install app --device "$DEVICE_ID" /Users/parris-campbellnkembi/Library/Developer/Xcode/DerivedData/GrowStudy-apouycmvnfmyjicigjigegrljvhx/Build/Products/Debug-iphoneos/GrowStudy.app
echo "GrowTasks (GrowStudy) installed."

xcrun devicectl device install app --device "$DEVICE_ID" /Users/parris-campbellnkembi/Library/Developer/Xcode/DerivedData/GrowFinance-cquycbguzvbragcjckljvomxvcan/Build/Products/Debug-iphoneos/GrowFinance.app
echo "GrowFinance installed."

echo "All 3 apps successfully updated on iPhone."

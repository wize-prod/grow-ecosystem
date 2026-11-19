#!/bin/bash
set -euo pipefail

DEVICE_ID="00008140-001E292E0062201C"

PRODUCTS_DIR="/Users/parris-campbellnkembi/Developer/GrowWorkspace/build/DerivedData/Build/Products/Debug-iphoneos"
GYM_APP="$PRODUCTS_DIR/GymApp.app"
NUTRI_APP="$PRODUCTS_DIR/NutriVaultApp.app"
STUDY_APP="$PRODUCTS_DIR/GrowStudy.app"

echo "Checking target iPhone ($DEVICE_ID) status..."
if ! xcrun devicectl list devices | grep "$DEVICE_ID" | grep -q -w "available"; then
    echo "Device status is unavailable. Please ensure iPhone screen is unlocked."
    exit 1
fi

echo "Device is available and unlocked."

echo "Step 1: Removing GrowFinance from iPhone (to respect 3-sideloaded app limit)..."
xcrun devicectl device uninstall app --device "$DEVICE_ID" com.nkembi.growfinance 2>/dev/null || true

echo "Step 2: Installing/Updating Grow (GymApp)..."
xcrun devicectl device install app --device "$DEVICE_ID" "$GYM_APP"

echo "Step 3: Installing/Updating Growcery (NutriVaultApp)..."
xcrun devicectl device install app --device "$DEVICE_ID" "$NUTRI_APP"

echo "Step 4: Installing/Updating GrowTasks (com.nkembi.growstudy / GrowTasks)..."
xcrun devicectl device install app --device "$DEVICE_ID" "$STUDY_APP"

echo "Deployment complete. Verifying installed 3-App Suite (GrowFit, Growcery, GrowTasks)..."
xcrun devicectl device info apps --device "$DEVICE_ID" | grep -E "com.nkembi.somagym|com.nkembi.nutrivault|com.nkembi.growstudy|com.nkembi.growfinance" || true

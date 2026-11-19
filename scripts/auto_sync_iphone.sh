#!/bin/bash
set -u

DEVICE_ID="00008140-001E292E0062201C"
PRODUCTS_DIR="/Users/parris-campbellnkembi/Developer/GrowWorkspace/build/DerivedData/Build/Products/Debug-iphoneos"
GYM_APP="$PRODUCTS_DIR/GymApp.app"
NUTRI_APP="$PRODUCTS_DIR/NutriVaultApp.app"
STUDY_APP="$PRODUCTS_DIR/GrowStudy.app"

echo "=== Autonomous Sideload Synchronization Daemon Active ==="
echo "Monitoring for direct physical connection to iPhone ($DEVICE_ID)..."

while true; do
    # Check if devicectl reports device as connected and available (unlocked)
    if xcrun devicectl list devices 2>/dev/null | grep "$DEVICE_ID" | grep -q -w "available"; then
        echo "Device detected as available and unlocked."
        echo "Executing autonomous provisioning sequence..."
        
        # Step 1: Remove GrowFinance to strictly respect 3-app slot limit
        echo "Removing com.nkembi.growfinance from iPhone..."
        xcrun devicectl device uninstall app --device "$DEVICE_ID" com.nkembi.growfinance 2>/dev/null || true
        
        # Step 2: Re-certify and restore Growcery (NutriVaultApp)
        echo "Restoring Growcery (NutriVaultApp)..."
        xcrun devicectl device install app --device "$DEVICE_ID" "$NUTRI_APP"
        
        # Step 3: Update Grow (GymApp)
        echo "Updating Grow (GymApp)..."
        xcrun devicectl device install app --device "$DEVICE_ID" "$GYM_APP"
        
        # Step 4: Install GrowTasks
        echo "Installing GrowTasks (com.nkembi.growstudy)..."
        xcrun devicectl device install app --device "$DEVICE_ID" "$STUDY_APP"
        
        echo "=== Verification of Installed Applications ==="
        xcrun devicectl device info apps --device "$DEVICE_ID" 2>/dev/null | grep -E "com.nkembi.somagym|com.nkembi.nutrivault|com.nkembi.growstudy" || true
        
        echo "Autonomous synchronization completed successfully."
        exit 0
    fi
    
    sleep 2
done

#!/usr/bin/env zsh
# Launch GrowStudy on MacBook Air M4
APP_PATH="$HOME/Applications/GrowStudy.app"

if [ -d "$APP_PATH" ]; then
    open "$APP_PATH" || "$APP_PATH/Contents/MacOS/GrowStudy" &
else
    echo "GrowStudy.app not found at $APP_PATH"
fi

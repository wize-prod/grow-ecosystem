#!/bin/bash
# GymApp MCP Server Launcher
# Binds to http://127.0.0.1:8765/sse for Gemini Developer Mode

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="/Users/parris-campbellnkembi/Developer/GrowWorkspace"
VENV="${WORKSPACE}/.venv"

echo "Starte GymApp Unified MCP-Server..."
echo "Endpunkt fuer Gemini Developer Mode: http://127.0.0.1:8765/sse"

cd "${WORKSPACE}"
export PYTHONPATH="${WORKSPACE}:${PYTHONPATH}"
exec "${VENV}/bin/python3" "${DIR}/server.py"


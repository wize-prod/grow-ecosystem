#!/bin/bash
# Unified Grow MCP Server Launcher (Port 8765)
# Delegiert direkt an den konsolidierten 40-Tool-MCP-Server (scripts/growcery_mcp/server.py)

WORKSPACE="/Users/parris-campbellnkembi/Developer/GrowWorkspace"
VENV="${WORKSPACE}/.venv"

echo "Starte Unified Grow MCP-Server (40 Tools, Supabase, CORS) auf Port 8765..."
cd "${WORKSPACE}"
export PYTHONPATH="${WORKSPACE}:${PYTHONPATH}"
exec "${VENV}/bin/python3" "${WORKSPACE}/scripts/growcery_mcp/server.py" --port 8765 "$@"

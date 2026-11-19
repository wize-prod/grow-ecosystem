#!/bin/bash
# Growcery MCP Server Launcher
# Binds to http://127.0.0.1:8766/sse for Gemini Developer Mode / External Agents
# Supports --stdio for local agent configurations

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="/Users/parris-campbellnkembi/Developer/GrowWorkspace/.venv"

echo "Starte Growcery Unified MCP-Server..."
echo "Endpunkt fuer Gemini Developer Mode: http://127.0.0.1:8766/sse"

exec "${VENV}/bin/python3" "${DIR}/server.py" "$@"

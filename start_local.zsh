#!/bin/zsh


if lsof -i :7681 &> /dev/null; then
    echo "Warning: Port 7681 is already in use. Killing existing process..."
    pkill -f "ttyd.*7681" || true
    sleep 1
fi

echo "Starting terminal server on port 7681..."
ttyd -p 7681 -W ./restricted_shell.sh &
TTYD_PID=$!

cleanup() {
    echo "Stopping terminal server..."
    kill $TTYD_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

sleep 2

if ! ps -p $TTYD_PID > /dev/null; then
    echo "Error: Failed to start terminal server"
    exit 1
fi

echo "Terminal server started successfully (PID: $TTYD_PID)"
echo "Starting MkDocs server..."

mkdocs serve
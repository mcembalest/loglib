#!/bin/zsh

# Make shell script executable
chmod +x restricted_shell.sh

# Check if ttyd is installed
if ! command -v ttyd &> /dev/null; then
    echo "Error: ttyd is not installed. Please install it first:"
    echo "  brew install ttyd  # macOS"
    echo "  apt install ttyd   # Ubuntu/Debian"
    exit 1
fi

# Check if port 7681 is available
if lsof -i :7681 &> /dev/null; then
    echo "Warning: Port 7681 is already in use. Killing existing process..."
    pkill -f "ttyd.*7681" || true
    sleep 1
fi

# Start terminal server in background
echo "Starting terminal server on port 7681..."
ttyd -p 7681 -W ./restricted_shell.sh &
TTYD_PID=$!

# Function to cleanup on exit
cleanup() {
    echo "Stopping terminal server..."
    kill $TTYD_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

# Wait a moment for ttyd to start
sleep 2

# Check if ttyd started successfully
if ! ps -p $TTYD_PID > /dev/null; then
    echo "Error: Failed to start terminal server"
    exit 1
fi

echo "Terminal server started successfully (PID: $TTYD_PID)"
echo "Starting MkDocs server..."

# Start MkDocs (this will block)
mkdocs serve
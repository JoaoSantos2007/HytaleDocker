# Attempt to shutdown the server gracefully
# Returns 0 if it is shutdown
# Returns 1 if it is not able to be shutdown
shutdown_server() {
    local return_val=0
    echo "Attempting graceful server shutdown"
    
    # Find the process ID
    local pid=$(pgrep -f HytaleServer.jar)
    
    if [ -n "$pid" ]; then
        # Send SIGTERM to allow graceful shutdown
        kill -SIGTERM "$pid"
        
        # Wait up to 30 seconds for process to exit
        local count=0
        while [ $count -lt 30 ] && kill -0 "$pid" 2>/dev/null; do
            sleep 1
            count=$((count + 1))
        done
        
        # Check if process is still running
        if kill -0 "$pid" 2>/dev/null; then
            echo "Server did not shutdown gracefully, forcing shutdown"
            return_val=1
        else
            echo "Server shutdown gracefully"
        fi
    else
        echo "Server process not found"
        return_val=1
    fi
    
    return "$return_val"
}

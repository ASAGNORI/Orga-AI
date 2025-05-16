#!/bin/bash

# Monitor Ollama service performance and health
# Usage: ./monitor-ollama.sh [--log-file <path>] [--interval <seconds>]

# Configuration
CONTAINER_NAME="orga-ai-v4-ollama-1"
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/ollama_monitor.log"
CHECK_INTERVAL=60
ALERT_THRESHOLD_CPU=90
ALERT_THRESHOLD_MEM=90
ALERT_THRESHOLD_RESP=5000 # Response time threshold in ms

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --log-file) LOG_FILE="$2"; shift ;;
        --interval) CHECK_INTERVAL="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Create logs directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages with timestamp
log_message() {
    local msg="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

# Function to check if Ollama container is running
check_container() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        log_message "ERROR: Ollama container is not running"
        return 1
    fi
    return 0
}

# Function to check API health and measure response time
check_health() {
    local start_time=$(date +%s%N)
    local response=$(curl -s -o /dev/null -w "%{http_code}:%{time_total}" http://localhost:11434/api/version)
    local status_code=$(echo $response | cut -d: -f1)
    local response_time=$(echo $response | cut -d: -f2)
    local response_ms=$(echo "$response_time * 1000" | bc)

    if [ "$status_code" = "200" ]; then
        log_message "Health check: OK (Response time: ${response_ms}ms)"
        if (( $(echo "$response_ms > $ALERT_THRESHOLD_RESP" | bc -l) )); then
            log_message "WARNING: Response time above threshold: ${response_ms}ms"
        fi
    else
        log_message "ERROR: Health check failed with status $status_code"
    fi
}

# Function to monitor resource usage
monitor_resources() {
    # Get CPU usage percentage
    local cpu_usage=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.CPUPerc}}" | sed 's/%//')
    
    # Get memory usage percentage and details
    local mem_usage=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.MemPerc}}" | sed 's/%//')
    local mem_details=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.MemUsage}}")
    
    log_message "Resource usage - CPU: ${cpu_usage}% | Memory: ${mem_usage}% ($mem_details)"
    
    # Check resource thresholds
    if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        log_message "WARNING: High CPU usage detected: ${cpu_usage}%"
    fi
    
    if (( $(echo "$mem_usage > $ALERT_THRESHOLD_MEM" | bc -l) )); then
        log_message "WARNING: High memory usage detected: ${mem_usage}%"
    fi
}

# Main monitoring loop
log_message "Starting Ollama monitoring (Interval: ${CHECK_INTERVAL}s, Log: $LOG_FILE)"
echo "Press Ctrl+C to stop"

while true; do
    if check_container; then
        check_health
        monitor_resources
        echo "----------------------------------------"
    fi
    sleep $CHECK_INTERVAL
done

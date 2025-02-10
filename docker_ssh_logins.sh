#!/bin/bash

# Array of Docker container names for SSH connection
containers=("managed-node1" "managed-node2" "managed-node3")

# Define green text color
GREEN='\033[0;32m'
# Define reset color (to reset text color to default)
NC='\033[0m'

echo "[===== Nodes: =====]"
# Check if container is running, if not start it
for container in "${containers[@]}"; do
    # Check if container is running
    if docker ps --filter "name=$container" | grep -q "$container"; then
        echo -e "[$container] -${GREEN} Active${NC}"
    else
    	# Start the container if not running and discard output
        docker start "$container" > /dev/null 2>&1 && echo -e "[$container] - ${GREEN}Active${NC}"
    fi
done

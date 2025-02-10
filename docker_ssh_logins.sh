#!/bin/bash

# Array of containers
containers=("managed-node1" "managed-node2" "managed-node3")

# Define green text using tput
GREEN=$(tput setaf 2)  # 2 is the color code for green
NC=$(tput sgr0)        # Reset color

# Function to check if the container is running, and start it if not
check_and_start_container() {
    container=$1
    if docker ps --filter "name=$container" | grep -q "$container"; then
        echo -e "[$container] - ${GREEN}Active${NC}"
    else
        docker start "$container" > /dev/null 2>&1 && echo -e "[$container] - ${GREEN}Active${NC}"
    fi
}


# Function to check if SSH is running in the container and start it if necessary
check_and_start_ssh() {
    container=$1
    ssh_status=$(docker exec "$container" service ssh status | grep -q "running" && echo "running" || echo "stopped")

    if [[ "$ssh_status" == "running" ]]; then
        echo -e "[$container] - ${GREEN}running${NC}"
    else
        docker exec "$container" service ssh start > /dev/null 2>&1 && echo -e "[$container] - ${GREEN}running${NC}"
    fi
}

# Check if containers are started and active
echo "[===== Nodes: =====]"
for container in "${containers[@]}"; do
    check_and_start_container "$container"
done

# Check SSH service status and start it if necessary
echo "[===== SSH-Status =====]"
for container in "${containers[@]}"; do
    check_and_start_ssh "$container"
done

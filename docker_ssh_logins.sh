#!/bin/bash

# Array of containers
containers=("managed-node1" "managed-node2" "managed-node3")

# Define green text using tput
GREEN=$(tput setaf 2)  # 2 is the color code for green
NC=$(tput sgr0)        # Reset color
RED=$(tput setaf 1)


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
    # Get the SSH status
    ssh_status=$(docker exec "$container" service ssh status | grep -q "not running" && echo "stopped" || echo "running")

    if [[ "$ssh_status" == "running" ]]; then
        echo -e "[$container] - ${GREEN}running${NC}"
    else
        echo -e "[${RED}$container${NC}] - ${RED}stopped${NC}"
        # Start SSH service if stopped
        docker exec "$container" service ssh start > /dev/null 2>&1
        echo -e "[$container] - ${GREEN}running${NC}"
    fi
}


# Function to test SSH connection
test_ssh_connection() {
    container=$1
    container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")

    if ssh -o BatchMode=yes -o ConnectTimeout=5 root@"$container_ip" "echo " 2>/dev/null; then
        echo -e "[$container] - ${GREEN}Successful${NC}"
    else
        echo -e "[${RED}$container${NC}] - ${RED}Failed${NC}"
    fi
}

# Check if containers are started and active
echo "[=============== Nodes: ===============]"
for container in "${containers[@]}"; do
	echo ""
    check_and_start_container "$container"
done

echo ""

# Check SSH service status and start it if necessary
echo "[=============== SSH-Status ===============]"
for container in "${containers[@]}"; do
	echo ""
    check_and_start_ssh "$container"
done

echo ""

# Test SSH connections
echo "[=============== SSH Connection ================]"
for container in "${containers[@]}"; do
    test_ssh_connection "$container"
done

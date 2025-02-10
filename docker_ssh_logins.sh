#!/bin/bash

# Array of Docker container names for SSH connection
containers=("managed-node1" "managed-node2" "managed-node3")

# Function to check if Docker container is running, and start if necessary
check_and_start_container(){
	container=$1
	status=$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)

	if [[ "status" != "true" ]]; then
		echo "Starting  $container.."
		docker start "$container"
	else
		echo "$container is already running."
	fi
}

#Check if containers are started and active
echo "[===== Nodes ======]"
for container in "${containers[@]}";do
	check_and_start_container "$container"
done


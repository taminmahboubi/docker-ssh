# docker-ssh
log into multiple Docker containers via SSH for Ansible testing

---
## 1. Initialization
Since we want to manipulate **multiple** containers, we'll begin by defining and inserting them into an array:
`containers=("managed-node1" "managed-node2" "managed-node3")`

Define ANSI colours for terminal output:
```bash
GREEN=$'\e[32m'  # Green text 
NC=$'\e[0m'     # Reset color
RED=$'\e[31m'   # Red text 
```
These will be used for successful and failed outputs.
---

## 2. Check and start container

Next we want to create a function to check if the container is running, and start it if it's not.
- We'll call it `check_and_start_container()`
- First variable will be `container=$1`, `$1` represents the firtst argument passed to the function when its called.
- Next we check `if` the node (i.e. `$container` variable will represent each node in a `for` loop which we will add later on) is running, we'll base it off the command `docker ps -f "name=managed-node1"` which will check through the list of running nodes, and filter out the node named **managed-node** (for this example). we'll also use `| grep -q "managed-node1"` which searched the output of `docker ps` for the string `"managed-node1"`, `-q` flag makes the `grep` silent. (it will return `0` if successful(finds `managed-node1`) and `1` if it fails.
- if it fails, we'll start the container with `docker start "managed-node1"` and echo `[managed-node1] - Active`
- if its successful, we'll simply echo `[managed-node1] - Active`

```bash
# Function to check if the container is running, and start it if not
check_and_start_container() {
    container=$1
    if docker ps --filter "name=$container" | grep -q "$container"; then
        echo -e "[$container] - ${GREEN}Active${NC}"
    else
        docker start "$container" > /dev/null 2>&1 && echo -e "[$container] - ${GREEN}Active${NC}"
    fi
}

```



## 3. Check and start SSH

## 4. Test SSH connection

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

### Next we want to create a function to check if the container is running, and start it if it's not.
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

### For Loop (where the function is called):

`echo "[=============== Nodes: ================]"`
Code above is for readability.

We want a `for` loop that will iterate over each element in the `containers` array. Each container (managed-node1, managed-node2, managed-node3) will be passed as an argument to the `check_and_start_container` function.

```bash
for container in "${containers[@]}"; do
	echo ""
	check_and_start_container "$container"
done
```

---


## 3. Check and start SSH

Next we create a function to check if SSH is running in the container and start it if necessary
`check_and_start_ssh()`

- Again, the first line of code inside the function will be `container=$1`, represents the first argument passed when the function is called.
- We want to get the SSH status: 
	- this can be done from within the node itself using `service ssh status`, however we are accessing it from outside, so we can use this command e.g `docker exec managed-node1 service ssh status`, which will output `* ssh is running` or `* ssh is not running`.
	- we can then pipe `grep -q` to quietly check if its output is `running` or `not running`, which can be achieved using the code `| grep -q "not running" && echo "stopped" || echo "running")` heres the logic:
	```
	if grep finds "not running", then echo "stopped"
	else
		echo "running" 
	```
- finally: `ssh_status=$(docker exec "$container" service ssh status | grep -q "not running" && echo "stopped" || echo "running")`
- Then we check if `ssh_status == "running"` or `"stopped"`, if its `"stopped"`, we echo `[$container] - stopped` then we start the container/node using: `docker exec "$container" service ssh start` and echo `[$container] - running` 
- if it's already running, we simply echo `[$container] - running` 

Then we add the `for loop` which it pretty much identical to the previous, except it calls the `check_and_start` functuion.



## 4. Test SSH connection

Finlly, a fucntion to test the SSH connection.
`test_ssh_connection()`

- again add a `container=$1` variable that takes the first argument passed into the function.

`container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")`
	- `docker inspect` is a command that gets detailed information about a docker container in the JSON format.
```JSON
{
  // ... (Other container details, omitted for brevity)
  "NetworkSettings": {
    // ... (Other network settings, omitted for brevity)
    "Networks": {
      "bridge": {
        "IPAddress": "172.17.0.2", // The IP address used in the code
        // ... (Other details for this network, omitted)
      },
      // ... (Other networks, if any, omitted)
    }
  },
  // ... (Other container details, omitted)
}


	dsd

```
	- `range` loops through each item in a list (or collection) of things.
	- `{{end}}` tells the Go template engine where a loop or conditional statement finishes. kinda like a closing bracket, marking the end of a block of code.
	- ` .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")` is a Go template that's used to extract IP addresses from a JSON object(the output of `docker inspect`).


Then an if statement to to check if an SSH server is running and accessible inside the Docker container:
-  `if ssh -o BatchMode=yes -o ConnectTimeout=5 root@"$container_ip" "echo " 2>/dev/null; then`
	- `-o BatchMode=yes` this option tells SSH to run in Batch Mode, which prevents SSH from prompting for any input(passwords, etc).
	- `-o ConnectTimeout=5` sets a timeout of 5 seconds for the connection attempt, if the connection isn't established within 5 seconds, SSH will give up, this helps to prevent the script from hanging indefinitely if a container isn't running.
	- `root@"$container_ip"` specifies the user **root** and the host ip **$container_ip**
	- `2>/dev/null` redirects any *error messages* to `/dev/null`, anything send there is discarded.
		- if successful, echo `"[$container] - Successful"`
		- if **not** successful, echo `"[$container] - Failed"` 

```bash
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

```


Then we add the `for loop` which it pretty much identical to the previous two, except it calls the `test_ssh_connection` functuion.

# Start network

## Prequisites

### Create swarm network

On _master_
```terminal
$ docker swarm init
$ docker swarm join-token manager
$ docker network create --attachable --driver overlay fabric
```

On _worker1_ & _worker2_
```terminal
<Run docker join command with token as manager>
```

Verify
```terminal
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
xw7x6jl4xd4os0qbhyqpzh3e8 *   master              Ready               Active              Reachable           19.03.1
w2kcpotnobikl5rrxcmkk77fp     worker1             Ready               Active              Leader              19.03.5
5le1phxeqqrc3jq2m1nv7okiq     worker2             Ready               Active              Reachable           19.03.8
```

### Add hostname

Add IP address of these 3 machines to hosts file in every mahines

```terminal
$ cat /etc/hosts
192.168.153.130 master
192.168.153.131 worker1
192.168.153.132 worker2
```

### Optional setups

- Make a `ssh-keygen` & `ssh-copy-id` from _master_ machine to make a password-less access to _worker1_ & _worker2_.
- Create the same account username on 3 machines.

## Start network from _master_ (clean network)

### Script
```bash
#!/bin/bash

# Clean up existing network (remove containers & volumes)
yes | ./byfn.sh down && yes | docker volume prune
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh down && yes | docker volume prune"
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh down && yes | docker volume prune"

# Generate crypto materials, channel artifacts and docker-compose files
yes | ./byfn.sh down && yes | docker volume prune && yes | ./byfn.sh generate

echo "Copy crypto materials, channel artifacts and docker-compose files to worker machines"
scp -r crypto-config channel-artifacts docker-compose-org1.yaml docker-compose-org2.yaml worker1:~/cbnu-voting-system-network
scp -r crypto-config channel-artifacts docker-compose-org1.yaml docker-compose-org2.yaml worker2:~/cbnu-voting-system-network

# Start up ZooKeeper containers
# ZooKeeper
# Worker2
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f zk_scripts/docker-compose-zk0.yaml"
# Master
yes | ./byfn.sh up -f zk_scripts/docker-compose-zk1.yaml
# Worker1
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f zk_scripts/docker-compose-zk2.yaml"

# Start up Kafka containers
# Kafka
# Worker2
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f kafka_scripts/docker-compose-kafka0.yaml"
# Master
yes | ./byfn.sh up -f kafka_scripts/docker-compose-kafka1.yaml
# Worker1
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f kafka_scripts/docker-compose-kafka2.yaml"
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f kafka_scripts/docker-compose-kafka3.yaml"

# Start up Order containers
# Orderer
# Worker2
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f docker-compose-orderer0.yaml"
# Master
yes | ./byfn.sh up -f docker-compose-orderer1.yaml
# Worker1
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f docker-compose-orderer2.yaml"

# Start up peer organization containers
# Peer Orgs
# Worker2
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f docker-compose-org1.yaml"
# Master
yes | ./byfn.sh up -f docker-compose-org2.yaml

docker service ls

# Creating channel: mychannel
ORG2_CLI_CONTAINER_ID=$(docker ps |grep fabric_org2cli|cut -d" " -f1)
docker exec $ORG2_CLI_CONTAINER_ID scripts/script.sh mychannel 3 golang 10 false true
```

## Start network after reboot or down (keeping old data)

### Script
```bash
#!/bin/bash

# Clean up containers (including crypto materials)
yes | ./byfn.sh down
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh down
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh down

# Generate new crypto materials, channel artifacts and docker-compose files
./byfn.sh generate

# Copy new crypto materials, channel artifacts and docker-compose files to worker machines
scp -r crypto-config channel-artifacts docker-compose-org1.yaml docker-compose-org2.yaml worker1:~/cbnu-voting-system-network
scp -r crypto-config channel-artifacts docker-compose-org1.yaml docker-compose-org2.yaml worker2:~/cbnu-voting-system-network

# Start up ZooKeeper containers
# ZooKeeper
# Worker2
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f zk_scripts/docker-compose-zk0.yaml"
# Master
yes | ./byfn.sh up -f zk_scripts/docker-compose-zk1.yaml
# Worker1
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f zk_scripts/docker-compose-zk2.yaml"

# Start up Kafka containers
# Kafka
# Worker2
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f kafka_scripts/docker-compose-kafka0.yaml"
# Master
yes | ./byfn.sh up -f kafka_scripts/docker-compose-kafka1.yaml
# Worker1
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f kafka_scripts/docker-compose-kafka2.yaml"
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f kafka_scripts/docker-compose-kafka3.yaml"

# Start up Order containers
# Orderer
# Worker2
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f docker-compose-orderer0.yaml"
# Master
yes | ./byfn.sh up -f docker-compose-orderer1.yaml
# Worker1
ssh worker1 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f docker-compose-orderer2.yaml"

# Start up peer organization containers
# Peer Orgs
# Worker2
ssh worker2 "cd ~/cbnu-voting-system-network && yes | ./byfn.sh up -f docker-compose-org1.yaml"
# Master
yes | ./byfn.sh up -f docker-compose-org2.yaml

docker service ls
```

## Firewall Note

### Prevent docker using `iptables` 

On all machines (master, worker1, worker2)

Edit or create a file `/etc/docker/daemon.json` and add this json content

```
{
  "iptables": false
}
```

### Use `ufw` instead of `iptables`

Check if the ufw is already enabled or enable it by running this command.

```
# ufw enable
```

### Allow some ports for docker swarm communication in local network (Run this on all machines)

Local network address is 192.168.153.0/24

```
sudo ufw allow from 192.168.153.0/24 to any port 2376 proto tcp comment "Docker Swarm tcp 2376"
sudo ufw allow from 192.168.153.0/24 to any port 2377 proto tcp comment "Docker Swarm tcp 2377"
sudo ufw allow from 192.168.153.0/24 to any port 7946 proto tcp comment "Docker Swarm tcp 7946"
sudo ufw allow from 192.168.153.0/24 to any port 7946 proto udp comment "Docker Swarm udp 7946"
sudo ufw allow from 192.168.153.0/24 to any port 4789 proto udp comment "Docker Swarm udp 4789"
```

### Allow some ports for hyperledger fabric

Used ports
#### Master
- 2181 ZooKeeper1 Client port
- 2888 ZooKeeper1 Peer port
- 3888 ZooKeeper1 Peer port
- 9092 Kafka1 Socket Server Listener port

- 7050 Orderer1
- 7054 CA - Org2
- 7051 Peer0 - Org2
- 8051 Peer1 - Org2
- 5984 CouchDB0 - Org2
- 6984 CouchDB1 - Org2

```
sudo ufw allow from 192.168.153.0/24 to any port 2181 proto tcp comment "ZooKeeper1 Client port"
sudo ufw allow from 192.168.153.0/24 to any port 2888 proto tcp comment "ZooKeeper1 Peer port"
sudo ufw allow from 192.168.153.0/24 to any port 3888 proto tcp comment "ZooKeeper1 Peer port"
sudo ufw allow from 192.168.153.0/24 to any port 9092 proto tcp comment "Kafka1 Socket Server Listener port"
sudo ufw allow from 192.168.153.0/24 to any port 7050 proto tcp comment "Orderer1"
sudo ufw allow from 192.168.153.0/24 to any port 7054 proto tcp comment "CA - Org2"
sudo ufw allow from 192.168.153.0/24 to any port 7051 proto tcp comment "Peer0 - Org2"
sudo ufw allow from 192.168.153.0/24 to any port 8051 proto tcp comment "Peer1 - Org2"
sudo ufw allow from 192.168.153.0/24 to any port 5984 proto tcp comment "CouchDB0 - Org2"
sudo ufw allow from 192.168.153.0/24 to any port 6984 proto tcp comment "CouchDB1 - Org2"
```

#### Worker1
- 2181 ZooKeeper2 Client port
- 2888 ZooKeeper2 Peer port
- 3888 ZooKeeper2 Peer port
- 9092 Kafka2 Socket Server Listener port
- 9094 Kafka3 Socket Server Listener port

- 7050 Orderer2

```
sudo ufw allow from 192.168.153.0/24 to any port 2181 proto tcp comment "ZooKeeper2 Client port"
sudo ufw allow from 192.168.153.0/24 to any port 2888 proto tcp comment "ZooKeeper2 Peer port"
sudo ufw allow from 192.168.153.0/24 to any port 3888 proto tcp comment "ZooKeeper2 Peer port"
sudo ufw allow from 192.168.153.0/24 to any port 9092 proto tcp comment "Kafka2 Socket Server Listener port"
sudo ufw allow from 192.168.153.0/24 to any port 9094 proto tcp comment "Kafka3 Socket Server Listener port"
sudo ufw allow from 192.168.153.0/24 to any port 7050 proto tcp comment "Orderer2"
```

#### Worker2
- 2181 ZooKeeper0 Client port
- 2888 ZooKeeper0 Peer port
- 3888 ZooKeeper0 Peer port

- 7050 Orderer0
- 7054 CA - Org1
- 7051 Peer0 - Org1
- 8051 Peer1 - Org1
- 5984 CouchDB0 - Org1
- 6984 CouchDB1 - Org1

```
sudo ufw allow from 192.168.153.0/24 to any port 2181 proto tcp comment "ZooKeeper0 Client port"
sudo ufw allow from 192.168.153.0/24 to any port 2888 proto tcp comment "ZooKeeper0 Peer port"
sudo ufw allow from 192.168.153.0/24 to any port 3888 proto tcp comment "ZooKeeper0 Peer port"
sudo ufw allow from 192.168.153.0/24 to any port 7050 proto tcp comment "Orderer0"
sudo ufw allow from 192.168.153.0/24 to any port 7054 proto tcp comment "CA - Org1"
sudo ufw allow from 192.168.153.0/24 to any port 7051 proto tcp comment "Peer0 - Org1"
sudo ufw allow from 192.168.153.0/24 to any port 8051 proto tcp comment "Peer1 - Org1"
sudo ufw allow from 192.168.153.0/24 to any port 5984 proto tcp comment "CouchDB0 - Org1"
sudo ufw allow from 192.168.153.0/24 to any port 6984 proto tcp comment "CouchDB1 - Org1"
```

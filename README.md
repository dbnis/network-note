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



#!/bin/bash

ENV_LOC="config/.env"

# get env vars
envList=$(grep -v '^#' ${ENV_LOC} | xargs)

# Export env vars
for ITER in ${envList}; do
    export ${ITER}
done

#################
# .env example
#################
# ## cluster setup
# CLUSTER_NODE_AMOUNT=3
# CLUSTER_CPU_CAPACITY=2
# CLUSTER_MEM_CAPACITY=2
# CLUSTER_DISK_AMOUNT=32
# CLUSTER_UBUNTU_VERSION=21.10

# ## kubernetes
# K3S_VERSION="v1.20.15+k3s1"

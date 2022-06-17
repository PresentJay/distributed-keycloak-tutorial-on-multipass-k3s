#!/bin/bash

ENV_LOC="config/.env"

# Show env vars
grep -v '^#' ${ENV_LOC}

# Export env vars
export $(grep -v '^#' ${ENV_LOC} | xargs)

#################
# .env example
#################
# ## cluster setup
# CLUSTER_NODE_AMOUNT=3
# CLUSTER_CPU_CAPACITY=2
# CLUSTER_MEM_CAPACITY=2
# CLUSTER_DISK_AMOUNT=32

# ## kubernetes
# K3S_VERSION="v1.20.15+k3s1"

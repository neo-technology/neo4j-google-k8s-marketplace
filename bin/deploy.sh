#!/bin/bash
#
# This script executes roughly the same as what the GKE marketplace does, and
# deploys the app with the set of parameters in the JSON below.
##################################################################
echo "Deploying test version"
SOLUTION_VERSION=$(cat chart/Chart.yaml | grep version: | sed 's/.*: //g')
DEPLOYER_IMAGE=gcr.io/neo4j-k8s-marketplace-public/causal-cluster/deployer:$SOLUTION_VERSION
APP_INSTANCE_NAME="neo4j-a$(head -c 2 /dev/urandom | base64 - | sed 's/[^A-Za-z0-9]/x/g' | tr '[:upper:]' '[:lower:]')"
vendor/marketplace-k8s-app-tools/scripts/start.sh \
   --deployer=$DEPLOYER_IMAGE \
   --parameters='{"name":"'$APP_INSTANCE_NAME'","namespace":"default","coreServers":"3", "cpuRequest":"100m", "memoryRequest": "1Gi", "volumeSize": "20Gi", 
   "readReplicaServers":"1", "image": "gcr.io/neo4j-k8s-marketplace-public/causal-cluster:'$SOLUTION_VERSION'"}'

echo "When finished, can be deleted via kubectl delete application/$APP_INSTANCE_NAME"

#!/bin/bash
#
# This script executes cypher-shell on a pod chosen from the coordinating service.
# It requires that APP_INSTANCE_NAME be defined, as is defined in deploy.sh
#################################################################################
if [ -z $APP_INSTANCE_NAME ] ; then
    echo "Ensure APP_INSTANCE_NAME is defined in your environment first"
    exit 1
fi

SOLUTION_VERSION=$(cat chart/Chart.yaml | grep version: | sed 's/.*: //g')

DEV_REGISTRY=gcr.io/neo4j-k8s-marketplace-public/causal-cluster
PROD_REGISTRY=gcr.io/cloud-marketplace/neo4j-public/causal-cluster-k8s

kubectl run -it --rm cypher-shell \
   --image=$PROD_REGISTRY:$SOLUTION_VERSION \
   --restart=Never \
   --namespace=default \
   --command -- ./bin/cypher-shell -u neo4j \
   -p "$(kubectl get secrets $APP_INSTANCE_NAME-neo4j-secrets -o yaml | grep neo4j-password: | sed 's/.*neo4j-password: *//' | base64 --decode)" \
   -a $APP_INSTANCE_NAME-neo4j.default.svc.cluster.local 

#!/bin/bash
PROJECT=neo4j-k8s-marketplace-public
CLUSTER=lab
ZONE=us-central1-a
NODES=3
API=beta
NEO4J_VERSION=3.4.1-enterprise

gcloud beta container clusters create $CLUSTER \
    --zone "$ZONE" \
    --project $PROJECT \
    --machine-type "n1-standard-1" \
    --num-nodes "3" \
    --max-nodes "10" \
    --enable-autoscaling
    
gcloud container clusters get-credentials $CLUSTER \
   --zone $ZONE \
   --project $PROJECT

# Configure local auth of docker so that we can use regular
# docker commands to push/pull from our GCR setup.
gcloud auth configure-docker

# Bootstrap RBAC cluster-admin for your user.
# More info: https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin --user $(gcloud config get-value account)

exec nohup kubectl proxy &

# Create google-specific custom resources in the cluster.
kubectl apply -f vendor/marketplace-k8s-app-tools/crd/app-crd.yaml

# This is the method for a local helm install.
# helm init
# helm install --name mygraph ~/hax/charts/stable/neo4j \
#    --set neo4jPassword=mySecretPassword \
#    --set imageTag=$NEO4J_VERSION \
#    --set authEnabled=true \
#    --set coreServers=3 \
#    --set readReplicaServers=0 \
#    --set acceptLicenseAgreement=yes

# kubectl expose pod neo4j-helm-neo4j-core-0 --port=7687 --target-port=7687 --name=core0-bolt --type=LoadBalancer
# kubectl expose pod neo4j-helm-neo4j-core-1 --port=7687 --target-port=7687 --name=core1-bolt --type=LoadBalancer
# kubectl expose pod neo4j-helm-neo4j-core-2 --port=7687 --target-port=7687 --name=core2-bolt --type=LoadBalancer

# TO DELETE
# helm del --purge mygraph
# kubectl delete configmaps mygraph-neo4j-ubc

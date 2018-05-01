#!/bin/bash
PROJECT=neo4j-k8s-marketplace-public
CLUSTER=lab
ZONE=us-central1-a
NODES=3
API=beta
NEO4J_VERSION=3.3.5-enterprise

gcloud $API container --project $PROJECT clusters create $CLUSTER --zone $ZONE \
   --username "admin" --cluster-version "1.8.8-gke.0" \
   --machine-type "n1-standard-1" --image-type "COS" \
   --disk-size "100" \
   --tags "neo4j" \
   --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
   --num-nodes $NODES --network "default" \
   --enable-cloud-logging \
   --enable-cloud-monitoring \
   --subnetwork "default"


gcloud container clusters get-credentials $CLUSTER \
   --zone $ZONE \
   --project $PROJECT

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init

sleep 5
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}' 

helm install --name mygraph ~/hax/charts/stable/neo4j \
   --set neo4jPassword=mySecretPassword \
   --set imageTag=$NEO4J_VERSION \
   --set authEnabled=true \
   --set core.numberOfServers=3 \
   --set readReplica.numberOfServers=0 \
   --set acceptNeo4jLicense=yes

kubectl expose pod neo4j-helm-neo4j-core-0 --port=7687 --target-port=7687 --name=core0-bolt --type=LoadBalancer
kubectl expose pod neo4j-helm-neo4j-core-1 --port=7687 --target-port=7687 --name=core1-bolt --type=LoadBalancer
kubectl expose pod neo4j-helm-neo4j-core-2 --port=7687 --target-port=7687 --name=core2-bolt --type=LoadBalancer


# TO DELETE
# helm del --purge mygraph
# kubectl delete configmaps mygraph-neo4j-ubc

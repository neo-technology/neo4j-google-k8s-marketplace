#!/bin/bash
PROJECT=neo4j-k8s-marketplace-public
CLUSTER=lab
ZONE=us-central1-a
NODES=3
API=beta
NEO4J_VERSION=3.3.5-enterprise

gcloud beta container clusters create $CLUSTER \
    --zone "$ZONE" \
    --project $PROJECT \
    --machine-type "n1-standard-1" \
    --num-nodes "3"
    
gcloud container clusters get-credentials $CLUSTER \
   --zone $ZONE \
   --project $PROJECT

# Bootstrap RBAC cluster-admin for your user.
# More info: https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin --user $(gcloud config get-value account)

exec nohup kubectl proxy &
helm init

kubectl apply -f vendor/marketplace-k8s-app-tools/crd/app-crd.yaml

# OLD
# kubectl create serviceaccount --namespace kube-system tiller
# kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
# sleep 5
# kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}' 

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

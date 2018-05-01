#!/bin/bash
helm template neo4j stable/neo4j \
   --set name=neo4j-helm \
   --set neo4jPassword=mySecretPassword \
   --set imageTag=$NEO4J_VERSION \
   --set authEnabled=true \
   --set core.numberOfServers=3 \
   --set image=gcr.io/neo4j-k8s-marketplace-public/neo4j \
   --set imageTag=3.3.4 \
   --set imagePullPolicy=IfNotPresent \
   --set core.persistentVolume.storageClass=standard \
   --set core.persistentVolume.size=10Gi \
   --set resources={} \
   --set readReplica.numberOfServers=0 > manifest.yml

#    --set core.sideCarContainers={} \
#    --set core.initContainers={} \
#    --set core.persistentVolume.annotations={} \

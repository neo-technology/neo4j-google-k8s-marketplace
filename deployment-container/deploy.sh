#!/bin/sh

echo "I am the install container for Neo4j on Google K8S Marketplace"

NEO4J_CHART=/data/charts/stable/neo4j

if [ -z ${NEO4J_VERSION} ]; then
  NEO4J_VERSION=3.3.5-enterprise
fi

if [ -z ${NAME} ] ; then
  echo "NAME was not set, defaulting to deploy mygraph"
  NAME=mygraph
fi

helm install --name "$NAME" $NEO4J_CHART \
   --set neo4jPassword=mySecretPassword \
   --set imageTag=$NEO4J_VERSION \
   --set authEnabled=true \
   --set core.numberOfServers=3 \
   --set readReplica.numberOfServers=0 \
   --set acceptNeo4jLicense=yes

echo "Helm installed.  Waiting for it to come alive"
sleep 10
echo "Calling it done"
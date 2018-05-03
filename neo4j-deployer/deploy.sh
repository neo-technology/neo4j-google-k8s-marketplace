#!/bin/sh
export PATH=$PATH:/data/google-cloud-sdk/bin
echo "I am the deploy container for Neo4j on Google K8S Marketplace"

NEO4J_CHART=/data/charts/stable/neo4j

if [ -z ${NEO4J_VERSION} ]; then
  NEO4J_VERSION=3.3.5-enterprise
fi

if [ -z ${NAME} ] ; then
  echo "NAME was not set, defaulting to deploy mygraph"
  NAME=mygraph
else 
  echo "Deploying graph named $NAME"
fi

echo "Chart looks like:"
ls -l $NEO4J_CHART

echo "Kubectl proxy"
/bin/kubectl proxy

echo "Helm installing"
ls -l /bin/helm

/bin/helm install --name "$NAME" $NEO4J_CHART \
   --set neo4jPassword=mySecretPassword \
   --set imageTag=$NEO4J_VERSION \
   --set authEnabled=true \
   --set core.numberOfServers=3 \
   --set readReplica.numberOfServers=0 \
   --set acceptNeo4jLicense=yes

echo "Helm installed.  Waiting for it to come alive"
sleep 10
echo "Calling it done"

if [ -z ${TEST_MODE} ]; then
  echo "No testing"
else 
  echo "Test mode $TEST_MODE"
fi

echo "Long sleep"

sleep 1000000
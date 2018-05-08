#!/bin/sh
export PATH=$PATH:/data/google-cloud-sdk/bin
echo "I am the deploy container for Neo4j on Google K8S Marketplace"

NEO4J_CHART=/data/charts/stable/neo4j

if [ -z ${NEO4J_VERSION} ]; then
  NEO4J_VERSION=3.3.5-enterprise
fi

if [ -z ${APP_INSTANCE_NAME} ] ; then
  echo "APP_INSTANCE_NAME was not set, defaulting to deploy mygraph"
  APP_INSTANCE_NAME=mygraph
else 
  echo "Deploying graph named $APP_INSTANCE_NAME"
fi

if [ -z ${READ_REPLICAS} ] ; then
  READ_REPLICAS=0
fi

if [ -z ${CORE_NODES} ] ; then
  CORE_NODES=3
fi

if [ -z ${ACCEPT_LICENSE} ] ; then
  ACCEPT_LICENSE=yes
fi

if [ -z ${NEO4J_PASSWORD} ] ; then
  NEO4J_PASSWORD='mySecretPassword'
fi

echo "Here we go, we're deploying:"
head -n 5 $NEO4J_CHART/Chart.yaml

echo "Kubectl proxy"
exec /bin/kubectl proxy &
echo "Helm installing"
ls -l /bin/helm

/bin/helm init

echo "Installing Neo4j chart..."
/bin/helm install --name "$APP_INSTANCE_NAME" $NEO4J_CHART \
   --set neo4jPassword="$NEO4J_PASSWORD" \
   --set imageTag=$NEO4J_VERSION \
   --set authEnabled=true \
   --set core.numberOfServers=$CORE_NODES \
   --set readReplica.numberOfServers=$READ_REPLICAS \
   --set acceptNeo4jLicense=$ACCEPT_LICENSE

echo "Deployed"

if [ -z ${TEST_MODE} ]; then
  echo "Beginning testing"
  cd "$NEO4J_CHART" && /bin/helm test
  echo "Testing complete"
else 
  echo "Test mode $TEST_MODE"
fi

echo "Long sleep"

sleep 1000000
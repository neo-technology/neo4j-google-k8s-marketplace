# neo4j-google-k8s-marketplace

This repository contains instructions and files necessary for running Neo4j Enterprise via Google's
Hosted Kubernetes Marketplace.

If you would like setup instructions on how to install this from the GCP Marketplace, or on how to use the application once it is deployed, please consult the [user guide](user-guide/USER-GUIDE.md).

# Maintenance & Development / Getting started

## Updating git submodules

This repo contains git submodules corresponding to dependent Google code repos.
You can run the following commands to make sure submodules are updated.

```shell
git submodule sync --recursive
git submodule update --recursive --init --force
```

## Setting up the GKE environment

See `setup-k8s.sh` for instructions.  These steps are only to be followed for standing up a new testing cluster for the purpose of testing the code in this repo.

## Overview

The solution is composed of two core containers:
- The deployment container, which expands the helm chart and applies resources to a running k8s cluster See the `deployer` and `chart` directories.
- The test container, which is layered on top of the deploy container and runs functional tests to ensure a working neo4j cluster.  See the `apptest` directory.
- A set of solution containers deployed under the neo4j GCR. The primary solution container shares the name with the solution (causal cluster)
and tracks the 3.4 release series, but is not versioned more specifically than that.  See the `causal-cluster` directory.

## Building the Deployment Container
 
```
make app/build
```

## Running the Deployer Container

Using the marketplace-k8s-app-tools script to launch the deployment container mimics how google's
k8s marketplace does it with the UI.

The make task `make app/install` accomplishes this, below is a variant with what that does:

```
SOLUTION_VERSION=$(cat chart/Chart.yaml | grep version: | sed 's/.*: //g')
DEPLOYER_IMAGE=gcr.io/neo4j-k8s-marketplace-public/causal-cluster/deployer:$SOLUTION_VERSION
APP_INSTANCE_NAME="neo4j-a$(head -c 2 /dev/urandom | base64 - | sed 's/[^A-Za-z0-9]/x/g' | tr '[:upper:]' '[:lower:]')"
vendor/marketplace-k8s-app-tools/scripts/start.sh \
   --deployer=$DEPLOYER_IMAGE \
   --parameters='{"name":"'$APP_INSTANCE_NAME'","namespace":"default","coreServers":"3", "cpuRequest":"100m", "memoryRequest": "1Gi", "volumeSize": "2Gi", 
   "readReplicaServers":"1", "image": "gcr.io/neo4j-k8s-marketplace-public/causal-cluster:'$SOLUTION_VERSION'"}'
```

Once deployed, the instructions above on getting logs and running cypher-shell still apply.

To stop/delete, assuming that the generated name was `neo4j-qy7n`:

```
export MY_APP=neo4j-qy7n
kubectl delete application/$MY_APP
```

## Running Tests

- Build the test conainer `make app/build-test`
- Run tests

```
make app/verify
```

That app/verify target, like many others, is provided for by Google's
marketplace tools repo; consult app.Makefile in that repo for full details. 
Behind the scenes, it invokes `driver.sh` to deploy, wait for successful deploy,
and launch the testing container.

Actual test contents are specified by the resources in `tester.yaml` in the apptest directory.

## How to run Backups

- `make app/backup` to build the relevant docker container
- Customize `backup/backup.yaml` as appropriate
- kubectl apply -f backup/backup.yaml

For further details, consult the README file in the backup directory.

## Running from your Local Machine

These instructions mimic what the deployment container does.

### Helm Expansion

```
helm template chart/ \
   --set namespace=default \
   --set image=gcr.io/neo4j-k8s-marketplace-public/causal-cluster:3.4 \
   --set name=my-graph \
   --set neo4jPassword=mySecretPassword \
   --set authEnabled=true \
   --set coreServers=3 \
   --set readReplicaServers=0 \
   --set cpuRequest=200m \
   --set memoryRequest=1Gi \
   --set volumeSize=2Gi \
   --set acceptLicenseAgreement=yes > expanded.yaml
```

### Applying to Cluster (Manual)

```kubectl apply -f expanded.yaml```

### Discovering the Password to your Cluster

It's stored in a secret, base64 encoded.  With proper access you can unmask the password
like this:

```
kubectl get secrets $APP_INSTANCE_NAME-neo4j-secrets -o yaml | grep neo4j-password: | sed 's/.*neo4j-password: *//' | base64 --decode
```

### Connecting to an Instance

```
# Assumes APP_INSTANCE_NAME, SOLUTION_VERSION are set.
# When deploying from the marketplace, if you deploy as "mygraph",
# then you will have a corresponding application/mygraph

kubectl run -it --rm cypher-shell \
   --image=gcr.io/neo4j-k8s-marketplace-public/causal-cluster:$SOLUTION_VERSION \
   --restart=Never \
   --namespace=default \
   --command -- ./bin/cypher-shell -u neo4j \
   -p "$(kubectl get secrets $APP_INSTANCE_NAME-neo4j-secrets -o yaml | grep neo4j-password: | sed 's/.*neo4j-password: *//' | base64 --decode)" \
   -a $APP_INSTANCE_NAME-neo4j.default.svc.cluster.local "call dbms.cluster.overview()"
```

### Getting Logs

```
kubectl logs -l "app=neo4j,component=core"
```

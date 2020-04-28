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

## Setting up Tooling

```
$ gcloud config set project neo4j-k8s-marketplace-public
```

Then, install mpdev following [these instructions](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/mpdev-references.md)

Then:

```
export REGISTRY=gcr.io/$(gcloud config get-value project | tr ':' '/')
```

Registry will end up being `gcr.io/neo4j-k8s-marketplace-public` which is where our containers go.

## Overview

The solution is composed of two core containers:
- The deployment container, which expands the helm chart and applies resources to a running k8s cluster See the `deployer` and `chart` directories.
- The test container, which is layered on top of the deploy container and runs functional tests to ensure a working neo4j cluster.  See the `apptest` directory.
- A set of solution containers deployed under the neo4j GCR. The primary solution container shares the name with the solution (causal cluster)
and tracks the 4.0 release series, but is not versioned more specifically than that.  See the `causal-cluster` directory.

## Building All Containers and Pushing them to the Staging Repo
 
```
make app/build
```

## Running the Deployer Container to test deploy the solution

Adjust parameters as needed / necessary, and take note of the tags for versioning.  But what this is doing is
running the deployer container, and telling it to deploy a cluster of 3 cores, 1 RR of the "solution containers".

```
# This assumes APP_INSTANCE_NAME=testdeploy and SOLUTION_VERSION=4.0
$ mpdev install \
      --deployer=gcr.io/neo4j-k8s-marketplace-public/causal-cluster/deployer:4.0 \
      --parameters='{"name": "testdeploy", "namespace": "default", "image":"gcr.io/neo4j-k8s-marketplace-public/causal-cluster:4.0","coreServers":"3","readReplicaServers":"1"}'
```

## Running the Deployer Container (Old Method Relying on Google Marketplace Utils)

I'm keeping these instructions here for now but we should probably be using mpdev above.

Using the marketplace-k8s-app-tools script to launch the deployment container mimics how google's
k8s marketplace does it with the UI.

The make task `make app/install` accomplishes this, below is a variant with what that does:

```
SOLUTION_VERSION=$(cat chart/Chart.yaml | grep version: | sed 's/.*: //g')
DEPLOYER_IMAGE=gcr.io/neo4j-k8s-marketplace-public/causal-cluster/deployer:$SOLUTION_VERSION
APP_INSTANCE_NAME="neo4j-a$(head -c 2 /dev/urandom | base64 - | sed 's/[^A-Za-z0-9]/x/g' | tr '[:upper:]' '[:lower:]')"
vendor/marketplace-k8s-app-tools/scripts/start.sh \
   --deployer=$DEPLOYER_IMAGE \
   --parameters='{"name":"'$APP_INSTANCE_NAME'","namespace":"default","coreServers":"3", "cpuRequest":"100m", "memoryRequest": "1Gi", "volumeSize": "20Gi", 
   "readReplicaServers":"1", "image": "gcr.io/neo4j-k8s-marketplace-public/causal-cluster:'$SOLUTION_VERSION'"}'
```

Once deployed, the instructions above on getting logs and running cypher-shell still apply.

## Deleting a Running Instance of Causal Cluster

Given that a causal cluster is deployed as $APP_INSTANCE_NAME

```
kubectl delete application/$APP_INSTANCE_NAME
```

## How these Containers Work

Two key bits, the "solution container" and the "deployer container".

The solution container is basically just Neo4j's regular docker image,
with a few things layered on top of it like cloud tools and license 
information to satisfy Google Marketplace requirements.  

The deployer container is based on a Google container that knows how to
deploy helm charts and run tests on Marketplace solutions.   The helm chart
it deploys, which arranges the solution container in the right topology, is in
the `chart` subdirectory.

The `deployer/Dockerfile` is very important because it assembles all of the bits and
puts things in the right locations, such as the helm chart under `/data` inside the
container and the testing artifacts inside of `/data-test`.  

The actual testing artifacts consist of some shell scripts that test a deployed
solution to make sure it's OK (`apptest/deployer/neo4j/templates/tester.yaml`) and
a "schema overlay" (`apptest/deployer/schema.yaml`).  The way the deploy container
works is that `mpdev` or the Makefile approach runs the deployer container in test
mode.   That deployer container deploys the actual solution, and then runs the test
artifacts.  The schema overlay dominates whatever properties were not defined in 
the solution schema.yaml file.  In this way, the testing approach can mimic user 
selections that might be made via the marketplace UI. 

## Running Tests (New Method)

```
mpdev verify \
    --deployer=gcr.io/neo4j-k8s-marketplace-public/causal-cluster/deployer:4.0 >VERIFY.log 2>&1
```

I like to save the verify logs because the output is so huge.  If something goes wrong
it's easier to capture it and look back through the log.

What this command does is to run the deployer container, which deploys the solution
containers, waits for everything to come live (pods in ready status) and then runs
the test resources following the "schema overlay" approach described above.

The testing process is simple: if the test resources exit with code 0, you're good.
If they exit with any other code, your tests failed.

## Running Tests  (Old Method)

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
DEPLOY_ID=$(head -c 10 /dev/urandom | md5 | head -c 5)
SOLUTION_VERSION=4.0
IMAGE=gcr.io/neo4j-k8s-marketplace-public/causal-cluster:$SOLUTION_VERSION
APP_INSTANCE_NAME=deploy-$DEPLOY_ID
CLUSTER_PASSWORD=mySecretPassword
CORES=3
READ_REPLICAS=0
CPU_REQUEST=200m
MEMORY_REQUEST=1Gi
CPU_LIMIT=2
MEMORY_LIMIT=4Gi
VOLUME_SIZE=4Gi
STORAGE_CLASS_NAME=standard

helm template chart/ --name $APP_INSTANCE_NAME \
   --set namespace=default \
   --set image=$IMAGE \
   --set name=$APP_INSTANCE_NAME \
   --set neo4jPassword=$CLUSTER_PASSWORD \
   --set authEnabled=true \
   --set coreServers=$CORES \
   --set readReplicaServers=$READ_REPLICAS \
   --set cpuRequest=$CPU_REQUEST \
   --set memoryRequest=$MEMORY_REQUEST \
   --set cpuLimit=$CPU_LIMIT \
   --set memoryLimit=$MEMORY_LIMIT \
   --set volumeSize=$VOLUME_SIZE \
   --set volumeStorageClass=$STORAGE_CLASS_NAME \
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
   --image=gcr.io/cloud-marketplace/neo4j-public/causal-cluster-k8s:$SOLUTION_VERSION \
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

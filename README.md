# neo4j-google-k8s-marketplace

This repository contains instructions and files necessary for running Neo4j Enterprise via Google's
Hosted Kubernetes Marketplace.

# Getting started

## Updating git submodules

You can run the following commands to make sure submodules
are populated with proper code.

```shell
git submodule sync --recursive
git submodule update --recursive --init --force
```

## Setting up the GKE environment

See `setup-k8s.sh` for instructions.

## Building the Deployment Container

```
make app/build
```

## Running from your Local Machine

These instructions mimic what the deployment container does.

### Helm Expansion

helm template chart/ \
   --set NAMESPACE=default \
   --set reportingSecret=XYZ \
   --set image=gcr.io/neo4j-k8s-marketplace-public/neo4j:3.3.5-enterprise \
   --set name=mygraph \
   --set APP_INSTANCE_NAME=mygraph \
   --set neo4jPassword=mySecretPassword \
   --set authEnabled=true \
   --set coreServers=3 \
   --set acceptLicenseAgreement=yes > expanded.yaml

### Applying to Cluster

```kubectl apply -f expanded.yaml```

### Discovering the Password to your Cluster

It's stored in a secret, base64 encoded.  With proper access you can unmask the password
like this:

```
kubectl get secrets $APP_INSTANCE_NAME-neo4j-secrets -o yaml | grep neo4j-password: | sed 's/neo4j-password: *//' | base64 -D
```

### Connecting to an Instance

```
export APP_INSTANCE_NAME=mygraph

kubectl run -it --rm cypher-shell \
   --image=gcr.io/neo4j-k8s-marketplace-public/neo4j:3.3.5-enterprise \
   --restart=Never \
   --namespace=default \
   --command -- ./bin/cypher-shell -u neo4j \
   -p "$(kubectl get secrets $APP_INSTANCE_NAME-neo4j-secrets -o yaml | grep neo4j-password: | sed 's/neo4j-password: *//' | base64 -D)" \
   -a $APP_INSTANCE_NAME-neo4j.default.svc.cluster.local "call dbms.cluster.overview()"
```

### Getting Logs
```
kubectl logs -l "app=neo4j,component=core"
```

## Running the Deployer Container

Using the marketplace-k8s-app-tools script to launch the deployment container mimics how google's
k8s marketplace will do it live.

```
DEPLOYER_IMAGE=gcr.io/neo4j-k8s-marketplace-public/neo4j-deployer:latest
APP_INSTANCE_NAME="neo4j-$(head -c 3 /dev/urandom | base64 - | sed 's/[^A-Za-z0-9]/x/g' | tr '[:upper:]' '[:lower:]')"
vendor/marketplace-k8s-app-tools/scripts/start.sh \
   --deployer=$DEPLOYER_IMAGE \
   --parameters='{"NAMESPACE": "default", "APP_INSTANCE_NAME": "'$APP_INSTANCE_NAME'", "coreServers":"3", "cpu":"500m", "mem": "3Gi", "volumeSize": "7Gi", "volumeStorageClass":"pd-ssd", "readReplicaServers":"0", "reportingSecret": "XYZ", "image": "gcr.io/neo4j-k8s-marketplace-public/neo4j:3.3.5-enterprise"}'
```

Once deployed, the instructions above on getting logs and running cypher-shell still apply.

## Running Tests

- Build the test conainer `make app/build-test`
- Run tests

```
vendor/marketplace-k8s-app-tools/scripts/start_test.sh \
   --marketplace_tools=vendor/marketplace-k8s-app-tools \
   --deployer=gcr.io/neo4j-k8s-marketplace-public/neo4j-tester:latest \
   --test_parameters='{"foo":"6","bar":"7"}' \
   --parameters='{"APP_TESTER_IMAGE":"gcr.io/neo4j-k8s-marketplace-public/neo4j-tester:latest","APP_INSTANCE_NAME":"foo","NAMESPACE":"default"}'
```

# User Guide

## Overview

General application overview, covering basic functions and configuration options. This section
must also link to the published Cloud Launcher solution URL.

## One time Setup

- Configuring client tools
- Installing the Application CRD
- Acquiring and installing a license Secret from Cloud Launcher (if applicable)

## Installation

- Commands for installing the application
- Passing parameters available in UI configuration
- Pinning image references to immutable digests

## Basic Usage

- Connecting to an admin console (if applicable)
- Connecting a client tool and running a sample command (if acclipable)
- Modifying usernames and passwords
- Enabling ingress and installing TLS certs (if applicable)

## Backup and Restore

- Backing up application state
- Restoring application state from a backup

## Image Updates

Updating application images, assuming patch/minor updates

## Scaling

Scaling the application (if applicable)



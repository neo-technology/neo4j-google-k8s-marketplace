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

## Building the Deployment Container

```
make app/build
```

## Local Testing

These instructions mimic what the deployment container does.

### Helm Expansion

helm template chart/ \
   --set NAMESPACE=default \
   --set APP_INSTANCE_NAME=mygraph \
   --set neo4jPassword=mySecretPassword \
   --set authEnabled=true \
   --set coreServers=3 \
   --set readReplicaServers=0 \
   --set acceptLicenseAgreement=yes > expanded.yaml

### Applying to Cluster

```kubectl apply -f expanded.yaml```

### Connecting to an Instance

```
export PASSWORD=mySecretPassword
export APP_INSTANCE_NAME=mygraph
kubectl run -it --rm cypher-shell \
   --image=gcr.io/neo4j-k8s-marketplace-public/neo4j:3.3.5-enterprise \
   --restart=Never \
   --namespace=default \
   --command -- ./bin/cypher-shell -u neo4j \
   -p "$PASSWORD" \
   -a $APP_INSTANCE_NAME-neo4j.default.svc.cluster.local "call dbms.cluster.overview()"
```

## Running the Deployer Container

Using the marketplace-k8s-app-tools script to launch the deployment container mimics how google's
k8s marketplace will do it live.

```
DEPLOYER_IMAGE=gcr.io/neo4j-k8s-marketplace-public/neo4j-deployer:latest
vendor/marketplace-k8s-app-tools/scripts/start.sh \
   --deployer=$DEPLOYER_IMAGE \
   --parameters='{"acceptLicenseAgreement":"yes", "NAMESPACE": "default", "APP_INSTANCE_NAME": "myneo4j", "core.numberOfServers":"4", "reportingSecret": "XYZ", "image": "gcr.io/neo4j-k8s-marketplace-public/neo4j:3.3.5-enterprise"}'
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



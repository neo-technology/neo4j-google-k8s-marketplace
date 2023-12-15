#!/bin/bash
#
# This script is intended to be used for internal testing only, to create the artifacts necessary for
# testing and deploying this code in a sample GKE cluster.
PROJECT=neo4j-k8s-marketplace-public
ZONE=us-east1-b
CLUSTER_PREFIX=${CLUSTER_PREFIX:-lab}

# Deleting the GKE cluster
gcloud container clusters delete $CLUSTER_PREFIX \
  --zone $ZONE \
  --project $PROJECT \
  --quiet

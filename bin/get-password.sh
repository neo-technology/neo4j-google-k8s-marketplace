#!/bin/bash
APP_INSTANCE_NAME=$1
kubectl get secrets $APP_INSTANCE_NAME-neo4j-secrets -o yaml | grep neo4j-password: | sed 's/.*neo4j-password: *//' | base64 --decode

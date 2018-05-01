# Deployment Container

This container deploys an instance of the neo4j helm chart to a k8s cluster on google.

# Usage

```
SERVICE_ACCOUNT=~/.google/neo4j-k8s-marketplace-public-e1dffd5975c8.json
docker run \
   -e GCLOUD_PROJECT=neo4j-k8s-marketplace-public \
   -e GKE_CLUSTER=lab \
   -e ZONE=us-central1-a \
   -e GCLOUD_SERVICE_KEY_BASE64=$(base64 $SERVICE_ACCOUNT) \
   neo4j-deploy:latest
```
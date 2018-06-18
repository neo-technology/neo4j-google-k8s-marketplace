# Google Kubernetes Marketplace

This directory contains artifacts necessary for publishing neo4j as part of Google's Kubernetes Marketplace.

The corresponding google project where all artifacts are stored is:
https://console.cloud.google.com/gcr/images/neo4j-k8s-marketplace-public/

# Pushing Docker Images

Build the [UBB agent](https://github.com/GoogleCloudPlatform/ubbagent) as a
docker container, and then push that.

```
git submodule sync --recursive
cd vendor/ubbagent
docker build -t gcr.io/neo4j-k8s-marketplace-public/ubbagent:neo4j
gcloud docker -- push gcr.io/neo4j-k8s-marketplace-public/ubbagent:neo4j
```

Test Image for Helm:

```
docker pull dduportal/bats:0.4.0
docker tag dduportal/bats:0.4.0 gcr.io/neo4j-k8s-marketplace-public/dduportal/bats:0.4.0
gcloud docker -- push gcr.io/neo4j-k8s-marketplace-public/dduportal/bats:0.4.0

docker pull markhneedham/k8s-kubectl:master
docker tag markhneedham/k8s-kubectl:master gcr.io/neo4j-k8s-marketplace-public/markneedham/k8s-kubectl:master
gcloud docker -- push gcr.io/neo4j-k8s-marketplace-public/markneedham/k8s-kubectl:master
```

(As of this writing ubbagent is under development, additional steps may be
necessary) 

# Questions?

Contact David Allen <david.allen@neo4j.com>

# Relevant Documentation

Consult the partnering tech folder for Google on Google Drive.  Periodic documentation provided by Google is hosted there.

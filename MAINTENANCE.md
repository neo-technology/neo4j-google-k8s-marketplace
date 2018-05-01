# Google Kubernetes Marketplace

This directory contains artifacts necessary for publishing neo4j as part of Google's Kubernetes Marketplace.

Files for running it in k8s will be kept in a separate repo TBD that needs to be public. These files are only 
for the non-public aspects of maintaining the listing, and keeping instructions and so on.

The corresponding google project where all artifacts are stored is:
https://console.cloud.google.com/gcr/images/neo4j-k8s-marketplace-public/

# Pushing Docker Images

```
docker pull neo4j:3.3.5-enterprise
docker tag neo4j:3.3.5-enterprise gcr.io/neo4j-k8s-marketplace-public/neo4j:3.3.5-enterprise
gcloud docker -- push gcr.io/neo4j-k8s-marketplace-public/neo4j:3.3.5-enterprise
```

Build the [UBB agent](https://github.com/GoogleCloudPlatform/ubbagent) as a
docker container, and then push that.

```
git clone https://github.com/GoogleCloudPlatform/ubbagent
cd ubbagent
docker build -t gcr.io/neo4j-k8s-marketplace-public/ubbagent:neo4j
gcloud docker -- push gcr.io/neo4j-k8s-marketplace-public/ubbagent:neo4j
```

Test Image for Helm:

```
docker pull markhneedham/k8s-kubectl:master
docker tag markhneedham/k8s-kubectl:master gcr.io/neo4j-k8s-marketplace-public/markneedham/k8s-kubectl:master
gcloud docker -- push gcr.io/neo4j-k8s-marketplace-public/markneedham/k8s-kubectl:master
```

(As of this writing ubbagent is under development, additional steps may be
necessary) 

# Questions?

Contact David Allen <david.allen@neo4j.com> for access to API keys, materials, or anything else you might need.

# Relevant Documentation

Consult the partnering tech folder for Google on Google Drive.  Periodic documentation provided by Google is hosted there.

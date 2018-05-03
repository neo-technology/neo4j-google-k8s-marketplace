# Adapted from https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/tree/master/marketplace/deployer_helm_base
FROM launcher.gcr.io/google/debian9

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    gettext \
    jq \
    python \
    python-yaml \
    wget \
    git-all \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /bin/kubectl \
        https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl \
    && chmod 755 /bin/kubectl

RUN mkdir -p /bin/helm-downloaded \
    && wget -q -O /bin/helm-downloaded/helm.tar.gz \
        https://storage.googleapis.com/kubernetes-helm/helm-v2.8.1-linux-amd64.tar.gz \
    && tar -zxvf /bin/helm-downloaded/helm.tar.gz -C /bin/helm-downloaded \
    && mv /bin/helm-downloaded/linux-amd64/helm /bin/ \
    && rm -rf /bin/helm-downloaded

COPY vendor/marketplace-k8s-app-tools/marketplace/deployer_helm_base/* /bin/
COPY vendor/marketplace-k8s-app-tools/marketplace/deployer_util/* /bin/

RUN mkdir -p /data/chart
RUN mkdir -p /data-test/chart

# Neo4j customizations below
WORKDIR /data

RUN git clone https://github.com/moxious/charts.git

WORKDIR /bin
COPY neo4j-deployer/schema.yml /data/schema.yml
COPY neo4j-deployer/deploy.sh /bin/deploy.sh
RUN chmod +x /bin/deploy.sh

# TBD: https://github.com/baptiste-bonnaudet/gcloud-kubectl/blob/master/run.sh
ENTRYPOINT ["/bin/bash", "/bin/deploy.sh"]
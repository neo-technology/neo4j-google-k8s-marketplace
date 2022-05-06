# Neo4j on Google Kubernetes Engine User Guide

## Overview

Neo4j on GKE allows users to deploy multi-node Neo4j Enterprise Causal Clusters to GKE instances, with configuration options for the most common scenarios.  It represents a very rapid way to get started running the world leading native graph database on top of Kubernetes.

This guide is intended only as a supplement to the [Neo4j Operations Manual](https://neo4j.com/docs/operations-manual/4.4/?ref=googlemarketplace).   Neo4j on GKE is essentially a docker container based deploy of Neo4j Causal Cluster.  As such, all of the information in the Operations Manual applies to its operation, and this guide will focus only on kubernetes-specific concerns and GKE-specific concerns.

## Licensing & Cost

Neo4j on GKE is available to any existing enterprise license holder of Neo4j in a Bring Your Own License (BYOL) arrangement.  Neo4j on GKE is also available under evaluation licenses, contact Neo4j in order to obtain one.   There is no hourly or metered cost associated with using Neo4j on GKE for current license holders; you will pay only for the google compute infrastructure necessary to run the software.

## One time Setup

Before installing Neo4j into your GKE cluster, confirm the following:
- You should have docker and kubectl installed locally from the machine where you want to use neo4j
- You have authenticated google’s CLI tools (gcloud) locally to your account.
- You have run gcloud container clusters get-credentials to configure your local kubectl client to interact with your GKE cluster.
- You should verify that you hold an existing Neo4j Enterprise license, whether purchased, via the startup program, or on an evaluation basis.

## Installation

The standard installation flow for Neo4j on GCP Marketplace is to simply follow the prompts, and fill out the following configuration options, which are described below.

### Key Configuration Options

The following lists relevant configuration options for the deploy.  Only the name is strictly required, but users are strongly encouraged to consult [Neo4j’s System Requirements](https://neo4j.com/docs/operations-manual/current/installation/requirements/?ref=googlemarketplace) and to tailor CPU, memory, and disk to the anticipated workload that will be used, in order to ensure best performance.

* **name**:  the name of your cluster deployment
* **coreServers**: (default: 3) the number of core servers in your cluster ([refer to Neo4j Causal Cluster architecture](https://neo4j.com/docs/operations-manual/current/clustering/introduction/?ref=googlemarketplace)).  Core Servers' main responsibility is to safeguard data. The Core Servers do so by replicating all transactions using the Raft protocol.  This setting can be set to 1, which
will result in a single neo4j instance ([dbms.mode=SINGLE](https://neo4j.com/docs/operations-manual/current/reference/configuration-settings/#config_dbms.mode)).  Additional notes: if a single instance is chosen, it cannot be scaled up and down.  A core server count of 2 is not recommended or a sensible HA cluster sizing.
* **readReplicaServers**: (default: 0) the number of read replicas in your cluster ([refer to Neo4j Causal Cluster architecture](https://neo4j.com/docs/operations-manual/current/clustering/introduction/?ref=googlemarketplace)).  Read Replicas' main responsibility is to scale out graph workloads (Cypher queries, procedures, and so on). Read Replicas act like caches for the data that the Core Servers safeguard, but they are not simple key-value caches. In fact Read Replicas are fully-fledged Neo4j databases capable of fulfilling arbitrary (read-only) graph queries and procedures.  If coreServers is less than or equal to 2, this setting is ignored and 0 replicas will result.
* **cpuRequest**: CPU units to allocate to each pod.  Refer to [Managing computing resources on Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu)
* **memoryRequest**: Memory to allocate to each pod.
* **cpuLimit**: CPU unit limit per pod
* **memoryLimit**: Memory limit per pod
* **volumeSize**:  Disk allocation to core nodes, for example “2Gi”

### Hardware Allocation

In order to ensure that Neo4j is deployable on basic/default GKE clusters, the default values for hardware requests have been made fairly low, and can be found in [schema.yaml](../schema.yaml).  The initial request is a fraction of a CPU per node, with 512MB of memory.  By default, the CPU upper limit is 8, and memory limit 512GB, which can be adjusted. 

Sizing databases is ultimately something that should be done with the workload in mind.
Consult Neo4j's [Performance Tuning Documentation](https://neo4j.com/developer/guide-performance-tuning/?ref=googlemarketplace) for more information.  In general,
heap size and page cache sizing are the most important places to start when tuning performance.

### Cluster Formation

Immediately after deploying Neo4j on GKE, as the pods are created the cluster begins to form.  This may take up to 5 minutes, depending on a number of factors including how long it takes pods to get scheduled, and how many resources are associated with the pods.  While the cluster is forming, the Neo4j REST API and Bolt endpoints may not be available.   After a few minutes, bolt endpoints become available inside of the kubernetes cluster.  Please note that by default, Neo4j services are not
exposed externally.  See below for information on proxying and other limitations.

### Generated Password

After installing from GCP Marketplace, your cluster will start with a strong password that was randomly generated in the startup process.   This is stored in a kubernetes secret that is attached to your deployment.   Given a deployment named “my-graph”, you can find the password as the “neo4j-password” key under the mygraph-neo4j-secrets configuration item in Kubernetes.   The password is base64 encoded, and can be recovered as plaintext by authorized users with this command:

```
kubectl get secrets $APP_INSTANCE_NAME-neo4j-secrets -o yaml | grep neo4j-password: | sed 's/.*neo4j-password: *//' | base64 --decode
```

This password applies for the base administrative user named “neo4j”.

### Hostnames

All neo4j cluster nodes inside of GKE will get private DNS names that you can use to access them.  Host names will be generated as follows.   `$NAMESPACE` refers to the kubernetes namespace used to deploy neo4j, and `$APP_INSTANCE_NAME` refers to the name it was deployed under.  The variable `$N` refers to the individual cluster node.  For clusters with 3 core nodes, $N could be 0, 1, or 2, and a total of three hostnames will be valid.

- Core Host:  `$APP_INSTANCE_NAME-neo4j-core-$N.$APP_INSTANCE_NAME-neo4j.$NAMESPACE.svc.cluster.local`
- Read Replica Host: `$APP_INSTANCE_NAME-neo4j-replica-$N.neo4j-replica.$NAMESPACE.svc.cluster.local`

### Exposed Services

By default, each node will expose:
- HTTP on port 7474
- HTTPS on port 7473
- Bolt on port 7687

Exposed services and port mappings can be configured by referencing neo4j’s docker documentation.   See the advanced configuration section in this document for how to change the way the docker containers in each pod are configured.

### Service Address

Additionally, a service address inside of the cluster will be available as follows - to determine your service address, simply substitute $APP_INSTANCE_NAME with the name you deployed neo4j under, and $NAMESPACE with the kubernetes namespace where neo4j resides.

`$APP_INSTANCE_NAME-neo4j.$NAMESPACE.svc.cluster.local`

Any client may connect to this address, as it is a DNS record with multiple entries pointing to the nodes which back the cluster.  For example, bolt+routing clients can use this address to bootstrap their connection into the cluster, subject to the items in the limitations section.

## Manual Installation without Google Marketplace

The deployment package is structured as a helm chart; to avoid the need for installation of helm users and other objects into Kubernetes such as tiller, helm is essentially used as a template engine.  As a result, so install Neo4j into an existing k8s cluster, we use helm to expand the chart, and then simply apply the result using kubectl.

Consult the README.md at the top of the github repository for instructions on how to use helm to expand the chart, and apply that manually to your kubernetes cluster.  Broadly, the process is to expand the helm chart into a single large template of resources, and then simply apply those resources to your cluster using `kubectl apply`.

## Usage

### Cypher Shell
To connect to your cluster, you can issue the following command; modify APP_INSTANCE_NAME to be the name you chose when you deployed neo4j.

```
APP_INSTANCE_NAME=my-graph
# Set password as described above in NEO4J_PASSWORD
kubectl run -it --rm cypher-shell \
  --image=gcr.io/cloud-marketplace/neo4j-public/causal-cluster-k8s:4.4 \
  --restart=Never \
  --namespace=default \
  --command -- ./bin/cypher-shell -u neo4j \
  -p "$NEO4J_PASSWORD" \
  -a $APP_INSTANCE_NAME-neo4j.default.svc.cluster.local
```

Please consult standard Neo4j documentation on the many other usage options present, once you have a basic bolt client and cypher shell capability.

### Neo4j Browser

Neo4j browser is available on port 7474 of any of the hostnames described above.  However, because of the network environment that the cluster is in, hosts in the neo4j cluster advertise themselves with private internal DNS that is not resolvable from outside of the cluster.  See the “Security” and “Limitations” sections in this document for a discussion of the issues there, and for pointers on how you can configure your database with your organization’s DNS entries to enable this access.

Browser access can be enabled with the following steps.

#### Determine your Cluster Leader

When the cluster forms, one node will be chosen as the leader; in Neo4j's topology, only the leader
may accept writes.  To determine which host is the leader, you can run the cypher-shell command given above, and simply call the cypher procedure:  `CALL dbms.cluster.overview();`.  This will provide a routing table indicating which host (and pod) is the leader.

If you only want to run read queries, it makes no difference which pod you attach to.

#### Forward local ports

First, use [kubectl to forward ports](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) on your cluster's leader pod to your localhost.

```
MY_CLUSTER_LEADER_POD=mygraph-neo4j-core-0
kubectl port-forward $MY_CLUSTER_LEADER_POD 7687:7687 7474:7474
```

In this example, my deployment is named "mygraph", and the "core-0" pod is the leader.  We are forwarding port 7474 for browser, and port 7687 for bolt access.

#### Connect to Browser

Open a browser to `http://localhost:7474` and you will be connecting directly to the cluster leader.

**Important**:  when launching Neo4j Browser, you will see a `:server connect` box, which will be configured to connect to the host's advertised name, which will be an internal DNS name.  Make sure to change this to `localhost`, because the private DNS name is not resolveable from your local machine.

Use your username and password as normal.

Becuase you're connecting to the leader, both reads and writes are possible.  The same approach can be used to attach a browser instance on any local port to any of your pods.

### Adding Users, Changing Passwords

Once connected via a cypher shell, you may use any of the existing procedures for user and role management provided as part of neo4j.
Advanced/Custom Configuration of Neo4j

The deploy for GKE is based on Neo4j’s public docker containers.  This means that [Neo4j documentation for Docker](https://neo4j.com/docs/operations-manual/current/installation/docker/?ref=googlemarketplace) applies to the configuration of these pods.   In general, to specify an advanced configuration, users should edit the core-statefulset template, and the readreplicas-statefulset template to specify environment variables passed to the Docker containers following the guidance of the Docker documentation listed above.

For example, to enable query logging in Neo4j, a user would need to set dbms.logs.query.enabled=true inside of the container.   To do that, a user would add the following environment variable `NEO4J_dbms_logs_query_enabled=true` to the relevant templates; these environment variables would be passed through to the docker container, which would configure neo4j appropriately.

### Backup

Provided with this distribution is a method of backing up a neo4j instance to Google Cloud Storage (GCS).  In the code repository, you can consult the documentation in the backup directory on how to use this container to take an active backup and save that data to GCS.  To do this, you will need to create a storage bucket, and create a service account with permissions on that storage bucket.   Backup may be run against a running cluster.

For full details on all aspects of Backup and Restore, please consult the [Neo4j documentation on backups](https://neo4j.com/docs/operations-manual/current/backup/?ref=googlemarketplace).

### Restore

This repo contains a restore directory with a container that can restore a Neo4j backup
to the pod before it starts.  Generally the restore runs as an initContainer.  You will
need a backup set stored in google storage, and a service key with access to the
relevant bucket.

### Image Updates

This version of Neo4j on GKE tracks the 4.4 release series of Neo4j.  As such, periodic updates may be provided which will increase the patch level release that is underlying causal cluster, but at no time will any non-backwards compatible image updates be introduced.

## Scaling

### Planning

Before scaling a database running on kubernetes, make sure to consult in depth the Neo4j documentation on clustering architecture, and in particular take care to choose carefully between whether you want to add core nodes or read replicas.  Additionally, this planning process should take care to include details of the kubernetes layer, and where the node pools reside.  Adding extra core nodes to protect data with additional redundancy may not provide extra guarantees if all kubernetes nodes are in the same zone, for example.

For many users and use cases, careful planning on initial database sizing is preferable to later attempts to rapidly scale the cluster.

When adding new nodes to a neo4j cluster, upon the node joining the cluster, it will need to replicate the existing data from the other nodes in the cluster.  As a result, this can create a temporary higher load on the remaining nodes as they replicate data to the new member.   In the case of very large databases, this can cause temporary unavailability under heavy loads.  We recommend
that when setting up a scalable instance of Neo4j, you configure pods to restore from a recent
backup set before starting.  Instructions on how to restore are provided in this repo.  In this way,
new pods are mostly caught up before entering the cluster, and the "catch-up" process is minimal both
in terms of time spent and load placed on the rest of the cluster.

Because of the data intensive nature of any database, careful planning before scaling is highly recommended.   Storage allocation for each new node is also needed; as a result, when scaling the database, the kubernetes cluster will create new persistent volume claims and GCE volumes.

Because Neo4j's configuration is different in single-node mode (dbms.mode=SINGLE) you should not
scale a deployment if it was initially set to 1 coreServer.  This will result in multiple independent
databases, not one cluster.

### Execution
Neo4j on GKE consists of two StatefulSets in Kubernetes, one for core nodes, and one for replicas.  In configuration, even if you chose zero replicas, you will see a StatefulSet with zero members.

Scaling the database is a matter of scaling one of these stateful sets.  In this example, we will add a read replica to a cluster that has 1 existing replica.

- Choose “Workloads” from the GKE menu
- Select the replica StatefulSet, which will be named $APP_INSTANCE_NAME-neo4j-replica
- Click the “Scale” button on the top toolbar
- You will be given a dialog showing at current 1 replica (in this scenario).   Change it to 2, and click the “Scale” button.
- This kicks off the process of scheduling a new pod into this replica set.   The pod will be pre-configured to connect to the rest of the cluster, so no further action is needed.

Depending on the size of your database and how busy the other members are, it may take considerable time for the cluster topology to show the presence of the new member, as it connects to the cluster and performs catch-up.
Once the new node is caught up, you can execute the cypher query CALL dbms.cluster.overview(); to verify that the new node is operational.

### Warnings and Indications

Scaled pods inherit their configuration from their statefulset.  For neo4j, this means that items like configured storage size, hardware limits, and passwords apply to scale up members.

If scaling down, do not scale below three core nodes; this is the minimum necessary to guarantee a properly functioning cluster with data redundancy.   Consult the neo4j clustering documentation for more information.
Neo4j on GKE is configured to never delete the backing data drive, to lessen the chance of inadvertent data destruction.   If you scale up and then later scale down, this may orphan a GCE disk, which you may want to manually delete at a later date.

## Security

For security reasons, we have not enabled access to the database cluster from outside of Kubernetes by default, instead choosing to leave this to users to configure appropriate network access policies for their usage.  If this is desired, we recommend exposing each pod individually, and not using a load balancer service across all pods, because neo4j’s cluster architecture differentiates between the leader and followers; not all pods may be treated interchangeably as a result.

## Limitations

At present, bolt+routing drivers which attempt to connect to the cluster from outside of Kubernetes will not function as expected.  Bolt+routing can be used from within the cluster though.  The reason for this has to do with network address translation between the private DNS addresses of the database nodes inside the cluster, and the inability for external clients to resolve those addresses.

If your use case requires the need to access neo4j with bolt+routing from outside of Kubernetes, we recommend that you assign externally valid DNS to each of your nodes, and then configure the nodes to advertise that external DNS.  In this way, bolt+routing from outside of kubernetes can be made to work, after configuring ingresses to permit network traffic to enter the cluster.

Exposing each individual pod to a distinct external port is another option, but users who take this “port spreading” approach should be careful to keep in mind the cluster topology; i.e. only the cluster leader may accept writes, but any bolt endpoint may be used to spread out read queries.

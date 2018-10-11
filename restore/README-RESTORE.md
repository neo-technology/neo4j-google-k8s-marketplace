# Restoring Neo4j Containers

This directory contains files necessary for restoring Neo4j Docker containers
from google storage, or local files placed on the volume.

## Approach

The restore container is used as an `initContainer` in the main cluster.  Prior to
a node in the Neo4j cluster starting, the restore container copies down the backup
set, and restores it into place.  When the initContainer terminates, the regular
Neo4j docker instance starts, and picks up where the backup left off.

This container is primarily tested against the backup .tar.gz archives produced by
the `backup` container in this same code repository.  We recommend you use that approach.  If you tar/gz your own backups using a different approach, be careful to
inspect the `restore.sh` script, because it needs to make certain assumptions about
directory structure that come out of archived backups in order to restore properly.

## Using the Restore Container

Code for the restore container can be found in this directory, and can be built as
a docker container directly, and pushed to any registry as needed.

### Create a service key secret to access cloud storage

First you want to create a kubernetes secret that contains the content of your account service key.  This key must have permissions to access the bucket and backup set that you're trying to restore. 

```
MY_SERVICE_ACCOUNT_KEY=$HOME/.google/my-service-key.json
kubectl create secret generic restore-service-key \
   --from-file=credentials.json=$MY_SERVICE_ACCOUNT_KEY
```

### Configure the initContainer for Core and Read Replica Nodes

Finally, specify the initContainer like this, in `values.yaml`.

Important:
* Ensure that the volume mount to /auth matches the secret name you created above.
* Ensure that your BUCKET, BACKUP_NAME, and GOOGLE_APPLICATION_CREDENTIALS are
set correctly given the way you created your secret.

```
coreInitContainers: 
   - name: restore-from-file
     image: gcr.io/neo4j-k8s-marketplace-public/causal-cluster/restore:3.4
     imagePullPolicy: Always
     volumeMounts:
     - name: datadir
       mountPath: /data
     - name: restore-service-key
       mountPath: /auth
     env:
     - name: BUCKET
       value: gs://my-google-storage-bucket
     - name: BACKUP_NAME
       value: my-backup-set.tar.gz
     - name: GOOGLE_APPLICATION_CREDENTIALS
       value: /auth/credentials.json
     - name: FORCE_OVERWRITE
       value: "false"
```

This snippet above creates the initContainer just for core nodes.  It's strongly recommended you do the same for `readReplicaInitContainers` if you are using read replicas. If you restore only to core nodes and not to read replicas, when they start
the core nodes will replicate the data to the read replicas.   This will work just fine, but may result in longer startup times and much more bandwidth.

## Parameters

- `GOOGLE_APPLICATION_CREDENTIALS` - path to a file with a JSON service account key (see credentials below)
- `BUCKET` the URL of the bucket, of the form `gs://my-bucket` where the backup set resides.
- `BACKUP_NAME` path to a file (or uncompressed directory) within the bucket that contains the backup files.  Example:  `mydata-backup-2018-09-01.tar.gz`
- `PURGE_ON_COMPLETE` (defaults to false/no).  If this is set to the value "true", the restore process will remove the restore artifacts from disk.  Otherwise, they
will be left in place.  This is useful for debugging restores, to see what was
copied down from cloud storage and how it was expanded.

The restore container can detect .tar.gz and .zip compressed backups and deal with them appropriately, as well as uncompressed directory backup sets.

## Optional Parameters

- `FORCE_OVERWRITE` if this is the value "true", then the restore process will overwrite and
destroy any existing data that is on the volume.  Take care when using this in combination with
persistent volumes.  The default is false; if data already exists on the drive, the restore operation will likely fail but preserve your data.

## Running the Restore

With the initContainer in place and properly configured, simply deploy a new cluster 
using the regular approach.  Prior to start, the restore will happen, and when the 
cluster comes live, it will be populated with the data.

## Ongoing Maintenance

In general we'd recommend taking regular full backups, and restoring from those.

## Limitations

- Container has not yet been tested with incremental backups
- For the time being, only google storage as a cloud storage option is implemented, 
but adapting this approach to S3 or other storage should be fairly straightforward with modifications to `restore.sh`

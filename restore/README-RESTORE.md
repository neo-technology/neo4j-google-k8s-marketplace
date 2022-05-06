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

### Create a service key secret to access cloud storage

First you want to create a kubernetes secret that contains the content of your account service key.  This key must have permissions to access the bucket and backup set that you're trying to restore. 

```
MY_SERVICE_ACCOUNT_KEY=$HOME/.google/my-service-key.json
kubectl create secret generic restore-service-key \
   --from-file=credentials.json=$MY_SERVICE_ACCOUNT_KEY
```

In `values.yaml`, then configure the secret you set here like so:

```
# maintenanceServiceKeySecret=restore-service-key
```

This setting allows the core and read replica nodes to access that service key
as a volume.  That volume being present within the containers is necessary for the
next step.

If this service key secret is not in place, the auth information will not be able to be mounted as
a volume in the initContainer, and your pods may get stuck/hung at "ContainerCreating" phase.

### Configure the initContainer for Core and Read Replica Nodes

Finally, specify the initContainer like this, in `values.yaml`.

Important:
* Ensure that the volume mount to /auth matches the secret name you created above.
* Ensure that your BUCKET, BACKUP_NAME, and GOOGLE_APPLICATION_CREDENTIALS are
set correctly given the way you created your secret.

```
coreInitContainers: 
   - name: restore-from-file
     image: gcr.io/neo4j-k8s-marketplace-public/causal-cluster/restore:4.4
     imagePullPolicy: Always
     volumeMounts:
     - name: datadir
       mountPath: /data
     - name: restore-service-key
       mountPath: /auth
     env:
     - name: REMOTE_BACKUPSET
       value: gs://my-google-storage-bucket/my-backupset.tar.gz
     - name: BACKUP_SET_DIR
       value: my-backup-set
     - name: GOOGLE_APPLICATION_CREDENTIALS
       value: /auth/credentials.json
     - name: FORCE_OVERWRITE
       value: "false"
```

Notice that we're mounting the secret at the `/auth` path and then passing our application credentials as a file within that path.  This is what permits shell tools to access your google cloud storage resources.

This snippet above creates the initContainer just for core nodes.  It's strongly recommended you do the same for `readReplicaInitContainers` if you are using read replicas. If you restore only to core nodes and not to read replicas, when they start
the core nodes will replicate the data to the read replicas.   This will work just fine, but may result in longer startup times and much more bandwidth.

## Parameters

- `GOOGLE_APPLICATION_CREDENTIALS` - path to a file with a JSON service account key (see credentials below)
- `REMOTE_BACKUPSET` the URL of the backupset, of the form `gs://my-bucket/my-backup.tar.gz` where the backup set resides.
- `BACKUP_SET_DIR` - (optional).  If you used the backup container that comes with this repo, then this is not needed.  If you made your own backup, this should contain the name of the directory that the compressed backup set expands to.  This is intended to handle relative paths within the compressed set.  For example if your backup set `foo.tar.gz` decompresses to `myData/mySet/*` files, then you would set `BACKUP_SET_DIR=myData/mySet` (the relative path) so that the restore utility knows the right directory to point at after the set is uncompressed.
- `PURGE_ON_COMPLETE` (defaults to true).  If this is set to the value "true", the restore process will remove the restore artifacts from disk.  With any other 
value, they will be left in place.  This is useful for debugging restores, to 
see what was copied down from cloud storage and how it was expanded.

The restore container can detect .tar.gz and .zip compressed backups and deal with them appropriately, as well as uncompressed directory backup sets.

## Optional Parameters

- `FORCE_OVERWRITE` if this is the value "true", then the restore process will overwrite and
destroy any existing data that is on the volume.  Take care when using this in combination with
persistent volumes.  The default is false; if data already exists on the drive, the restore operation will likely fail but preserve your data.

**Warnings**

A common way you might deploy Neo4j would be restore from last backup when a container initializes.  This would be good for a cluster, because it would minimize how much catch-up
is needed when a node is launched.  Any difference between the last backup and the rest of the
cluster would be provided via catch-up.

For single nodes, take extreme care here.  If a node crashes, and you automatically restore from
backup, and force-overwrite what was previously on the disk, you will lose any data that the
database captured between when the last backup was taken, and when the crash happened.  As a
result, for single node instances of Neo4j you should either perform restores manually when you
need them, or you should keep a very regular backup schedule to minimize this data loss.  If data
loss is under no circumstances acceptable, do not automate restores for single node deploys.

## Running the Restore

With the initContainer in place and properly configured, simply deploy a new cluster 
using the regular approach.  Prior to start, the restore will happen, and when the 
cluster comes live, it will be populated with the data.

## Limitations

As of Neo4j 4.1 series, data backups do not include authorization information for your cluster.
That is, usernames/passwords associated with the graph are not included in the backup, and hence
are not restored when you restore.

This is something to be aware of; when launching a cluster typically you're providing startup auth
information and separate configuration anyway.  If you create users, groups, and roles you may want
to separately take copies of the auth files so that they can be restored when your cluster starts up.
Alternatively, users may configure their systems to use LDAP providers in which case there is no need
to backup any auth information.

## Ongoing Maintenance

In general we'd recommend taking regular full backups, and restoring from those.

## Limitations

- Container has not yet been tested with incremental backups
- For the time being, only google storage as a cloud storage option is implemented, 
but adapting this approach to S3 or other storage should be fairly straightforward with modifications to `restore.sh`

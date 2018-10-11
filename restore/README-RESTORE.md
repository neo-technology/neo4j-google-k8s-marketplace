# Restoring Neo4j Containers

This directory contains files necessary for restoring Neo4j Docker containers
from google storage, or local files placed on the volume.

See restore.yaml for an example.   

## Required Parameters

- `GOOGLE_APPLICATION_CREDENTIALS` - path to a file with a JSON service account key (see credentials below)
- `BUCKET` the URL of the bucket, of the form `gs://my-bucket` where the backup set resides.
- `BACKUP_NAME` path to a file (or uncompressed directory) within the bucket that contains the
backup files.  Example:  `mydata-backup-2018-09-01.tar.gz`

The restore container can detect .tar.gz and .zip compressed backups and deal with them appropriately, as well as uncompressed directory backup sets.

## Credentials

First you want to create a kubernetes secret that contains your account service key, like this:

```
MY_SERVICE_ACCOUNT_KEY=$HOME/.google/neo4j-k8s-marketplace-public-ad35bd86462f.json
kubectl create secret generic restore-service-key \
   --from-file=credentials.json=$MY_SERVICE_ACCOUNT_KEY
```

Then in the initContainer, you want to map use a volume mount to connect restore-service-key to /auth, and then you can simply specify:

`GOOGLE_APPLICATION_CREDENTIALS=/auth/credentials.json`

## Optional Parameters

- `FORCE_OVERWRITE` if this is the value "true", then the restore process will overwrite and
destroy any existing data that is on the volume.  Take care when using this in combination with
persistent volumes.  The default is false; if data already exists on the drive, the restore operation will likely fail but preserve your data.



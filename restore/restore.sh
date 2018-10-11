#!/bin/bash

if [ -z $BUCKET ]; then
    echo "You must specify a BUCKET address such as gs://my-backups/"
    exit 1
fi

if [ -z $BACKUP_NAME ] ; then
    echo "You must specify a BACKUP_NAME such as my-data.tar.gz"
    exit 1
fi

if [ -z $PURGE_ON_COMPLETE ]; then
    PURGE_ON_COMPLETE=false
fi

# Pass the force flag to the restore operation, which will overwrite
# whatever is there, if and only if FORCE_OVERWRITE=true.
if [ "$FORCE_OVERWRITE" = true ]; then
    echo "We will be force-overwriting any data present"
    FORCE_FLAG="--force"
else
    # Pass no flag in any other setup.
    echo "We will not force-overwrite data if present"
    FORCE_FLAG=""
fi

if [ -z $HEAP_SIZE ] ; then
    HEAP_SIZE=2G
fi

if [ -z $PAGE_CACHE ]; then
    PAGE_CACHE=4G
fi

echo "Activating google credentials before beginning"
echo $GOOGLE_APPLICATION_CREDENTIALS
ls -l $GOOGLE_APPLICATION_CREDENTIALS
cat $GOOGLE_APPLICATION_CREDENTIALS
gcloud auth activate-service-account --key-file "$GOOGLE_APPLICATION_CREDENTIALS"

if [ $? -ne 0 ] ; then
    echo "Credentials failed; no way to copy from google."
    echo "Ensure GOOGLE_APPLICATION_CREDENTIALS is appropriately set."
fi

echo "=============== Neo4j Restore ==============================="
echo "Beginning restore from $BACKUP_NAME to /data/"
echo "Using heap size $HEAP_SIZE and page cache $PAGE_CACHE"
echo "From google storage bucket $BUCKET using credentials located at $GOOGLE_APPLICATION_CREDENTIALS"
echo "============================================================"

BACKUPSET_ROOT=/data/backupset
RESTORE_FROM=/data/backupset

echo "Making restore directory"
mkdir -p /data/backupset

echo "Copying $BUCKET/$BACKUP_NAME -> $RESTORE_FROM"

# By copying recursively, the user can specify a dir with an uncompressed
# backup if preferred. The -m flag downloads in parallel if possible.
gsutil cp -r "$BUCKET/$BACKUP_NAME" "$RESTORE_FROM"

echo "Backup size pre-uncompress:"
du -hs "$RESTORE_FROM"
ls -l "$RESTORE_FROM"

# Important note!  If you have a backup name that is "foo.tar.gz" or 
# foo.zip, we need to assume that this unarchives to a directory called
# foo, as neo4j backup sets are directories.  So we'll remove the suffix
# after unarchiving and use that as the actual backup target.
if [[ $BACKUP_NAME =~ \.tar\.gz$ ]] ; then
    echo "Untarring backupset"
    cd "$RESTORE_FROM" && tar --force-local -zxvf "$BACKUP_NAME"

    if [ $? -ne 0 ] ; then
        echo "Failed to unarchive target backup set"
        exit 1
    fi

    # foo.tar.gz untars/zips to a directory called foo.
    UNTARRED_BACKUP_DIR=${BACKUP_NAME%.tar.gz}
    RESTORE_FROM="$RESTORE_FROM/data/$UNTARRED_BACKUP_DIR"
elif [[ $BACKUP_NAME =~ \.zip$ ]] ; then
    echo "Unzipping backupset"
    cd "$RESTORE_FROM" && unzip "$BACKUP_NAME"
    
    if [ $? -ne 0 ]; then 
        echo "Failed to unzip target backup set"
        exit 1
    fi

    # Remove file extension, get to directory name
    UNZIPPED_BACKUP_DIR=${BACKUP_NAME%.zip}
    RESTORE_FROM="$RESTORE_FROM/data/$UNZIPPED_BACKUP_DIR"
else
    echo "This backup $BACKUP_NAME looks uncompressed."
    RESTORE_FROM="$RESTORE_FROM/$BACKUP_NAME"
fi

echo "Set to restore from $RESTORE_FROM"
echo "Post compress backup size:"
du -hs "$RESTORE_FROM"
ls "$RESTORE_FROM"

cd /data && \
echo "Dry-run command"
echo neo4j-admin restore \
    --from="$RESTORE_FROM" \
    --database=graph.db $FORCE_FLAG

echo "Volume mounts and sizing"
df -h

echo "Now restoring"
neo4j-admin restore \
    --from="$RESTORE_FROM" \
    --database=graph.db $FORCE_FLAG

RESTORE_EXIT_CODE=$?

echo "Restore process complete with exit code $RESTORE_EXIT_CODE"

echo "Rehoming database"
echo "Restored to:"
ls -lR /var/lib/neo4j/data/databases

# neo4j-admin restore puts the DB in the wrong place, it needs to be re-homed
# for docker.
mkdir /data/databases
mv /var/lib/neo4j/data/databases/graph.db /data/databases/

# Modify permissions/group, because we're running as root.
chown -R neo4j /data/databases
chgrp -R neo4j /data/databases

echo "Final permissions"
ls -al /data/databases/graph.db

echo "Final size"
du -ms /data/databases/graph.db

if [ "$PURGE_ON_COMPLETE" = true ] ; then
    echo "Purging backupset from disk"
    rm -rf "$BACKUPSET_ROOT"
fi

exit $RESTORE_EXIT_CODE

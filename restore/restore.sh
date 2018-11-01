#!/bin/bash

if [ -z $REMOTE_BACKUPSET ]; then
    echo "You must specify a REMOTE_BACKUPSET such as gs://my-backups/my-backup.tar.gz"
    exit 1
fi

if [ -z $BACKUP_SET_DIR ] ; then
    echo "*********************************************************************************************"
    echo "* You have not specified BACKUP_SET_DIR -- this means that if your archive set uncompresses *"
    echo "* to a different directory than the file is named, this restore may fail                    *"
    echo "* See logs below to ensure the right path was selected.                                     *"
    echo "*********************************************************************************************"
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
gcloud auth activate-service-account --key-file "$GOOGLE_APPLICATION_CREDENTIALS"

if [ $? -ne 0 ] ; then
    echo "Credentials failed; copying from Google will likely fail unless the bucket is public"
    echo "Ensure GOOGLE_APPLICATION_CREDENTIALS is appropriately set."
fi

echo "=============== Neo4j Restore ==============================="
echo "Beginning restore from $BACKUP_NAME to /data/"
echo "Using heap size $HEAP_SIZE and page cache $PAGE_CACHE"
echo "From google storage bucket $BUCKET using credentials located at $GOOGLE_APPLICATION_CREDENTIALS"
echo "============================================================"

BACKUPSET_ROOT=/data/backupset
RESTORE_ROOT=/data/backupset

echo "Making restore directory"
mkdir -p /data/backupset

echo "Copying $REMOTE_BACKUPSET -> $RESTORE_ROOT"

# By copying recursively, the user can specify a dir with an uncompressed
# backup if preferred. The -m flag downloads in parallel if possible.
gsutil -m cp -r "$REMOTE_BACKUPSET" "$RESTORE_ROOT"

echo "Backup size pre-uncompress:"
du -hs "$RESTORE_ROOT"
ls -l "$RESTORE_ROOT"

# Important note!  If you have a backup name that is "foo.tar.gz" or 
# foo.zip, we need to assume that this unarchives to a directory called
# foo, as neo4j backup sets are directories.  So we'll remove the suffix
# after unarchiving and use that as the actual backup target.
BACKUP_FILENAME=$(basename "$REMOTE_BACKUPSET")
RESTORE_FROM=uninitialized
if [[ $BACKUP_FILENAME =~ \.tar\.gz$ ]] ; then
    echo "Untarring backup file"
    cd "$RESTORE_ROOT" && tar --force-local -zxvf "$BACKUP_FILENAME"

    if [ $? -ne 0 ] ; then
        echo "Failed to unarchive target backup set"
        exit 1
    fi

    # foo.tar.gz untars/zips to a directory called foo.
    UNTARRED_BACKUP_DIR=${BACKUP_FILENAME%.tar.gz}

    if [ -z $BACKUP_SET_DIR ] ; then
        echo "BACKUP_SET_DIR was not specified, so I am assuming this backup set was formatted by my backup utility"
        RESTORE_FROM="$RESTORE_ROOT/data/$UNTARRED_BACKUP_DIR"
    else 
        RESTORE_FROM="$RESTORE_ROOT/$BACKUP_SET_DIR"
    fi
elif [[ $BACKUP_NAME =~ \.zip$ ]] ; then
    echo "Unzipping backupset"
    cd "$RESTORE_ROOT" && unzip "$BACKUP_FILENAME"
    
    if [ $? -ne 0 ]; then 
        echo "Failed to unzip target backup set"
        exit 1
    fi

    # Remove file extension, get to directory name  
    UNZIPPED_BACKUP_DIR=${BACKUP_FILENAME%.zip}

    if [ -z $BACKUP_SET_DIR ] ; then
        echo "BACKUP_SET_DIR was not specified, so I am assuming this backup set was formatted by my backup utility"
        RESTORE_FROM="$RESTORE_FROM/data/$UNZIPPED_BACKUP_DIR"
    else
        RESTORE_FROM="$RESTORE_FROM/$BACKUP_SET_DIR"
    fi
else
    # If user stores backups as uncompressed directories, we would have pulled down the entire directory
    echo "This backup $BACKUP_FILENAME looks uncompressed."
    RESTORE_FROM="$RESTORE_FROM/$BACKUP_FILENAME"
fi

echo "BACKUP_FILENAME=$BACKUP_FILENAME"
echo "UNTARRED_BACKUP_DIR=$UNTARRED_BACKUP_DIR"
echo "UNZIPPED_BACKUP_DIR=$UNZIPPED_BACKUP_DIR"
echo "RESTORE_FROM=$RESTORE_FROM"

echo "Set to restore from $RESTORE_FROM"
echo "Post uncompress backup size:"
ls -al "$BACKUPSET_ROOT"
du -hs "$RESTORE_FROM"

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

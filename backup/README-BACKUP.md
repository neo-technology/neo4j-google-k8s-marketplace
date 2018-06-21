# Backing up Neo4j Containers

This directory contains files necessary for backing up Neo4j Docker containers
to google storage.

See backup.yaml for an example.   

The "credentials.json" file must be a base64-encoded version of a service key JSON that has permissions to write to the targeted google storage bucket.


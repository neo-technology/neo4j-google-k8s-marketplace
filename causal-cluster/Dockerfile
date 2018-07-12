ARG NEO4J_VERSION

FROM neo4j:${NEO4J_VERSION}

# Our app solution container is basically neo4j's public docker image, with some additions:

# SSH client, for various networking tricks (proxying/port forwarding)
RUN apk add --no-cache openssh-client

# Copies of licenses required for google marketplace, tied to open source review
RUN mkdir /licensing
ADD causal-cluster/licensing/* /licensing/

# Copies of default enabled plugins, distributed with the solution, not part of 
# the vanilla docker container.
ADD causal-cluster/plugins/* /plugins/

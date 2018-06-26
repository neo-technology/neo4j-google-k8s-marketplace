ARG NEO4J_VERSION

FROM neo4j:${NEO4J_VERSION}

# Our app solution container is basically neo4j's public docker image, with two additions:

# (1) Copies of licenses required for google marketplace, tied to open source review
RUN mkdir /licensing
ADD causal-cluster/licensing/* /licensing/

# (2) Copies of default enabled plugins, distributed with the solution, not part of 
# the vanilla docker container.
ADD causal-cluster/plugins/* /plugins/

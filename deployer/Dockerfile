FROM launcher.gcr.io/google/debian9 AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext

ADD chart /tmp/chart
RUN cd /tmp \
    && tar -czvf /tmp/neo4j.tar.gz chart
ADD apptest/deployer/neo4j /tmp/test/chart
RUN cd /tmp/test \
    && tar -czvf /tmp/test/neo4j.tar.gz chart/

ADD schema.yaml /tmp/solution-schema.yaml
ADD apptest/deployer/schema.yaml /tmp/test-schema.yaml

ARG REGISTRY
ARG TAG

# Substitute REGISTRY and TAG from the build environment into
# those schema files, so that the deployer/tester container is baked
# to a certain version of the solution.
RUN cat /tmp/solution-schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
    > /tmp/solution-schema.yaml.new \
    && mv /tmp/solution-schema.yaml.new /tmp/solution-schema.yaml

RUN cat /tmp/test-schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
    > /tmp/test-schema.yaml.new \
    && mv /tmp/test-schema.yaml.new /tmp/test-schema.yaml

FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm

COPY --from=build /tmp/neo4j.tar.gz /data/chart/
COPY --from=build /tmp/test/neo4j.tar.gz /data-test/chart/

COPY --from=build /tmp/test-schema.yaml /data-test/schema.yaml
COPY --from=build /tmp/solution-schema.yaml /data/schema.yaml

RUN echo "THIS IS MY TESTER SCHEMA OVERLAY"
RUN cat /data-test/schema.yaml

RUN echo "THIS IS MY SOLUTION SCHEMA"
RUN cat /data/schema.yaml

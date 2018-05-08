ARG MARKETPLACE_REGISTRY
FROM launcher.gcr.io/google/debian9 AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext

ADD chart /tmp/chart
RUN cd /tmp \
    && tar -czvf /tmp/neo4j.tar.gz chart
ADD apptest/deployer/chart /tmp/test/chart
RUN cd /tmp/test \
    && tar -czvf /tmp/test/neo4j.tar.gz chart/

FROM ${MARKETPLACE_REGISTRY}/deployer_helm_base
COPY --from=build /tmp/neo4j.tar.gz /data/chart/
COPY --from=build /tmp/test/neo4j.tar.gz /data-test/chart/
COPY apptest/deployer/config.yaml /data-test/
COPY apptest/deployer/schema.yaml /data-test/
COPY schema.yaml /data/schema.yaml
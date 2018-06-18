FROM launcher.gcr.io/google/debian9 AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext

ADD schema.yaml /tmp/schema.yaml
ADD chart /tmp/chart

RUN cd /tmp \
    && tar -czvf /tmp/neo4j.tar.gz chart

ADD apptest/deployer/neo4j /tmp/test/chart
RUN cd /tmp/test \
    && tar -czvf /tmp/test/neo4j.tar.gz chart/

ARG REGISTRY
ARG TAG

RUN cat /tmp/schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
    > /tmp/schema.yaml.subst

# ADD apptest/deployer/chart /tmp/test/chart
#RUN cd /tmp/test \
#    && tar -czvf /tmp/test/neo4j.tar.gz chart/

FROM gcr.io/google-marketplace-tools/k8s/deployer_helm
COPY --from=build /tmp/neo4j.tar.gz /data/chart/
COPY --from=build /tmp/test/neo4j.tar.gz /data-test/chart/
COPY apptest/deployer/schema.yaml /data-test/

COPY --from=build /tmp/schema.yaml.subst /data/schema.yaml

COPY apptest/deployer/schema.yaml /data-test/

RUN ls -l /data/

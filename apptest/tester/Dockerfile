FROM dduportal/bats:0.4.0
LABEL Maintainer="David Allen <david.allen@neo4j.com>"

COPY ./apptest/tests /tests

# Optional:
RUN apt-get install -y curl

CMD ["/tests/test.sh"]

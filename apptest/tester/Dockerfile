#FROM dduportal/bats:0.4.0
#LABEL Maintainer="David Allen <david.allen@neo4j.com>"
#
#COPY ./apptest/tests /tests
#RUN apt-get update && apt-get install -y apt-transport-https curl apt-utils
#RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#RUN touch /etc/apt/sources.list.d/kubernetes.list 
#RUN echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
#RUN apt-get update
#RUN apt-get install -y kubectl
#
#CMD ["/tests/test.sh"]
FROM launcher.gcr.io/google/debian9
RUN apt-get update
RUN apt-get install -y bash curl wget gnupg apt-transport-https curl apt-utils
RUN wget -O - https://debian.neo4j.org/neotechnology.gpg.key | apt-key add -
RUN echo 'deb https://debian.neo4j.org/repo stable/' | tee -a /etc/apt/sources.list.d/neo4j.list
RUN apt-get update && apt-get -y upgrade 
RUN apt-get install -y cypher-shell

CMD ["/bin/bash"]

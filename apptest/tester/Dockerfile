#FROM dduportal/bats:0.4.1
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
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y bash curl wget gnupg apt-transport-https curl apt-utils
RUN echo 'deb http://ftp.debian.org/debian stretch-backports main' | tee /etc/apt/sources.list.d/stretch-backports.list
RUN apt-get update
RUN apt-get install -y ca-certificates ca-certificates-java
RUN curl https://debian.neo4j.com/neotechnology.gpg.key | apt-key add -
RUN echo 'deb http://debian.neo4j.com stable 4.2' | tee -a /etc/apt/sources.list.d/neo4j.list
RUN apt-get update
RUN apt-get install -y cypher-shell=4.2.2

CMD ["/bin/bash"]

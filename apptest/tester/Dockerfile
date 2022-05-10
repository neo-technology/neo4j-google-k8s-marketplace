FROM launcher.gcr.io/google/debian10
RUN apt update && apt -y upgrade
RUN apt install -y bash curl wget gnupg apt-transport-https curl apt-utils
RUN wget https://dist.neo4j.org/cypher-shell/cypher-shell_4.4.6_all.deb
RUN apt install -y ./cypher-shell_4.4.6_all.deb

CMD ["/bin/bash"]

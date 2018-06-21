FROM launcher.gcr.io/google/debian9
RUN apt-get update
RUN apt-get install -y bash curl wget gnupg apt-transport-https apt-utils lsb-release
RUN wget -O - https://debian.neo4j.org/neotechnology.gpg.key | apt-key add -
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo 'deb https://debian.neo4j.org/repo stable/' | tee -a /etc/apt/sources.list.d/neo4j.list
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-$(lsb_release -c -s) main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

RUN apt-get update
RUN apt-get install -y neo4j-enterprise=1:3.4.1 google-cloud-sdk

RUN mkdir /data
ADD backup/backup.sh /scripts/backup.sh
RUN chmod +x /scripts/backup.sh
RUN gsutil

CMD ["/scripts/backup.sh"]

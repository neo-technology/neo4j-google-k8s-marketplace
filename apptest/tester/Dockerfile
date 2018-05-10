FROM launcher.gcr.io/google/debian9 AS tester
COPY apptest/tester/deploy_with_tests.sh /bin
RUN chmod +x /bin/*.sh
RUN mkdir /tests
COPY apptest/tests/* /tests

ENTRYPOINT ["/bin/bash", "/bin/deploy_with_tests.sh"]

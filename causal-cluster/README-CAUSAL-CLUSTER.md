## GCR.io Project Layout

Overall container layout for the project should be as follows:

```
gcr.io/partnerX/solutionY:v1
gcr.io/partnerX/solutionY/deployer:v1
gcr.io/partnerX/solutionY/support:v1
gcr.io/partnerX/solutionY:v2
gcr.io/partnerX/solutionY/deployer:v2
gcr.io/partnerX/solutionY/support:v2
```

This directory hosts the "solution" container, which is based on neo4j's public docker image.

This container is deployed by the helm chart in clustered configuration.
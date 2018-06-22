# Many targets in this makefile are prescribed by google's marketplace
# tools; do not change make targets or .build files.   Additional valuable
# targets can be found in $(tools_path)/app.Makefile where a lot of logic
# is inherited.
#################################################
APP_NAME = neo4j
REGISTRY = gcr.io/neo4j-k8s-marketplace-public/causal-cluster
DEPLOYER_TAG=$(shell cat chart/Chart.yaml | grep version: | sed 's/.*: //g')
APP_DEPLOYER_IMAGE=$(REGISTRY)/deployer:$(DEPLOYER_TAG)
APP_TAG=3.4.1-enterprise
tools_path = ./vendor/marketplace-k8s-app-tools

include $(tools_path)/crd.Makefile
include $(tools_path)/gcloud.Makefile
include $(tools_path)/marketplace.Makefile
include $(tools_path)/ubbagent.Makefile
include $(tools_path)/var.Makefile
include $(tools_path)/app.Makefile

APP_TESTER_IMAGE = $(REGISTRY)/tester:$(DEPLOYER_TAG)

APP_INSTANCE_NAME ?= testrun

APP_PARAMETERS ?= { \
  "name": "$(APP_INSTANCE_NAME)", \
  "namespace": "$(NAMESPACE)", \
  "image": "$(REGISTRY)/neo4j:$(APP_TAG)", \
  "reportingSecret": "XYZ", \
  "coreServers": "3", \
  "readReplicaServers": "1" \
}

APP_TEST_PARAMETERS ?= { \
  "tester.image": "$(APP_TESTER_IMAGE)" \
}

app/build:: .build/neo4j .build/deployer .build/tester .build/backup

app/build-test:: app/build .build/tester

app/image:: .build/neo4j

app/backup:: .build/backup

app/deployer:: .build/deployer

.build/deployer: schema.yaml \
				 deployer/* \
				 chart/* \
				 chart/templates/* \
				 apptest/deployer/* \
				 .build/marketplace/deployer/helm \
				 .build/var/REGISTRY \
				 | .build/neo4j
	echo $(DEPLOYER_TAG)
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)" \
		--build-arg TAG="$(APP_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@date >> "$@"

.build/tester: apptest/* .build/var/REGISTRY
	$(call print_target, $@)
	docker build \
	   --tag "$(APP_TESTER_IMAGE)" \
	   -f apptest/tester/Dockerfile \
	   .
	docker push "$(APP_TESTER_IMAGE)"
	@date >> "$@"

APP_BACKUP_IMAGE=$(REGISTRY)/backup:latest

.build/backup: backup/*
	docker build \
		--tag "$(APP_BACKUP_IMAGE)" \
		-f backup/Dockerfile \
		.
	docker push "$(APP_BACKUP_IMAGE)"
	@date >> "$@"

# Simulate building of primary app image. Actually just copying public image to
# local registry.
.build/neo4j: .build/var/REGISTRY
	docker pull appropriate/curl:latest
	docker tag appropriate/curl:latest $(REGISTRY)/appropriate/curl:latest
	docker push $(REGISTRY)/appropriate/curl:latest
    docker pull neo4j:3.4.1-enterprise
	docker tag neo4j:3.4.1-enterprise $(REGISTRY)/neo4j:$(APP_TAG)
	docker push "$(REGISTRY)/neo4j:$(APP_TAG)"
	@touch "$@"

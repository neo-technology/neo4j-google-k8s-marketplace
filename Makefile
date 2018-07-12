# Many targets in this makefile are prescribed by google's marketplace
# tools; do not change make targets or .build files.   Additional valuable
# targets can be found in $(tools_path)/app.Makefile where a lot of logic
# is inherited.
#################################################
APP_NAME = neo4j
REGISTRY = gcr.io/neo4j-k8s-marketplace-public/causal-cluster
SOLUTION_VERSION=$(shell cat chart/Chart.yaml | grep version: | sed 's/.*: //g')
APP_DEPLOYER_IMAGE=$(REGISTRY)/deployer:$(SOLUTION_VERSION)
NEO4J_VERSION=3.4.1-enterprise
tools_path = ./vendor/marketplace-k8s-app-tools

include $(tools_path)/crd.Makefile
include $(tools_path)/gcloud.Makefile
include $(tools_path)/marketplace.Makefile
include $(tools_path)/ubbagent.Makefile
include $(tools_path)/var.Makefile
include $(tools_path)/app.Makefile

APP_TESTER_IMAGE = $(REGISTRY)/tester:$(SOLUTION_VERSION)

APP_INSTANCE_NAME ?= testrun

APP_PARAMETERS ?= { \
  "name": "$(APP_INSTANCE_NAME)", \
  "namespace": "$(NAMESPACE)", \
  "image": "$(REGISTRY):$(SOLUTION_VERSION)", \
  "coreServers": "3", \
  "readReplicaServers": "1" \
}

APP_TEST_PARAMETERS ?= { \
  "tester.image": "$(APP_TESTER_IMAGE)" \
}

app/build:: app/image .build/deployer .build/tester .build/backup

app/build-test:: app/build .build/tester

app/image:  causal-cluster/*
	docker pull neo4j:$(NEO4J_VERSION)
	docker build --tag $(REGISTRY):$(SOLUTION_VERSION) \
		--build-arg NEO4J_VERSION="$(NEO4J_VERSION)" \
		-f causal-cluster/Dockerfile \
		.
	docker push $(REGISTRY):$(SOLUTION_VERSION)
	# Not needed as plugins are included in solution container
	#docker pull appropriate/curl:latest
	#docker tag appropriate/curl:latest $(REGISTRY)/appropriate/curl:latest
	#docker push $(REGISTRY)/appropriate/curl:latest

app/backup:: .build/backup

app/deployer:: .build/deployer

.build/deployer: schema.yaml \
				 deployer/* \
				 chart/* \
				 chart/templates/* \
				 apptest/deployer/* \
				 .build/marketplace/deployer/helm \
				 .build/var/REGISTRY
	echo $(SOLUTION_VERSION)
	docker build \
	    --build-arg REGISTRY=$(REGISTRY) \
		--build-arg TAG=$(SOLUTION_VERSION) \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@date >> "$@"

.build/tester: apptest/deployer/* apptest/deployer/neo4j/* apptest/deployer/neo4j/templates/* .build/var/REGISTRY
	$(call print_target, $@)
	docker build \
	   --tag "$(APP_TESTER_IMAGE)" \
	   -f apptest/tester/Dockerfile \
	   .
	docker push "$(APP_TESTER_IMAGE)"
	@date >> "$@"

APP_BACKUP_IMAGE=$(REGISTRY)/backup:$(SOLUTION_VERSION)

.build/backup: backup/*
	docker build \
		--tag "$(APP_BACKUP_IMAGE)" \
		-f backup/Dockerfile \
		.
	docker push "$(APP_BACKUP_IMAGE)"
	@date >> "$@"


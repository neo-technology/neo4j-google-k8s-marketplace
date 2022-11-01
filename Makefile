NAME = neo4j
REGISTRY = gcr.io/neo4j-k8s-marketplace-public/causal-cluster
# Solution version
SOLUTION_VERSION=$(shell cat chart/Chart.yaml | grep version: | sed 's/.*: //g')$(BUILD)
TAG=$(SOLUTION_VERSION)
APP_DEPLOYER_IMAGE=$(REGISTRY)/deployer:$(SOLUTION_VERSION)
APP_RESTORE_IMAGE=$(REGISTRY)/restore:$(SOLUTION_VERSION)
APP_BACKUP_IMAGE=$(REGISTRY)/restore:$(SOLUTION_VERSION)
NEO4J_VERSION=4.4.12-enterprise
TESTER_IMAGE = $(REGISTRY)/tester:$(SOLUTION_VERSION)
NAMESPACE ?= default

include ./app.Makefile
include ./crd.Makefile
include ./gcloud.Makefile
include ./var.Makefile

$(info ---- TAG = $(TAG))

APP_NAME ?= testrun

APP_PARAMETERS ?= { \
  "name": "$(APP_NAME)", \
  "namespace": "$(NAMESPACE)", \
  "image": "$(REGISTRY):$(SOLUTION_VERSION)", \
  "coreServers": "3", \
  "readReplicaServers": "1" \
}

APP_TEST_PARAMETERS ?= { \
	"tester.image": "$(TESTER_IMAGE)" \
}

app/build:: .build/neo4j \
            .build/neo4j/causal-cluster \
            .build/neo4j/deployer \
            .build/neo4j/tester \
			.build/neo4j/backup \
			.build/neo4j/restore

.build/neo4j: | .build
	mkdir -p "$@"


.build/neo4j/deployer: schema.yaml \
				 deployer/* \
				 chart/* \
				 chart/templates/* \
				 apptest/deployer/* \
				 .build/var/REGISTRY
	echo $(SOLUTION_VERSION)
	docker build \
	    --build-arg REGISTRY=$(REGISTRY) \
		--build-arg TAG=$(SOLUTION_VERSION) \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@touch "$@"


.build/neo4j/tester:   .build/var/TESTER_IMAGE \
                $(shell find apptest -type f) | .build/neo4j
	$(call print_target,$@)
	docker build \
	   --tag "$(TESTER_IMAGE)" \
	   --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
	   -f apptest/tester/Dockerfile \
	   .
	docker push "$(TESTER_IMAGE)"
	@touch "$@"

.build/neo4j/restore: restore/*
	docker build \
		--tag "$(APP_RESTORE_IMAGE)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
		-f restore/Dockerfile \
		.
	docker push "$(APP_RESTORE_IMAGE)"
	@date >> "$@"

APP_BACKUP_IMAGE=$(REGISTRY)/restore:$(SOLUTION_VERSION)

.build/neo4j/backup: backup/*
	docker build \
		--tag "$(APP_BACKUP_IMAGE)" \
  	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
		-f backup/Dockerfile \
		.
	docker push "$(APP_BACKUP_IMAGE)"
	@date >> "$@"

.build/neo4j/causal-cluster:  causal-cluster/*
	docker pull neo4j:$(NEO4J_VERSION)
	docker build --tag $(REGISTRY):$(SOLUTION_VERSION) \
		--build-arg NEO4J_VERSION="$(NEO4J_VERSION)" \
  	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
		-f causal-cluster/Dockerfile \
		.
	docker push $(REGISTRY):$(SOLUTION_VERSION)


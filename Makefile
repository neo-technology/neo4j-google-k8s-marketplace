APP_NAME = neo4j
REGISTRY = gcr.io/neo4j-k8s-marketplace-public
APP_REGISTRY=$(REGISTRY)/neo4j
APP_DEPLOYER_IMAGE=$(REGISTRY)/neo4j-deployer:latest
APP_TAG=3.3.5-enterprise
tools_path = ./vendor/marketplace-k8s-app-tools

include $(tools_path)/crd.Makefile
include $(tools_path)/gcloud.Makefile
include $(tools_path)/marketplace.Makefile
include $(tools_path)/ubbagent.Makefile
include $(tools_path)/var.Makefile
include $(tools_path)/app.Makefile

APP_TESTER_IMAGE = $(REGISTRY)/neo4j-tester:latest

APP_PARAMETERS ?= { \
  "name": "$(APP_INSTANCE_NAME)", \
  "namespace": "$(NAMESPACE)", \
  "image": "$(APP_REGISTRY):$(APP_TAG)" \
}

APP_TEST_PARAMETERS ?= { \
  "tester.image": "$(APP_TESTER_IMAGE)" \
}

app/build:: .build/neo4j .build/deployer .build/tester

app/build-test:: app/build .build/tester

.build/deployer: schema.yaml \
				 deployer/* \
				 chart/* \
				 apptest/deployer/* \
				 .build/marketplace/deployer/helm \
				 .build/var/REGISTRY \
				 | .build/neo4j
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)/neo4j" \
		--build-arg TAG="$(APP_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	gcloud docker -- push "$(APP_DEPLOYER_IMAGE)"
	@date >> "$@"

.build/tester: apptest/* .build/var/REGISTRY
	$(call print_target, $@)
	docker build \
	   --tag "$(APP_TESTER_IMAGE)" \
	   -f apptest/tester/Dockerfile \
	   .
	gcloud docker -- push "$(APP_TESTER_IMAGE)"
	@date >> "$@"

# Simulate building of primary app image. Actually just copying public image to
# local registry.
.build/neo4j: .build/var/REGISTRY
    docker pull neo4j:3.3.5-enterprise
	docker tag neo4j:3.3.5-enterprise $(REGISTRY)/neo4j:3.3.5-enterprise
	gcloud docker -- push "$(APP_REGISTRY):$(APP_TAG)"
	@touch "$@"

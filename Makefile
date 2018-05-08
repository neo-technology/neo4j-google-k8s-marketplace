APP_NAME = neo4j
REGISTRY = gcr.io/neo4j-k8s-marketplace-public
APP_REGISTRY=$(REGISTRY)/neo4j
APP_DEPLOYER_IMAGE=$(REGISTRY)/neo4j-deployer:latest
APP_TAG=3.3.5-enterprise
APP_TESTER_IMAGE = gcr.io/neo4j-k8s-marketplace-public/neo4j-tester:latest
tools_path = ./vendor/marketplace-k8s-app-tools

include $(tools_path)/gcloud.Makefile

include $(tools_path)/crd.Makefile
include $(tools_path)/app.Makefile
include $(tools_path)/ubbagent.Makefile

APP_TESTER_IMAGE = $(REGISTRY)/tester:latest

define APP_PARAMETERS
{ \
  "APP_INSTANCE_NAME": "$(APP_INSTANCE_NAME)", \
  "NAMESPACE": "$(NAMESPACE)", \
  "IMAGE_NEO4J": "$(APP_REGISTRY):$(APP_TAG)" \
}
endef

define TEST_PARAMETERS
{ \
  "APP_TESTER_IMAGE": "$(APP_TESTER_IMAGE)" \
}
endef

app/build:: .build/neo4j .build/deployer 

app/build-test:: app/build .build/tester

.build/deployer: schema.yaml deployer/* chart/* apptest/deployer/* $(MARKETPLACE_BASE_BUILD)/deployer-helm $(APP_BUILD)/registry_prefix | app/setup
	docker build \
	    --build-arg MARKETPLACE_REGISTRY="$(MARKETPLACE_REGISTRY)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	gcloud docker -- push "$(APP_DEPLOYER_IMAGE)"
	@date >> "$@"

.build/tester: apptest/* $(APP_BUILD)/registry_prefix | app/setup
	docker build \
	    --tag "$(APP_TESTER_IMAGE)" \
	    -f apptest/tester/Dockerfile \
	    .
	gcloud docker -- push "$(APP_TESTER_IMAGE)"
	@date >> "$@"

# Simulate building of primary app image. Actually just copying public image to
# local registry.
.build/neo4j: $(APP_BUILD)/registry_prefix | app/setup
    docker pull neo4j:3.3.5-enterprise
	docker tag neo4j:3.3.5-enterprise $(REGISTRY)/neo4j:3.3.5-enterprise
	gcloud docker -- push "$(APP_REGISTRY):$(APP_TAG)"
	@touch "$@"

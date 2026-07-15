REGISTRY_URL=ghcr.io/gigaflux
SERVICE_NAME ?= airflow-redis
REDIS_VER ?= 7.2
PLATFORM ?=

ifeq ($(PLATFORM),)
	UNAME_M := $(shell uname -m)
	ifeq ($(UNAME_M), x86_64)
		PLATFORM = amd64
	else ifeq ($(UNAME_M), amd64)
    	PLATFORM = amd64
	else ifeq ($(UNAME_M), aarch64)
    	PLATFORM = arm64
    else ifeq ($(UNAME_M), arm64)
    	PLATFORM = arm64
	else
    	$(error Error: Unknown architecture '$(UNAME_M)')
	endif
endif

MATCHED := $(filter $(PLATFORM), amd64 arm64)
ifeq ($(MATCHED),)
$(error Error: Unknown architecture '$(PLATFORM)')
endif

GIT_REVISION ?= $(shell git describe --tags --exact-match 2>/dev/null || \
                        git describe --tags 2>/dev/null || \
                        git rev-parse --short HEAD 2>/dev/null || \
                        echo "unknown")

GIT_SHA ?= $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")

IMAGE_SHORT_NAME = $(REGISTRY_URL)/$(SERVICE_NAME):$(REDIS_VER)
IMAGE_FULL_NAME = $(REGISTRY_URL)/$(SERVICE_NAME):$(REDIS_VER)-$(GIT_REVISION)

.PHONY: login logout build push release check check-report clean

## login: Authenticate Docker with GitHub Container Registry
login:
	@echo "Authenticating with GitHub Container Registry..."
	@echo "$(CR_PAT)" | docker login ghcr.io -u "$(GITHUB_ACTOR)" --password-stdin

## logout
logout:
	docker logout ghcr.io

build:
	@echo "Building local single-arch image for verification: $(IMAGE_FULL_NAME)"
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--load \
		-t $(IMAGE_SHORT_NAME) \
		--build-arg REDIS_VER=$(REDIS_VER) \
		--build-arg REVISION=$(GIT_REVISION) \
		--build-arg SHA=$(GIT_SHA) .
	#docker tag $(IMAGE_FULL_NAME)-$(PLATFORM) $(IMAGE_SHORT_NAME)-$(PLATFORM)

push:
	## login: Authenticate Docker with GitHub Container Registry
	@echo "$(CR_PAT)" | docker login ghcr.io -u "$(GITHUB_ACTOR)" --password-stdin
	@docker push $(IMAGE_SHORT_NAME)
	#docker buildx build \
	#	--platform linux/amd64,linux/arm64 \
	#	-t $(IMAGE_SHORT_NAME) \
	#	--push \
	#	--build-arg REDIS_VER=$(REDIS_VER) \
	#	--build-arg REVISION=$(GIT_REVISION) \
	#	--build-arg SHA=$(GIT_SHA) .
	# docker tag $(IMAGE_FULL_NAME) $(IMAGE_SHORT_NAME)
	docker logout ghcr.io

release: build push clean

check:
	docker run --rm \
  	-v /var/run/docker.sock:/var/run/docker.sock \
  	-v $$HOME/.cache/trivy:/root/.cache/trivy \
  	aquasec/trivy:latest image --scanners vuln,secret --severity CRITICAL,HIGH --ignore-unfixed  $(IMAGE_SHORT_NAME)

check-report:
	@docker run --rm \
  	-v /var/run/docker.sock:/var/run/docker.sock \
  	-v $$HOME/.cache/trivy:/root/.cache/trivy \
  	-v "$$(pwd)/../../../var:/workspace" \
  	aquasec/trivy:latest image --scanners vuln,secret --severity CRITICAL,HIGH --ignore-unfixed \
  	--format template \
  	--template "@/workspace/html.tpl" \
  	-o /workspace/$(SERVICE_NAME).html $(IMAGE_SHORT_NAME)

	@gsed -i 's|<style>|<style>@page { size: A4 landscape; margin: 0.5cm; } table, td, th, code, pre { word-break: break-all !important; white-space: pre-wrap !important; }|g' $$(pwd)/../../../var/$(SERVICE_NAME).html
	@docker run --rm \
	-v $$(pwd)/../../../var:/data \
	minidocks/weasyprint \
	/data/$(SERVICE_NAME).html /data/$(SERVICE_NAME).pdf

clean:
	@echo "Cleaning up dangling local Docker build cache layers..."


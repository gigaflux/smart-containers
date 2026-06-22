REGISTRY_URL=ghcr.io/gigaflux
SERVICE_NAME ?= airflow-db
PG_VER ?= 17
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

IMAGE_SHORT_NAME = $(REGISTRY_URL)/$(SERVICE_NAME):$(PG_VER)
IMAGE_FULL_NAME = $(REGISTRY_URL)/$(SERVICE_NAME):$(PG_VER)-$(GIT_REVISION)

.PHONY: build push release check clean

build:
	@echo "Building local single-arch image for verification: $(IMAGE_FULL_NAME)"
	docker buildx build \
		--platform linux/$(PLATFORM) \
		--load \
		-t $(IMAGE_FULL_NAME)-$(PLATFORM) \
		--build-arg PG_VER=$(PG_VER) \
		--build-arg REVISION=$(GIT_REVISION) \
		--build-arg SHA=$(GIT_SHA) .
	docker tag $(IMAGE_FULL_NAME)-$(PLATFORM) $(IMAGE_SHORT_NAME)-$(PLATFORM)

push:
	## login: Authenticate Docker with GitHub Container Registry
	@echo "$(CR_PAT)" | docker login ghcr.io -u "$(GITHUB_ACTOR)" --password-stdin
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		-t $(IMAGE_FULL_NAME) \
		--push \
		--build-arg PG_VER=$(PG_VER) \
		--build-arg REVISION=$(GIT_REVISION) \
		--build-arg SHA=$(GIT_SHA) .
	docker tag $(IMAGE_FULL_NAME) $(IMAGE_SHORT_NAME)
	docker logout ghcr.io

release: build push clean

check:
	docker run --rm \
  	-v /var/run/docker.sock:/var/run/docker.sock \
  	-v $$HOME/.cache/trivy:/root/.cache/trivy \
  	aquasec/trivy:latest image --scanners vuln,secret --severity CRITICAL,HIGH --ignore-unfixed  $(IMAGE_SHORT_NAME)-$(PLATFORM)

clean:
	@echo "Cleaning up dangling local Docker build cache layers..."


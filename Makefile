# !/usr/bin/make - f

SHELL                   := /usr/bin/env bash
SED                     := $(shell [[ `command -v gsed` ]] && echo gsed || echo sed)
REPO_API_URL            ?= https://hub.docker.com/v2
REPO_NAMESPACE          ?= lifthoofd
REPO_USERNAME           ?= utensils
IMAGE_NAME              ?= opengl
BASE_IMAGE              ?= alpine:3.12
LLVM_VERSION            ?= 10
TAG_SUFFIX              ?= $(shell echo "-$(BASE_IMAGE)" | $(SED) 's|:|-|g' | $(SED) 's|/|_|g' 2>/dev/null )
VCS_REF                 := $(shell git rev-parse --short HEAD)
BUILD_DATE              := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
PLATFORMS               ?= linux/amd64,linux/arm64,linux/arm/v7
RELEASES                ?= latest stable
STABLE                  ?= 20.0.6
LATEST                  ?= 20.1.2
BUILD_PROGRESS          ?= auto
BUILD_OUTPUT            ?= type=registry
BUILD_TYPE              ?= release
BUILD_OPTIMIZATION      ?= 3
MICRO_BADGER_URL        ?=

# Default target is to build all defined Mesa releases.
.PHONY: default
default: $(STABLE)

.PHONY: all
all: $(RELEASES)

# Build base images for all releases using buildx.
.PHONY: $(RELEASES)
.SILENT: $(RELEASES)
export MICRO_BADGER_URL
export BUILD_OUTPUT
$(RELEASES):
	if [ "$(@)" == "stable" ]; \
	then \
		MESA_VERSION="$(STABLE)"; \
	elif [ "$(@)" == "latest" ]; \
	then \
		MESA_VERSION="$(LATEST)"; \
	else \
		MESA_VERSION="$(@)"; \
	fi; \
	docker buildx build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_OPTIMIZATION=$(BUILD_OPTIMIZATION) \
		--build-arg BUILD_TYPE=$(BUILD_TYPE) \
		--build-arg LLVM_VERSION=$(LLVM_VERSION) \
		--build-arg MESA_VERSION="$$MESA_VERSION"  \
		--build-arg VCS_REF=$(VCS_REF) \
		--cache-from $(REPO_NAMESPACE)/$(IMAGE_NAME):$(@)$(TAG_SUFFIX) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(@)$(TAG_SUFFIX) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(@) \
		--platform=$(PLATFORMS) \
		--progress=$(BUILD_PROGRESS) \
		--output=$(BUILD_OUTPUT) \
		--file Dockerfile .
	
# Update README on DockerHub registry.
.PHONY: push-readme
.SILENT: push-readme
push-readme:
	echo "Authenticating to $(REPO_API_URL)";

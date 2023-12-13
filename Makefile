# This Makefile is meant to be used by people that do not usually work
# with Go source code. If you know what GOPATH is then you probably
# don't need to bother with make.

.PHONY: geth android ios evm all test clean

GOBIN = ./build/bin
GO ?= latest
GORUN = go run

DOCKER_REGISTRY ?= dock.getra.team
DOCKER_REPOSITORY ?= scalind/op-geth
IMAGE_TAG ?= latest

GIT_COMMIT ?= $(shell git rev-list -1 HEAD)
BUILDNUM ?= 1
VERSION ?= 0.0.1

DOCKER_PLATFORMS ?= linux/amd64,linux/arm64
TARGET ?= load

geth:
	$(GORUN) build/ci.go install ./cmd/geth
	@echo "Done building."
	@echo "Run \"$(GOBIN)/geth\" to launch geth."

all:
	$(GORUN) build/ci.go install

test: all
	$(GORUN) build/ci.go test

lint: ## Run linters.
	$(GORUN) build/ci.go lint

clean:
	go clean -cache
	rm -fr build/_workspace/pkg/ $(GOBIN)/*

# The devtools target installs tools required for 'go generate'.
# You need to put $GOBIN (or $GOPATH/bin) in your PATH to use 'go generate'.

devtools:
	env GOBIN= go install golang.org/x/tools/cmd/stringer@latest
	env GOBIN= go install github.com/fjl/gencodec@latest
	env GOBIN= go install github.com/golang/protobuf/protoc-gen-go@latest
	env GOBIN= go install ./cmd/abigen
	@type "solc" 2> /dev/null || echo 'Please install solc'
	@type "protoc" 2> /dev/null || echo 'Please install protoc'

forkdiff:
	docker run --rm \
		--mount src=$(shell pwd),target=/host-pwd,type=bind \
		protolambda/forkdiff:latest \
		-repo /host-pwd/ -fork /host-pwd/fork.yaml -out /host-pwd/forkdiff.html

docker-cloud:
	docker buildx build \
		-t $(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY):$(IMAGE_TAG) \
		--platform=$(DOCKER_PLATFORMS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(GIT_COMMIT) \
		--build-arg BUILDNUM=$(BUILDNUM) \
		$(if $(TARGET:local=),--load,--push) \
		-f Dockerfile.scalind.cloud .

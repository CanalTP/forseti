VERSION := $(shell git describe --tag --always --dirty)

.PHONY: linter-install
linter-install: ## Install linter
	curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s -- -b $(shell go env GOPATH)/bin v1.11.2

.PHONY: setup
setup: ## Install all the build and lint dependencies
	go get -u -mod readonly golang.org/x/tools/cmd/cover

.PHONY: test
test: ## Run all the tests
	echo 'mode: atomic' > coverage.txt && FIXTUREDIR=$(CURDIR)/fixtures go test -covermode=atomic -coverprofile=coverage.txt -race -timeout=30s ./...

.PHONY: fasttest
fasttest: ## Run short tests
	echo 'mode: atomic' > coverage.txt && FIXTUREDIR=$(CURDIR)/fixtures go test -short -covermode=atomic -coverprofile=coverage.txt -race -timeout=30s ./...

.PHONY: cover
cover: test ## Run all the tests and opens the coverage report
	go tool cover -html=coverage.txt

.PHONY: fmt
fmt: ## Run goimports on all go files
	find . -name '*.go' -not -wholename './vendor/*' | while read -r file; do goimports -w "$$file"; done

.PHONY: lint
lint: ## Run all the linters
	golangci-lint run -E gosec -E maligned -E misspell -E lll -E prealloc -E goimports -E unparam -E nakedret

.PHONY: ci
ci: lint test ## Run all the tests and code checks

.PHONY: build
build: ## Build a version
	CGO_ENABLED=0 go build -mod readonly -ldflags '-extldflags "-static"' -ldflags "-X github.com/CanalTP/sytralrt.SytralRTVersion=$(VERSION)" -tags=jsoniter -v ./cmd/...

.PHONY: clean
clean: ## Remove temporary files
	go clean

.PHONY: install
install: ## install project and it's dependancies, useful for autocompletion feature
	go install -i

.PHONY: version
version: ## display version of gormungandr
	@echo $(VERSION)

# Absolutely awesome: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: docker
docker: build ## build docker image
	docker build -t navitia/sytralrt:$(VERSION) .

.DEFAULT_GOAL := build

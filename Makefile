# Makefile for Gitea
# This file provides common development and build targets

.PHONY: all build clean test lint fmt vet help

# Build variables
BINARY_NAME := gitea
GO := go
GOFLAGS := -v
LDFLAGS := -s -w
BUILD_DIR := ./bin
MAIN_PKG := ./cmd/gitea

# Version info
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Inject version info into binary
LD_VERSION_FLAGS := -X main.Version=$(GIT_TAG) \
	-X main.GitCommit=$(GIT_COMMIT) \
	-X main.BuildTime=$(BUILD_TIME)

## all: Build the binary (default target)
all: build

## build: Compile the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	$(GO) build $(GOFLAGS) -ldflags "$(LDFLAGS) $(LD_VERSION_FLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PKG)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

## build-race: Build with race detector enabled
build-race:
	@echo "Building $(BINARY_NAME) with race detector..."
	@mkdir -p $(BUILD_DIR)
	$(GO) build -race $(GOFLAGS) -ldflags "$(LDFLAGS) $(LD_VERSION_FLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)-race $(MAIN_PKG)

## clean: Remove build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@$(GO) clean ./...
	@echo "Clean complete"

## test: Run all tests
test:
	@echo "Running tests..."
	$(GO) test ./... -count=1 -timeout 120s

## test-cover: Run tests with coverage report
test-cover:
	@echo "Running tests with coverage..."
	$(GO) test ./... -coverprofile=coverage.out -covermode=atomic
	$(GO) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

## lint: Run golangci-lint
lint:
	@echo "Running linter..."
	golangci-lint run ./...

## fmt: Format Go source files
fmt:
	@echo "Formatting code..."
	$(GO) fmt ./...
	goimports -w .

## vet: Run go vet
vet:
	@echo "Running go vet..."
	$(GO) vet ./...

## tidy: Tidy go modules
tidy:
	@echo "Tidying modules..."
	$(GO) mod tidy

## generate: Run go generate
generate:
	@echo "Running go generate..."
	$(GO) generate ./...

## run: Build and run the application
run: build
	@echo "Starting $(BINARY_NAME)..."
	$(BUILD_DIR)/$(BINARY_NAME) web

## dev: Run with air for live reload
dev:
	@echo "Starting development server with live reload..."
	air

## docker-build: Build Docker image
docker-build:
	@echo "Building Docker image..."
	docker build -t gitea:$(GIT_TAG) .

## help: Show this help message
help:
	@echo "Available targets:"
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'

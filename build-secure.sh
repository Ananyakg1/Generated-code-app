#!/bin/bash

# Secure Docker Build Script for Book Review Application
# This script builds the Docker image with security scanning and best practices

set -euo pipefail

# Configuration
APP_NAME="book-review-app"
APP_VERSION="1.0.0"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
REGISTRY="${DOCKER_REGISTRY:-localhost:5000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v trivy &> /dev/null; then
        log_warning "Trivy is not installed. Installing..."
        # Install trivy on Linux
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
        else
            log_error "Please install Trivy manually for security scanning"
            log_info "Visit: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
        fi
    fi
    
    log_success "Prerequisites check completed"
}

# Build the Docker image
build_image() {
    log_info "Building Docker image..."
    
    docker build \
        --build-arg BUILD_DATE="$BUILD_DATE" \
        --build-arg VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
        --tag "$APP_NAME:$APP_VERSION" \
        --tag "$APP_NAME:latest" \
        --file Dockerfile \
        .
    
    log_success "Docker image built successfully"
}

# Security scanning with Trivy
security_scan() {
    log_info "Running security scan with Trivy..."
    
    # Create reports directory
    mkdir -p security-reports
    
    # Scan for vulnerabilities
    trivy image --format json --output security-reports/trivy-report.json "$APP_NAME:$APP_VERSION"
    trivy image --format table --output security-reports/trivy-report.txt "$APP_NAME:$APP_VERSION"
    
    # Check for HIGH and CRITICAL vulnerabilities
    HIGH_CRITICAL=$(trivy image --format json "$APP_NAME:$APP_VERSION" | jq '.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH" or .Severity=="CRITICAL") | .VulnerabilityID' | wc -l)
    
    if [ "$HIGH_CRITICAL" -gt 0 ]; then
        log_warning "Found $HIGH_CRITICAL HIGH/CRITICAL vulnerabilities"
        log_info "Check security-reports/trivy-report.txt for details"
    else
        log_success "No HIGH/CRITICAL vulnerabilities found"
    fi
}

# Test the built image
test_image() {
    log_info "Testing the Docker image..."
    
    # Start container for testing
    CONTAINER_ID=$(docker run -d -p 8080:8080 --name "$APP_NAME-test" "$APP_NAME:$APP_VERSION")
    
    # Wait for application to start
    log_info "Waiting for application to start..."
    sleep 30
    
    # Health check
    if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
        log_success "Health check passed"
    else
        log_error "Health check failed"
        docker logs "$CONTAINER_ID"
        docker stop "$CONTAINER_ID"
        docker rm "$CONTAINER_ID"
        exit 1
    fi
    
    # Clean up test container
    docker stop "$CONTAINER_ID"
    docker rm "$CONTAINER_ID"
    
    log_success "Image testing completed"
}

# Generate SBOM (Software Bill of Materials)
generate_sbom() {
    log_info "Generating Software Bill of Materials (SBOM)..."
    
    mkdir -p security-reports
    
    # Generate SBOM using Trivy
    trivy image --format spdx-json --output security-reports/sbom.spdx.json "$APP_NAME:$APP_VERSION"
    
    log_success "SBOM generated: security-reports/sbom.spdx.json"
}

# Sign the image (if signing tools are available)
sign_image() {
    if command -v cosign &> /dev/null; then
        log_info "Signing Docker image with cosign..."
        cosign sign --yes "$APP_NAME:$APP_VERSION"
        log_success "Image signed successfully"
    else
        log_warning "cosign not available, skipping image signing"
        log_info "Install cosign for image signing: https://docs.sigstore.dev/cosign/installation/"
    fi
}

# Tag and push to registry (if specified)
push_image() {
    if [ "$REGISTRY" != "localhost:5000" ]; then
        log_info "Tagging image for registry: $REGISTRY"
        
        docker tag "$APP_NAME:$APP_VERSION" "$REGISTRY/$APP_NAME:$APP_VERSION"
        docker tag "$APP_NAME:latest" "$REGISTRY/$APP_NAME:latest"
        
        log_info "Pushing to registry..."
        docker push "$REGISTRY/$APP_NAME:$APP_VERSION"
        docker push "$REGISTRY/$APP_NAME:latest"
        
        log_success "Image pushed to registry"
    else
        log_info "Using local registry, skipping push"
    fi
}

# Main execution
main() {
    log_info "Starting secure Docker build for $APP_NAME v$APP_VERSION"
    
    check_prerequisites
    build_image
    security_scan
    test_image
    generate_sbom
    sign_image
    
    if [ "${PUSH_TO_REGISTRY:-false}" = "true" ]; then
        push_image
    fi
    
    log_success "Build completed successfully!"
    log_info "Image: $APP_NAME:$APP_VERSION"
    log_info "Security reports available in: security-reports/"
    
    # Display image information
    docker images | grep "$APP_NAME"
}

# Run main function
main "$@"

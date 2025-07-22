#!/bin/bash

# Kubernetes Deployment Script for Book Review Application
# This script deploys the application to Kubernetes with security best practices

set -euo pipefail

# Configuration
NAMESPACE="book-rev-namespace"
APP_NAME="book-review-app"
IMAGE_NAME="java-app"
IMAGE_TAG="${IMAGE_TAG:-latest}"
ENVIRONMENT="${ENVIRONMENT:-production}"
KUBECTL_TIMEOUT="${KUBECTL_TIMEOUT:-600s}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if we can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    log_success "kubectl is available and connected to cluster"
}

# Function to install required tools
install_tools() {
    log_info "Installing required tools..."
    
    # Install kubectl if not present
    if ! command -v kubectl &> /dev/null; then
        log_info "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    
    # Install helm if not present
    if ! command -v helm &> /dev/null; then
        log_info "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    # Install trivy for security scanning
    if ! command -v trivy &> /dev/null; then
        log_info "Installing Trivy..."
        sudo apt-get update
        sudo apt-get install wget apt-transport-https gnupg lsb-release -y
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install trivy -y
    fi
    
    # Install kube-score for security validation
    if ! command -v kube-score &> /dev/null; then
        log_info "Installing kube-score..."
        wget https://github.com/zegl/kube-score/releases/latest/download/kube-score_linux_amd64.tar.gz
        tar -xzf kube-score_linux_amd64.tar.gz
        sudo mv kube-score /usr/local/bin/
        rm kube-score_linux_amd64.tar.gz
    fi
    
    log_success "All required tools installed successfully"
}

# Function to validate Kubernetes manifests
validate_manifests() {
    log_info "Validating Kubernetes manifests..."
    
    local manifests_dir="k8s"
    local validation_failed=false
    
    # Check if manifests directory exists
    if [ ! -d "$manifests_dir" ]; then
        log_error "Manifests directory '$manifests_dir' not found"
        exit 1
    fi
    
    # Validate each YAML file
    for file in "$manifests_dir"/*.yaml; do
        if [ -f "$file" ]; then
            log_info "Validating $file..."
            
            # Basic YAML syntax validation
            if ! kubectl apply --dry-run=client -f "$file" &> /dev/null; then
                log_error "Validation failed for $file"
                validation_failed=true
            else
                log_success "✓ $file is valid"
            fi
        fi
    done
    
    if [ "$validation_failed" = true ]; then
        log_error "Manifest validation failed. Please fix the issues above."
        exit 1
    fi
    
    # Run kube-score for security validation
    log_info "Running security validation with kube-score..."
    if command -v kube-score &> /dev/null; then
        kube-score score "$manifests_dir"/*.yaml || log_warning "kube-score found some issues, review before production deployment"
    fi
    
    log_success "All manifests validated successfully"
}

# Function to create namespace
create_namespace() {
    log_info "Creating namespace '$NAMESPACE'..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_info "Namespace '$NAMESPACE' already exists"
    else
        kubectl apply -f k8s/namespace.yaml
        log_success "Namespace '$NAMESPACE' created successfully"
    fi
}

# Function to apply secrets
apply_secrets() {
    log_info "Applying secrets..."
    
    # Check if secrets already exist
    if kubectl get secret book-review-secrets -n "$NAMESPACE" &> /dev/null; then
        log_warning "Secrets already exist. Updating..."
        kubectl delete secret book-review-secrets -n "$NAMESPACE"
    fi
    
    kubectl apply -f k8s/secrets.yaml
    log_success "Secrets applied successfully"
}

# Function to apply configuration
apply_config() {
    log_info "Applying configuration..."
    
    kubectl apply -f k8s/configmap.yaml
    log_success "Configuration applied successfully"
}

# Function to deploy application
deploy_application() {
    log_info "Deploying application..."
    
    # Update image tag in deployment if specified
    if [ "$IMAGE_TAG" != "latest" ]; then
        log_info "Updating image tag to $IMAGE_TAG..."
        sed -i "s|$IMAGE_NAME:latest|$IMAGE_NAME:$IMAGE_TAG|g" k8s/deployment.yaml
    fi
    
    # Apply deployment and service
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    
    # Apply security policies
    kubectl apply -f k8s/network-policy.yaml
    kubectl apply -f k8s/security-policies.yaml
    
    # Apply monitoring configuration
    kubectl apply -f k8s/monitoring.yaml
    
    log_success "Application deployed successfully"
}

# Function to wait for deployment
wait_for_deployment() {
    log_info "Waiting for deployment to complete..."
    
    # Wait for deployment to be ready
    if kubectl rollout status deployment/"$APP_NAME" -n "$NAMESPACE" --timeout="$KUBECTL_TIMEOUT"; then
        log_success "Deployment completed successfully"
    else
        log_error "Deployment failed or timed out"
        
        # Show pod status for debugging
        log_info "Pod status:"
        kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=$APP_NAME"
        
        # Show recent events
        log_info "Recent events:"
        kubectl get events -n "$NAMESPACE" --sort-by=.metadata.creationTimestamp | tail -10
        
        exit 1
    fi
}

# Function to run health checks
run_health_checks() {
    log_info "Running health checks..."
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l "app.kubernetes.io/name=$APP_NAME" -n "$NAMESPACE" --timeout=300s
    
    # Get pod name for health check
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=$APP_NAME" -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$pod_name" ]; then
        log_error "No pods found for health check"
        exit 1
    fi
    
    # Check health endpoint
    log_info "Checking health endpoint..."
    if kubectl exec "$pod_name" -n "$NAMESPACE" -- curl -f http://localhost:8080/actuator/health &> /dev/null; then
        log_success "Health check passed"
    else
        log_error "Health check failed"
        
        # Show pod logs for debugging
        log_info "Pod logs:"
        kubectl logs "$pod_name" -n "$NAMESPACE" --tail=20
        
        exit 1
    fi
}

# Function to show deployment status
show_status() {
    log_info "Deployment Status:"
    echo
    
    # Show namespace resources
    kubectl get all -n "$NAMESPACE"
    echo
    
    # Show pod details
    log_info "Pod Details:"
    kubectl describe pods -n "$NAMESPACE" -l "app.kubernetes.io/name=$APP_NAME" | grep -E "(Name:|Status:|Ready:|Restart Count:|Image:|Node:|IP:)"
    echo
    
    # Show service endpoints
    log_info "Service Endpoints:"
    kubectl get endpoints -n "$NAMESPACE"
    echo
    
    # Show ingress if exists
    if kubectl get ingress -n "$NAMESPACE" &> /dev/null; then
        log_info "Ingress:"
        kubectl get ingress -n "$NAMESPACE"
        echo
    fi
}

# Function to setup monitoring
setup_monitoring() {
    log_info "Setting up monitoring..."
    
    # Check if Prometheus operator is available
    if kubectl get crd servicemonitors.monitoring.coreos.com &> /dev/null; then
        log_info "Prometheus operator detected, applying ServiceMonitor..."
        kubectl apply -f k8s/monitoring.yaml
        log_success "Monitoring configuration applied"
    else
        log_warning "Prometheus operator not found, skipping ServiceMonitor creation"
    fi
}

# Function to cleanup on failure
cleanup_on_failure() {
    log_error "Deployment failed. Starting cleanup..."
    
    # Scale down deployment to 0
    kubectl scale deployment "$APP_NAME" --replicas=0 -n "$NAMESPACE" &> /dev/null || true
    
    # Wait a bit for pods to terminate
    sleep 10
    
    # Show final status
    kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=$APP_NAME"
    
    log_error "Deployment rolled back due to failure"
    exit 1
}

# Function to perform rollback
rollback_deployment() {
    log_warning "Performing rollback..."
    
    # Get previous revision
    local previous_revision
    previous_revision=$(kubectl rollout history deployment/"$APP_NAME" -n "$NAMESPACE" | grep -E "^[0-9]+" | tail -2 | head -1 | awk '{print $1}')
    
    if [ -n "$previous_revision" ]; then
        log_info "Rolling back to revision $previous_revision..."
        kubectl rollout undo deployment/"$APP_NAME" -n "$NAMESPACE" --to-revision="$previous_revision"
        
        # Wait for rollback to complete
        kubectl rollout status deployment/"$APP_NAME" -n "$NAMESPACE" --timeout=300s
        
        log_success "Rollback completed successfully"
    else
        log_error "No previous revision found for rollback"
        cleanup_on_failure
    fi
}

# Main deployment function
main() {
    log_info "Starting Kubernetes deployment for Book Review Application"
    log_info "Environment: $ENVIRONMENT"
    log_info "Namespace: $NAMESPACE"
    log_info "Image: $IMAGE_NAME:$IMAGE_TAG"
    echo
    
    # Set error handler
    trap 'log_error "Deployment failed at line $LINENO"; cleanup_on_failure' ERR
    
    # Install required tools
    install_tools
    
    # Check prerequisites
    check_kubectl
    
    # Validate manifests
    validate_manifests
    
    # Create namespace
    create_namespace
    
    # Apply secrets
    apply_secrets
    
    # Apply configuration
    apply_config
    
    # Deploy application
    deploy_application
    
    # Setup monitoring
    setup_monitoring
    
    # Wait for deployment to complete
    wait_for_deployment
    
    # Run health checks
    run_health_checks
    
    # Show final status
    show_status
    
    log_success "✅ Book Review Application deployed successfully!"
    log_info "Access the application at: http://$(kubectl get svc book-review-app-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'localhost'):8080"
    
    echo
    log_info "Useful commands:"
    echo "  View pods:     kubectl get pods -n $NAMESPACE"
    echo "  View logs:     kubectl logs -f deployment/$APP_NAME -n $NAMESPACE"
    echo "  Port forward:  kubectl port-forward svc/book-review-app-service 8080:80 -n $NAMESPACE"
    echo "  Scale app:     kubectl scale deployment $APP_NAME --replicas=5 -n $NAMESPACE"
    echo "  Delete app:    kubectl delete namespace $NAMESPACE"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --image-tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --image-tag TAG       Docker image tag to deploy (default: latest)"
            echo "  --environment ENV     Deployment environment (default: production)"
            echo "  --namespace NS        Kubernetes namespace (default: book-rev-namespace)"
            echo "  --help, -h            Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main

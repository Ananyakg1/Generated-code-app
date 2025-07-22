# Book Review Application - Kubernetes Deployment Guide

This document provides comprehensive instructions for deploying the Book Review Application to Kubernetes with enterprise-grade security practices.

## 🏗️ Architecture Overview

The Kubernetes deployment includes:

- **Namespace Isolation**: Dedicated `book-rev-namespace` with resource quotas
- **Security Context**: Non-root execution with dropped capabilities
- **Network Policies**: Strict ingress/egress traffic control
- **Resource Management**: CPU/Memory limits and requests
- **High Availability**: 3 replicas with anti-affinity rules
- **Health Monitoring**: Comprehensive health checks and monitoring
- **Configuration Management**: ConfigMaps and Secrets for secure configuration

## 📋 Prerequisites

### Local Development
- Docker Desktop with Kubernetes enabled
- kubectl CLI tool
- Helm (optional, for package management)

### Production Deployment
- Kubernetes cluster (EKS, GKE, AKS, or on-premises)
- kubectl configured with cluster access
- Container registry access (GitHub Container Registry, ECR, etc.)
- Storage class for persistent volumes

## 🛡️ Security Features

### Pod Security
- **Non-root execution**: Runs as user ID 1001
- **Read-only root filesystem**: Prevents runtime modifications
- **Dropped capabilities**: ALL capabilities dropped, only essential ones added
- **Security context**: Comprehensive security policies applied
- **Resource limits**: Prevents resource exhaustion attacks

### Network Security
- **Network policies**: Strict ingress/egress rules
- **Service isolation**: ClusterIP services for internal communication
- **Traffic encryption**: TLS termination at ingress level

### Configuration Security
- **Secrets management**: Sensitive data in Kubernetes secrets
- **ConfigMap separation**: Non-sensitive configuration separate from secrets
- **Environment variable injection**: Secure configuration loading

## 📁 Project Structure

```
k8s/
├── namespace.yaml           # Namespace with resource quotas
├── configmap.yaml          # Application configuration
├── secrets.yaml            # Sensitive configuration
├── deployment.yaml         # Application deployment
├── service.yaml            # Service definitions
├── network-policy.yaml     # Network security policies
├── security-policies.yaml  # Pod security policies and HPA
└── monitoring.yaml         # Monitoring and ingress configuration
```

## 🚀 Quick Start

### 1. Using GitHub Actions (Recommended)

The repository includes a comprehensive GitHub Actions workflow that handles:
- Docker image building and security scanning
- Kubernetes manifest validation
- Automated deployment to staging/production
- Health checks and rollback capabilities

```yaml
# Trigger deployment
git push origin main  # Deploys to production
git push origin develop  # Deploys to staging
```

### 2. Manual Deployment

#### Windows
```cmd
# Deploy using the Windows batch script
deploy-k8s.bat --environment production --image-tag latest

# Or with custom parameters
deploy-k8s.bat --image-tag v1.2.3 --namespace my-namespace
```

#### Linux/macOS
```bash
# Make script executable
chmod +x deploy-k8s.sh

# Deploy using the shell script
./deploy-k8s.sh --environment production --image-tag latest

# Or with custom parameters
./deploy-k8s.sh --image-tag v1.2.3 --namespace my-namespace
```

#### kubectl (Manual)
```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply configuration
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml

# Deploy application
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Apply security policies
kubectl apply -f k8s/network-policy.yaml
kubectl apply -f k8s/security-policies.yaml

# Setup monitoring
kubectl apply -f k8s/monitoring.yaml

# Wait for deployment
kubectl rollout status deployment/book-review-app -n book-rev-namespace
```

## 🔧 Configuration

### Environment Variables

The application supports the following configuration through ConfigMaps:

```yaml
# Database Configuration
SPRING_DATASOURCE_URL: "jdbc:h2:file:/app/data/bookreviews"
SPRING_DATASOURCE_USERNAME: "sa"

# Server Configuration  
SERVER_PORT: "8080"
SPRING_PROFILES_ACTIVE: "production,docker"

# JVM Tuning
JAVA_OPTS: "-Xms256m -Xmx512m -XX:+UseContainerSupport"

# Logging
LOGGING_LEVEL_ROOT: "INFO"
LOGGING_LEVEL_COM_BOOKREVIEW: "INFO"
```

### Secrets

Sensitive configuration is stored in Kubernetes secrets:

```bash
# Database password
DB_PASSWORD: <base64-encoded-password>

# Application keys
APP_SECRET_KEY: <base64-encoded-secret>
ENCRYPTION_KEY: <base64-encoded-key>
```

To create/update secrets:
```bash
# Create secret from literal values
kubectl create secret generic book-review-secrets \
  --from-literal=db-password='YourSecurePassword' \
  --from-literal=app-secret-key='YourSecretKey' \
  --from-literal=encryption-key='YourEncryptionKey' \
  -n book-rev-namespace

# Or apply from YAML (already base64 encoded)
kubectl apply -f k8s/secrets.yaml
```

## 📊 Monitoring and Observability

### Health Checks

The application provides comprehensive health endpoints:

```bash
# Application health
curl http://service-ip:8080/actuator/health

# Readiness check
curl http://service-ip:8080/actuator/health/readiness

# Liveness check  
curl http://service-ip:8080/actuator/health/liveness

# Metrics (Prometheus format)
curl http://service-ip:8080/actuator/prometheus
```

### Monitoring Setup

If Prometheus Operator is installed:

```bash
# ServiceMonitor will be automatically created
kubectl get servicemonitor -n book-rev-namespace
```

### Logging

View application logs:

```bash
# View logs from all pods
kubectl logs -l app.kubernetes.io/name=book-review-app -n book-rev-namespace

# Follow logs in real-time
kubectl logs -f deployment/book-review-app -n book-rev-namespace

# View logs from specific pod
kubectl logs <pod-name> -n book-rev-namespace
```

## 🔄 Scaling and Updates

### Horizontal Scaling

The deployment includes a Horizontal Pod Autoscaler (HPA):

```bash
# View HPA status
kubectl get hpa -n book-rev-namespace

# Manual scaling
kubectl scale deployment book-review-app --replicas=5 -n book-rev-namespace
```

### Rolling Updates

Deploy new version:

```bash
# Update image
kubectl set image deployment/book-review-app \
  book-review-app=java-app:v1.2.3 \
  -n book-rev-namespace

# Monitor rollout
kubectl rollout status deployment/book-review-app -n book-rev-namespace

# Rollback if needed
kubectl rollout undo deployment/book-review-app -n book-rev-namespace
```

## 🌐 Ingress and External Access

### Port Forward (Development)

```bash
# Forward local port to service
kubectl port-forward svc/book-review-app-service 8080:80 -n book-rev-namespace

# Access application
open http://localhost:8080
```

### Ingress Controller (Production)

The deployment includes an Ingress resource for production:

```bash
# Check ingress status
kubectl get ingress -n book-rev-namespace

# Get ingress IP
kubectl get ingress book-review-app-ingress -n book-rev-namespace \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

For HTTPS/TLS:
1. Install cert-manager in your cluster
2. Configure DNS to point to your ingress IP
3. Update the ingress hostname in `k8s/monitoring.yaml`

## 🔒 Security Best Practices

### Network Policies

The deployment includes strict network policies:

- **Default deny all**: All traffic blocked by default
- **Selective ingress**: Only required ports and sources allowed
- **Egress restrictions**: Limited external communication
- **Namespace isolation**: Traffic isolated within namespace

### Pod Security

- **Security context**: Non-root user, read-only filesystem
- **Resource limits**: CPU/Memory constraints prevent resource exhaustion  
- **Capability dropping**: Minimal required capabilities
- **Service account**: Dedicated service account with minimal permissions

### Secret Management

- **Base64 encoding**: All secrets base64 encoded
- **Separate secret resources**: Sensitive data in dedicated secrets
- **Environment variable injection**: Secure configuration loading
- **Regular rotation**: Plan for secret rotation

## 🛠️ Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n book-rev-namespace

# Describe pod for events
kubectl describe pod <pod-name> -n book-rev-namespace

# Check logs
kubectl logs <pod-name> -n book-rev-namespace
```

#### Image Pull Issues

```bash
# Check image pull secrets
kubectl get secrets -n book-rev-namespace

# Verify image name and tag
kubectl describe pod <pod-name> -n book-rev-namespace | grep Image
```

#### Network Connectivity

```bash
# Test service connectivity
kubectl exec <pod-name> -n book-rev-namespace -- curl http://book-review-app-service

# Check network policies
kubectl get networkpolicy -n book-rev-namespace
```

#### Resource Issues

```bash
# Check resource usage
kubectl top pods -n book-rev-namespace
kubectl top nodes

# Check resource quotas
kubectl describe quota -n book-rev-namespace
```

### Health Check Failures

```bash
# Test health endpoint manually
kubectl exec <pod-name> -n book-rev-namespace -- curl http://localhost:8080/actuator/health

# Check application logs
kubectl logs <pod-name> -n book-rev-namespace | grep ERROR
```

### Performance Issues

```bash
# Check HPA status
kubectl get hpa -n book-rev-namespace

# View metrics
kubectl top pods -n book-rev-namespace

# Scale manually if needed
kubectl scale deployment book-review-app --replicas=10 -n book-rev-namespace
```

## 🔧 Customization

### Resource Requirements

Adjust resource limits in `k8s/deployment.yaml`:

```yaml
resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Replica Count

Modify replica count:

```yaml
spec:
  replicas: 3  # Change as needed
```

### Environment-Specific Configuration

Create environment-specific versions:

```bash
# Copy base files
cp k8s/deployment.yaml k8s/deployment-staging.yaml

# Modify for staging environment
# Update image tags, resource limits, etc.
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-kubernetes/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Prometheus Monitoring](https://prometheus.io/docs/)

## 🆘 Support

For deployment issues:

1. Check the troubleshooting section above
2. Review pod logs and events
3. Verify cluster resources and permissions
4. Consult Kubernetes documentation for specific error messages

The deployment scripts provide detailed logging and error handling to help identify and resolve issues quickly.

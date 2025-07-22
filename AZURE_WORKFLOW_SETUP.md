# Azure AKS Deployment Workflow - Setup Guide

This document provides comprehensive setup instructions for the GitHub Actions workflow that builds, scans, and deploys your Java Book Review application to Azure Kubernetes Service (AKS).

## 🏗️ Workflow Architecture

The workflow consists of three main jobs:

### 1. **Build Job**
- ✅ Compiles and tests Java application with Maven
- ✅ Installs Azure CLI, kubectl, Helm, and Trivy
- ✅ Builds multi-platform Docker image (AMD64/ARM64)  
- ✅ Performs comprehensive security scanning with Trivy
- ✅ Pushes image to Azure Container Registry
- ✅ Generates SBOM (Software Bill of Materials)
- ✅ Uploads security reports to GitHub Security tab

### 2. **Deploy Job**
- ✅ Connects to AKS cluster
- ✅ Updates Kubernetes manifests with new image tag
- ✅ Deploys to `flask-app-namespace` 
- ✅ Runs comprehensive health checks
- ✅ Provides automatic rollback on failure
- ✅ Generates deployment summary

### 3. **Notification Job**
- ✅ Sends deployment status notifications
- ✅ Reports build and deployment results

## 🔧 Prerequisites Setup

### 1. Azure Resources Required

You need the following Azure resources set up:

#### Azure Container Registry (ACR)
```bash
# Create resource group
az group create --name myResourceGroup --location eastus

# Create ACR
az acr create --resource-group myResourceGroup --name myregistry --sku Basic
```

#### Azure Kubernetes Service (AKS)
```bash
# Create AKS cluster
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-count 3 \
    --enable-managed-identity \
    --attach-acr myregistry
```

#### Service Principal for GitHub Actions
```bash
# Create service principal
az ad sp create-for-rbac --name "github-actions-sp" \
    --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group}

# Output will include:
# - appId (AZURE_CLIENT_ID)
# - password (AZURE_CLIENT_SECRET)  
# - tenant (AZURE_TENANT_ID)
```

### 2. GitHub Repository Secrets Configuration

Configure these secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AZURE_CLIENT_ID` | Service Principal Application ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_CLIENT_SECRET` | Service Principal Password | `your-secret-password` |
| `AZURE_SUSCRIPTION_ID` | Azure Subscription ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | Azure Tenant ID | `12345678-1234-1234-1234-123456789012` |
| `REGISTRY_LOGIN_SERVER` | ACR Login Server | `myregistry.azurecr.io` |
| `REGISTRY_USERNAME` | ACR Username | `myregistry` |
| `REGISTRY_PASSWORD` | ACR Password | `your-acr-password` |
| `AKS_CLUSTER_NAME` | AKS Cluster Name | `myAKSCluster` |
| `AKS_RESOURCE_GROUP` | AKS Resource Group | `myResourceGroup` |

#### Getting ACR Credentials
```bash
# Get ACR login server
az acr show --name myregistry --query loginServer --output tsv

# Get ACR credentials
az acr credential show --name myregistry
```

## 🚀 Workflow Features

### Build ID and Image Tagging
The workflow generates unique build IDs using:
```
{GITHUB_RUN_NUMBER}-{TIMESTAMP}-{SHORT_SHA}
```
Example: `123-20240722150530-a1b2c3d4`

### Trivy Security Scanning
The workflow implements comprehensive security scanning with:

#### Manual Trivy Installation
```bash
sudo apt-get install trivy -y
```

#### Trivy Scan Configuration
- **Action Version**: `aquasecurity/trivy-action@0.28.0`
- **Formats**: Both `table` (console) and `sarif` (GitHub Security)
- **Exit Code**: `1` for CRITICAL/HIGH vulnerabilities
- **Ignore Unfixed**: `true`
- **Severity Levels**: `CRITICAL,HIGH`
- **Timeout**: `10m`

#### Security Reports Generated
1. **SARIF Report**: Uploaded to GitHub Security tab
2. **JSON Report**: Detailed vulnerability information
3. **Summary Report**: Markdown summary with counts
4. **SBOM**: Software Bill of Materials (CycloneDX and SPDX formats)

### Deployment Features

#### Namespace Management
- Deploys to existing `flask-app-namespace`
- Creates namespace if it doesn't exist
- Verifies resources before deployment

#### Health Checks
- Pod readiness checks with 5-minute timeout
- Application health endpoint testing (`/actuator/health`)
- Port-forward testing for validation
- Comprehensive logging on failure

#### Rollback Strategy
- Automatic rollback on deployment failure
- Previous revision detection and restoration
- Graceful degradation with scaling to zero

## 🎯 Workflow Triggers

### Automatic Triggers
- **Push to main**: Deploys to production
- **Push to develop**: Deploys to staging  
- **Pull Request to main**: Runs build and security scan only

### Manual Triggers
```yaml
workflow_dispatch:
  inputs:
    environment:
      description: 'Deployment environment'
      required: true
      default: 'staging'
      type: choice
      options: [staging, production]
    skip_security_scan:
      description: 'Skip security scan for testing'
      required: false
      default: false
      type: boolean
```

## 📊 Workflow Outputs and Artifacts

### Build Outputs
- `image-tag`: Unique build ID used as image tag
- `image-full`: Complete image reference with registry
- `build-id`: Build identifier for tracking

### Generated Artifacts
- **Security Reports**: SARIF, JSON, and summary reports
- **SBOM Files**: CycloneDX and SPDX formats
- **Deployment Summary**: Comprehensive deployment status
- **Build Logs**: Detailed execution logs

### Artifact Retention
- Security reports: 30 days
- SBOM files: 90 days  
- Deployment summaries: 30 days

## 🛠️ Customization Options

### Environment-Specific Configuration

#### Staging Environment
```yaml
environment:
  name: staging
  url: ${{ steps.deployment-info.outputs.app-url }}
```

#### Production Environment  
```yaml
environment:
  name: production
  url: ${{ steps.deployment-info.outputs.app-url }}
```

### Resource Customization

#### Java Version
```yaml
env:
  JAVA_VERSION: '17'  # Change to '11', '17', '21', etc.
```

#### Image Name
```yaml
env:
  IMAGE_NAME: book-review-app  # Change to your preferred name
```

#### Namespace
```yaml
env:
  NAMESPACE: flask-app-namespace  # Change to your target namespace
```

### Security Scan Customization

#### Trivy Severity Levels
```bash
# Current: CRITICAL,HIGH
# Options: UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL
--severity CRITICAL,HIGH,MEDIUM
```

#### Scan Timeout
```bash
# Current: 10m
# Options: 1m, 5m, 10m, 30m
--timeout 30m
```

## 🔍 Monitoring and Debugging

### View Workflow Status
1. Go to **Actions** tab in GitHub repository
2. Click on workflow run to see detailed logs
3. Check individual job logs for troubleshooting

### Security Scan Results
1. Go to **Security** tab in GitHub repository
2. Click **Code scanning alerts**
3. Review Trivy scan results and vulnerabilities

### Deployment Status
1. Check workflow artifacts for deployment summary
2. Connect to AKS cluster to verify deployment
3. Use kubectl commands for troubleshooting

### Common Troubleshooting Commands

#### Check Deployment Status
```bash
kubectl get deployments -n flask-app-namespace
kubectl get pods -n flask-app-namespace
kubectl logs -l app.kubernetes.io/name=book-review-app -n flask-app-namespace
```

#### Test Application Health
```bash
kubectl port-forward service/book-review-app-service 8080:80 -n flask-app-namespace
curl http://localhost:8080/actuator/health
```

#### Check Image Pull Status
```bash
kubectl describe pod <pod-name> -n flask-app-namespace
```

## 🚨 Security Best Practices

### Secret Management
- Never commit secrets to repository
- Use GitHub repository secrets for sensitive data
- Regularly rotate service principal credentials
- Monitor access logs and permissions

### Image Security
- All images scanned for vulnerabilities before deployment
- Critical/High vulnerabilities block deployment
- SBOM generated for supply chain transparency
- Multi-platform builds for compatibility

### Kubernetes Security
- Deployments use security contexts and policies
- Network policies restrict traffic
- Resource limits prevent resource exhaustion
- Health checks ensure application readiness

## 📈 Performance Optimization

### Build Performance
- Maven dependency caching enabled
- Docker layer caching with Buildx
- Multi-platform builds optimized
- Parallel job execution where possible

### Deployment Performance  
- Rolling updates with zero downtime
- Health checks with appropriate timeouts
- Resource limits for predictable performance
- Horizontal Pod Autoscaler (HPA) support

## 🆘 Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Azure Login Failed
```bash
# Solution: Verify service principal credentials
az login --service-principal --username $CLIENT_ID --password $CLIENT_SECRET --tenant $TENANT_ID
```

#### Issue: ACR Authentication Failed
```bash
# Solution: Check ACR credentials and permissions
az acr login --name myregistry
```

#### Issue: AKS Connection Failed
```bash
# Solution: Verify AKS cluster access
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
kubectl cluster-info
```

#### Issue: Security Scan Failure
- Check if image was built successfully
- Verify Trivy installation and configuration
- Review vulnerability thresholds
- Check network connectivity for vulnerability database updates

#### Issue: Deployment Failure
- Verify Kubernetes manifests syntax
- Check namespace permissions
- Review resource limits and quotas
- Validate image pull permissions

### Getting Help
1. Check workflow logs for detailed error messages
2. Review GitHub Actions documentation
3. Consult Azure AKS and ACR documentation
4. Check Trivy documentation for security scanning issues

## ✅ Workflow Validation Checklist

Before using the workflow, ensure:

- [ ] All Azure resources are created and configured
- [ ] Service principal has appropriate permissions
- [ ] All GitHub secrets are configured correctly
- [ ] Kubernetes manifests are present in `k8s/` directory
- [ ] Dockerfile is present and builds successfully
- [ ] Target namespace exists or can be created
- [ ] ACR has sufficient storage and permissions

## 🎉 Success Indicators

A successful workflow run will show:

- ✅ Java application builds without errors
- ✅ All tests pass successfully
- ✅ Docker image builds and pushes to ACR
- ✅ Security scan completes with acceptable results
- ✅ SBOM and security reports generated
- ✅ Deployment completes successfully
- ✅ Health checks pass
- ✅ Application is accessible

The workflow provides comprehensive automation for building, securing, and deploying your Java application to Azure AKS with enterprise-grade security practices!

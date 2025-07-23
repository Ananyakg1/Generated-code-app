# Azure Deployment Troubleshooting Guide

This document provides solutions for common Azure deployment issues encountered in the GitHub Actions workflow.

## 🚨 Common Issues and Solutions

### 1. **Subscription ID Error: "The subscription of '' doesn't exist"**

**Error Message:**
```
ERROR: The subscription of '' doesn't exist in cloud 'AzureCloud'.
```

**Root Cause:** The `AZURE_SUBSCRIPTION_ID` secret is empty or incorrectly named.

**Solutions:**

#### Option A: Verify GitHub Secret Name
Ensure your GitHub secret is named exactly:
```
AZURE_SUBSCRIPTION_ID
```
(Not `AZURE_SUSCRIPTION_ID` - note the correct spelling)

#### Option B: Get Your Subscription ID
```bash
# List all subscriptions
az account list --output table

# Get current subscription
az account show --query id --output tsv
```

#### Option C: Set the Secret in GitHub
1. Go to your repository
2. Settings → Secrets and variables → Actions
3. Add/update the secret `AZURE_SUBSCRIPTION_ID` with your subscription ID

### 2. **Service Principal Authentication Failed**

**Error Message:**
```
AADSTS70002: Error validating credentials
```

**Solutions:**

#### Check Service Principal Credentials
```bash
# Test login locally
az login --service-principal \
  --username YOUR_CLIENT_ID \
  --password YOUR_CLIENT_SECRET \
  --tenant YOUR_TENANT_ID
```

#### Verify Required Secrets
Ensure all secrets are set correctly:
- `AZURE_CLIENT_ID` - Application (client) ID
- `AZURE_CLIENT_SECRET` - Client secret value
- `AZURE_TENANT_ID` - Directory (tenant) ID
- `AZURE_SUBSCRIPTION_ID` - Subscription ID

#### Create New Service Principal (if needed)
```bash
az ad sp create-for-rbac \
  --name "github-actions-book-review" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

### 3. **Container Registry Authentication Failed**

**Error Message:**
```
Error: denied: access forbidden
```

**Solutions:**

#### Get ACR Credentials
```bash
# Get ACR login server
az acr show --name YOUR_REGISTRY_NAME --query loginServer --output tsv

# Get ACR credentials
az acr credential show --name YOUR_REGISTRY_NAME
```

#### Verify ACR Secrets
- `REGISTRY_LOGIN_SERVER` - e.g., `myregistry.azurecr.io`
- `REGISTRY_USERNAME` - Usually the registry name
- `REGISTRY_PASSWORD` - Admin password from ACR

#### Enable ACR Admin User
```bash
az acr update --name YOUR_REGISTRY_NAME --admin-enabled true
```

### 4. **AKS Cluster Access Denied**

**Error Message:**
```
Error: Unauthorized
```

**Solutions:**

#### Grant AKS Permissions
```bash
# Assign Azure Kubernetes Service Cluster Admin Role
az role assignment create \
  --assignee YOUR_CLIENT_ID \
  --role "Azure Kubernetes Service Cluster Admin Role" \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.ContainerService/managedClusters/{cluster-name}
```

#### Verify AKS Secrets
- `AKS_CLUSTER_NAME` - Name of your AKS cluster
- `AKS_RESOURCE_GROUP` - Resource group containing the cluster

### 5. **Image Pull Errors in Kubernetes**

**Error Message:**
```
ErrImagePull or ImagePullBackOff
```

**Solutions:**

#### Check Image Name and Tag
Verify the image reference is correct:
```bash
# Check if image exists in ACR
az acr repository list --name YOUR_REGISTRY_NAME --output table
az acr repository show-tags --name YOUR_REGISTRY_NAME --repository book-review-app
```

#### Attach ACR to AKS
```bash
az aks update \
  --name YOUR_CLUSTER_NAME \
  --resource-group YOUR_RESOURCE_GROUP \
  --attach-acr YOUR_REGISTRY_NAME
```

### 6. **Health Check Failures**

**Error Message:**
```
Health check failed after 5 attempts
```

**Solutions:**

#### Check Pod Status
```bash
kubectl get pods -n flask-app-namespace
kubectl describe pod POD_NAME -n flask-app-namespace
kubectl logs POD_NAME -n flask-app-namespace
```

#### Verify Health Endpoint
```bash
# Port forward to test locally
kubectl port-forward svc/book-review-app-service 8080:80 -n flask-app-namespace
curl http://localhost:8080/actuator/health
```

### 7. **Namespace Issues**

**Error Message:**
```
namespace "flask-app-namespace" not found
```

**Solutions:**

#### Create Namespace Manually
```bash
kubectl create namespace flask-app-namespace
```

#### Verify Namespace in Workflow
Check that the workflow uses the correct namespace:
```yaml
env:
  NAMESPACE: flask-app-namespace
```

## 🔧 Debugging Commands

### Azure CLI Debug Commands
```bash
# Check current account
az account show

# List subscriptions
az account list

# Test ACR access
az acr login --name YOUR_REGISTRY_NAME

# Test AKS access
az aks get-credentials --resource-group YOUR_RESOURCE_GROUP --name YOUR_CLUSTER_NAME
```

### Kubectl Debug Commands
```bash
# Check cluster connection
kubectl cluster-info

# List all resources in namespace
kubectl get all -n flask-app-namespace

# Check events
kubectl get events -n flask-app-namespace --sort-by=.metadata.creationTimestamp

# Describe deployment
kubectl describe deployment book-review-app -n flask-app-namespace
```

### Docker Registry Debug Commands
```bash
# Test image pull
docker pull YOUR_REGISTRY_NAME.azurecr.io/book-review-app:latest

# List images in ACR
az acr repository list --name YOUR_REGISTRY_NAME
```

## 📋 Pre-Deployment Checklist

Before running the workflow, verify:

- [ ] All GitHub secrets are configured correctly
- [ ] Service principal has required permissions
- [ ] ACR admin user is enabled
- [ ] AKS cluster is accessible
- [ ] Target namespace exists or can be created
- [ ] Docker image builds locally
- [ ] Kubernetes manifests are valid

## 🆘 Quick Fixes

### Update All Secrets at Once
Use this template to verify all your secrets:

```bash
# Get all required values
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
TENANT_ID=$(az account show --query tenantId --output tsv)
# CLIENT_ID and CLIENT_SECRET from service principal creation
# REGISTRY values from ACR
# AKS values from cluster creation

echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
# Add others manually to GitHub secrets
```

### Reset Service Principal
```bash
# Delete old service principal
az ad sp delete --id YOUR_CLIENT_ID

# Create new one
az ad sp create-for-rbac \
  --name "github-actions-book-review-new" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

## 📞 Getting Help

If issues persist:

1. **Check GitHub Actions logs** for detailed error messages
2. **Test commands locally** using Azure CLI
3. **Verify permissions** for service principal
4. **Review Azure resource status** in Azure Portal
5. **Check Kubernetes cluster health** using kubectl

Remember: The key to successful debugging is testing each component (Azure CLI, ACR, AKS) individually before running the full workflow!

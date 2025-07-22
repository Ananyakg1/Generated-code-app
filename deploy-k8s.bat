@echo off
REM Kubernetes Deployment Script for Book Review Application (Windows)
REM This script deploys the application to Kubernetes with security best practices

setlocal enabledelayedexpansion

REM Configuration
set NAMESPACE=book-rev-namespace
set APP_NAME=book-review-app
set IMAGE_NAME=java-app
if "%IMAGE_TAG%"=="" set IMAGE_TAG=latest
if "%ENVIRONMENT%"=="" set ENVIRONMENT=production
if "%KUBECTL_TIMEOUT%"=="" set KUBECTL_TIMEOUT=600s

REM Colors for output (Windows)
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

REM Logging functions
:log_info
echo %BLUE%[INFO]%NC% %~1
goto :eof

:log_success
echo %GREEN%[SUCCESS]%NC% %~1
goto :eof

:log_warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:log_error
echo %RED%[ERROR]%NC% %~1
goto :eof

REM Function to check if kubectl is available
:check_kubectl
call :log_info "Checking kubectl availability..."

kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "kubectl is not installed. Please install kubectl first."
    exit /b 1
)

kubectl cluster-info >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit /b 1
)

call :log_success "kubectl is available and connected to cluster"
goto :eof

REM Function to install required tools
:install_tools
call :log_info "Installing required tools..."

REM Check for Chocolatey and install tools
where choco >nul 2>&1
if %errorlevel% neq 0 (
    call :log_warning "Chocolatey not found. Please install kubectl, helm, and other tools manually."
    goto :eof
)

REM Install kubectl if not present
kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    call :log_info "Installing kubectl..."
    choco install kubernetes-cli -y
)

REM Install helm if not present
helm version >nul 2>&1
if %errorlevel% neq 0 (
    call :log_info "Installing Helm..."
    choco install kubernetes-helm -y
)

call :log_success "Required tools check completed"
goto :eof

REM Function to validate Kubernetes manifests
:validate_manifests
call :log_info "Validating Kubernetes manifests..."

set manifests_dir=k8s
set validation_failed=false

if not exist "%manifests_dir%" (
    call :log_error "Manifests directory '%manifests_dir%' not found"
    exit /b 1
)

for %%f in ("%manifests_dir%\*.yaml") do (
    call :log_info "Validating %%f..."
    kubectl apply --dry-run=client -f "%%f" >nul 2>&1
    if !errorlevel! neq 0 (
        call :log_error "Validation failed for %%f"
        set validation_failed=true
    ) else (
        call :log_success "✓ %%f is valid"
    )
)

if "%validation_failed%"=="true" (
    call :log_error "Manifest validation failed. Please fix the issues above."
    exit /b 1
)

call :log_success "All manifests validated successfully"
goto :eof

REM Function to create namespace
:create_namespace
call :log_info "Creating namespace '%NAMESPACE%'..."

kubectl get namespace %NAMESPACE% >nul 2>&1
if %errorlevel% equ 0 (
    call :log_info "Namespace '%NAMESPACE%' already exists"
) else (
    kubectl apply -f k8s\namespace.yaml
    call :log_success "Namespace '%NAMESPACE%' created successfully"
)
goto :eof

REM Function to apply secrets
:apply_secrets
call :log_info "Applying secrets..."

kubectl get secret book-review-secrets -n %NAMESPACE% >nul 2>&1
if %errorlevel% equ 0 (
    call :log_warning "Secrets already exist. Updating..."
    kubectl delete secret book-review-secrets -n %NAMESPACE%
)

kubectl apply -f k8s\secrets.yaml
call :log_success "Secrets applied successfully"
goto :eof

REM Function to apply configuration
:apply_config
call :log_info "Applying configuration..."

kubectl apply -f k8s\configmap.yaml
call :log_success "Configuration applied successfully"
goto :eof

REM Function to deploy application
:deploy_application
call :log_info "Deploying application..."

REM Update image tag in deployment if specified
if not "%IMAGE_TAG%"=="latest" (
    call :log_info "Updating image tag to %IMAGE_TAG%..."
    powershell -Command "(Get-Content k8s\deployment.yaml) -replace '%IMAGE_NAME%:latest', '%IMAGE_NAME%:%IMAGE_TAG%' | Set-Content k8s\deployment.yaml"
)

REM Apply deployment and service
kubectl apply -f k8s\deployment.yaml
kubectl apply -f k8s\service.yaml

REM Apply security policies
kubectl apply -f k8s\network-policy.yaml
kubectl apply -f k8s\security-policies.yaml

REM Apply monitoring configuration
kubectl apply -f k8s\monitoring.yaml

call :log_success "Application deployed successfully"
goto :eof

REM Function to wait for deployment
:wait_for_deployment
call :log_info "Waiting for deployment to complete..."

kubectl rollout status deployment/%APP_NAME% -n %NAMESPACE% --timeout=%KUBECTL_TIMEOUT%
if %errorlevel% equ 0 (
    call :log_success "Deployment completed successfully"
) else (
    call :log_error "Deployment failed or timed out"
    
    call :log_info "Pod status:"
    kubectl get pods -n %NAMESPACE% -l "app.kubernetes.io/name=%APP_NAME%"
    
    call :log_info "Recent events:"
    kubectl get events -n %NAMESPACE% --sort-by=.metadata.creationTimestamp
    
    exit /b 1
)
goto :eof

REM Function to run health checks
:run_health_checks
call :log_info "Running health checks..."

kubectl wait --for=condition=ready pod -l "app.kubernetes.io/name=%APP_NAME%" -n %NAMESPACE% --timeout=300s
if %errorlevel% neq 0 (
    call :log_error "Pods failed to become ready"
    exit /b 1
)

REM Get pod name for health check
for /f "tokens=*" %%i in ('kubectl get pods -n %NAMESPACE% -l "app.kubernetes.io/name=%APP_NAME%" -o jsonpath^="{.items[0].metadata.name}"') do set pod_name=%%i

if "%pod_name%"=="" (
    call :log_error "No pods found for health check"
    exit /b 1
)

call :log_info "Checking health endpoint..."
kubectl exec %pod_name% -n %NAMESPACE% -- curl -f http://localhost:8080/actuator/health >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Health check passed"
) else (
    call :log_error "Health check failed"
    
    call :log_info "Pod logs:"
    kubectl logs %pod_name% -n %NAMESPACE% --tail=20
    
    exit /b 1
)
goto :eof

REM Function to show deployment status
:show_status
call :log_info "Deployment Status:"
echo.

kubectl get all -n %NAMESPACE%
echo.

call :log_info "Pod Details:"
kubectl describe pods -n %NAMESPACE% -l "app.kubernetes.io/name=%APP_NAME%" | findstr /i "Name: Status: Ready: Restart Image: Node: IP:"
echo.

call :log_info "Service Endpoints:"
kubectl get endpoints -n %NAMESPACE%
echo.

kubectl get ingress -n %NAMESPACE% >nul 2>&1
if %errorlevel% equ 0 (
    call :log_info "Ingress:"
    kubectl get ingress -n %NAMESPACE%
    echo.
)
goto :eof

REM Function to setup monitoring
:setup_monitoring
call :log_info "Setting up monitoring..."

kubectl get crd servicemonitors.monitoring.coreos.com >nul 2>&1
if %errorlevel% equ 0 (
    call :log_info "Prometheus operator detected, applying ServiceMonitor..."
    kubectl apply -f k8s\monitoring.yaml
    call :log_success "Monitoring configuration applied"
) else (
    call :log_warning "Prometheus operator not found, skipping ServiceMonitor creation"
)
goto :eof

REM Main deployment function
:main
call :log_info "Starting Kubernetes deployment for Book Review Application"
call :log_info "Environment: %ENVIRONMENT%"
call :log_info "Namespace: %NAMESPACE%"
call :log_info "Image: %IMAGE_NAME%:%IMAGE_TAG%"
echo.

REM Install required tools
call :install_tools
if %errorlevel% neq 0 exit /b 1

REM Check prerequisites
call :check_kubectl
if %errorlevel% neq 0 exit /b 1

REM Validate manifests
call :validate_manifests
if %errorlevel% neq 0 exit /b 1

REM Create namespace
call :create_namespace
if %errorlevel% neq 0 exit /b 1

REM Apply secrets
call :apply_secrets
if %errorlevel% neq 0 exit /b 1

REM Apply configuration
call :apply_config
if %errorlevel% neq 0 exit /b 1

REM Deploy application
call :deploy_application
if %errorlevel% neq 0 exit /b 1

REM Setup monitoring
call :setup_monitoring

REM Wait for deployment to complete
call :wait_for_deployment
if %errorlevel% neq 0 exit /b 1

REM Run health checks
call :run_health_checks
if %errorlevel% neq 0 exit /b 1

REM Show final status
call :show_status

call :log_success "✅ Book Review Application deployed successfully!"

REM Get service IP
for /f "tokens=*" %%i in ('kubectl get svc book-review-app-service -n %NAMESPACE% -o jsonpath^="{.status.loadBalancer.ingress[0].ip}" 2^>nul') do set service_ip=%%i
if "%service_ip%"=="" set service_ip=localhost

call :log_info "Access the application at: http://%service_ip%:8080"

echo.
call :log_info "Useful commands:"
echo   View pods:     kubectl get pods -n %NAMESPACE%
echo   View logs:     kubectl logs -f deployment/%APP_NAME% -n %NAMESPACE%
echo   Port forward:  kubectl port-forward svc/book-review-app-service 8080:80 -n %NAMESPACE%
echo   Scale app:     kubectl scale deployment %APP_NAME% --replicas=5 -n %NAMESPACE%
echo   Delete app:    kubectl delete namespace %NAMESPACE%

goto :eof

REM Parse command line arguments
:parse_args
if "%~1"=="--image-tag" (
    set IMAGE_TAG=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--environment" (
    set ENVIRONMENT=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--namespace" (
    set NAMESPACE=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="" goto main
call :log_error "Unknown option: %~1"
exit /b 1

:show_help
echo Usage: %0 [options]
echo Options:
echo   --image-tag TAG       Docker image tag to deploy (default: latest)
echo   --environment ENV     Deployment environment (default: production)
echo   --namespace NS        Kubernetes namespace (default: book-rev-namespace)
echo   --help, -h            Show this help message
goto :eof

REM Entry point
call :parse_args %*

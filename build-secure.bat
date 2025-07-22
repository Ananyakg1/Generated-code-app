@echo off
REM Secure Docker Build Script for Book Review Application (Windows)
REM This script builds the Docker image with security scanning and best practices

setlocal enabledelayedexpansion

REM Configuration
set APP_NAME=book-review-app
set APP_VERSION=1.0.0
set REGISTRY=localhost:5000

echo [INFO] Starting secure Docker build for %APP_NAME% v%APP_VERSION%

REM Check prerequisites
echo [INFO] Checking prerequisites...

where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not installed or not in PATH
    exit /b 1
)

where trivy >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Trivy is not installed. Please install for security scanning
    echo [INFO] Visit: https://aquasecurity.github.io/trivy/latest/getting-started/installation/
)

echo [SUCCESS] Prerequisites check completed

REM Build the Docker image
echo [INFO] Building Docker image...

docker build ^
    --build-arg BUILD_DATE="%date% %time%" ^
    --tag %APP_NAME%:%APP_VERSION% ^
    --tag %APP_NAME%:latest ^
    --file Dockerfile ^
    .

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker build failed
    exit /b 1
)

echo [SUCCESS] Docker image built successfully

REM Security scanning with Trivy (if available)
where trivy >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Running security scan with Trivy...
    
    if not exist security-reports mkdir security-reports
    
    trivy image --format json --output security-reports\trivy-report.json %APP_NAME%:%APP_VERSION%
    trivy image --format table --output security-reports\trivy-report.txt %APP_NAME%:%APP_VERSION%
    
    echo [SUCCESS] Security scan completed
    echo [INFO] Check security-reports\trivy-report.txt for details
)

REM Test the built image
echo [INFO] Testing the Docker image...

REM Start container for testing
docker run -d -p 8080:8080 --name %APP_NAME%-test %APP_NAME%:%APP_VERSION%
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to start test container
    exit /b 1
)

REM Wait for application to start
echo [INFO] Waiting for application to start...
timeout /t 30 /nobreak >nul

REM Health check using curl (if available) or PowerShell
where curl >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    curl -f http://localhost:8080/actuator/health >nul 2>nul
    if !ERRORLEVEL! EQU 0 (
        echo [SUCCESS] Health check passed
    ) else (
        echo [ERROR] Health check failed
        docker logs %APP_NAME%-test
        docker stop %APP_NAME%-test
        docker rm %APP_NAME%-test
        exit /b 1
    )
) else (
    echo [INFO] curl not available, skipping automated health check
    echo [INFO] Please verify manually that http://localhost:8080/actuator/health is accessible
    timeout /t 10 /nobreak >nul
)

REM Clean up test container
docker stop %APP_NAME%-test >nul 2>nul
docker rm %APP_NAME%-test >nul 2>nul

echo [SUCCESS] Image testing completed

REM Display completion information
echo [SUCCESS] Build completed successfully!
echo [INFO] Image: %APP_NAME%:%APP_VERSION%
echo [INFO] Security reports available in: security-reports\

REM Display image information
docker images | findstr %APP_NAME%

echo.
echo [INFO] To run the application:
echo docker run -p 8080:8080 %APP_NAME%:%APP_VERSION%
echo.
echo [INFO] To run with docker-compose:
echo docker-compose up
echo.

pause

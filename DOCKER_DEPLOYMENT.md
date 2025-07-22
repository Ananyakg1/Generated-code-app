# Docker Deployment Guide for Book Review Application

This guide provides comprehensive instructions for deploying the Book Review Application using Docker with security best practices.

## Table of Contents
- [Quick Start](#quick-start)
- [Security Configuration](#security-configuration)
- [Production Deployment](#production-deployment)
- [Development Setup](#development-setup)
- [Monitoring and Logging](#monitoring-and-logging)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Prerequisites
- Docker 20.10+ installed
- Docker Compose 2.0+ installed
- At least 512MB RAM available
- Port 8080 available

### Build and Run
```bash
# Clone or download the project
cd book-review-app

# Build the secure Docker image
./build-secure.sh  # Linux/Mac
# OR
build-secure.bat   # Windows

# Run with Docker Compose
docker-compose up -d

# Access the application
open http://localhost:8080
```

## Security Configuration

### Image Security Features
- **Non-root execution**: Runs as user `appuser` (UID: 1001)
- **Minimal attack surface**: Alpine-based image with only essential components
- **Vulnerability scanning**: Integrated Trivy scanning
- **Multi-stage build**: Separate build and runtime stages
- **Read-only filesystem**: Container runs with read-only root filesystem
- **Resource limits**: CPU and memory constraints

### Runtime Security
```bash
# Production-ready security settings
docker run -d \
  --name book-review-app \
  --user 1001:1001 \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=100m \
  --cap-drop=ALL \
  --cap-add=SETUID \
  --cap-add=SETGID \
  --security-opt=no-new-privileges:true \
  --memory=512m \
  --cpus=0.5 \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=docker \
  book-review-app:1.0.0
```

## Production Deployment

### Environment Variables
Required environment variables for production:
```bash
# Database configuration
DB_PASSWORD=your_secure_database_password

# Application configuration
SPRING_PROFILES_ACTIVE=docker
SERVER_PORT=8080

# Security settings
MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics
LOGGING_LEVEL_ROOT=INFO

# Resource configuration
JAVA_OPTS=-Xms256m -Xmx512m -XX:+UseContainerSupport
```

### Docker Compose Production
```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  book-review-app:
    image: book-review-app:1.0.0
    container_name: book-review-app-prod
    restart: unless-stopped
    
    # Security context
    user: "1001:1001"
    read_only: true
    
    # Security options
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - SETUID
      - SETGID
    
    # Resource limits
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
    
    # Volumes
    volumes:
      - app-data:/app/data:rw
      - app-logs:/app/logs:rw
    
    # Temporary filesystems
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /app/tmp:noexec,nosuid,size=50m
    
    # Environment
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - DB_PASSWORD=${DB_PASSWORD}
      - JAVA_OPTS=-Xms256m -Xmx512m
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    
    # Ports
    ports:
      - "8080:8080"

volumes:
  app-data:
    driver: local
  app-logs:
    driver: local
```

### Kubernetes Deployment
```yaml
# k8s-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: book-review-app
  labels:
    app: book-review-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: book-review-app
  template:
    metadata:
      labels:
        app: book-review-app
    spec:
      securityContext:
        runAsUser: 1001
        runAsGroup: 1001
        runAsNonRoot: true
        fsGroup: 1001
      containers:
      - name: book-review-app
        image: book-review-app:1.0.0
        imagePullPolicy: Always
        
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
            add:
            - SETUID
            - SETGID
        
        ports:
        - containerPort: 8080
          protocol: TCP
        
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "docker"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: book-review-secrets
              key: db-password
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        
        volumeMounts:
        - name: tmp-volume
          mountPath: /tmp
        - name: app-tmp-volume
          mountPath: /app/tmp
        - name: app-data
          mountPath: /app/data
        - name: app-logs
          mountPath: /app/logs
      
      volumes:
      - name: tmp-volume
        emptyDir:
          sizeLimit: 100Mi
      - name: app-tmp-volume
        emptyDir:
          sizeLimit: 50Mi
      - name: app-data
        persistentVolumeClaim:
          claimName: book-review-data
      - name: app-logs
        emptyDir:
          sizeLimit: 1Gi

---
apiVersion: v1
kind: Service
metadata:
  name: book-review-app-service
spec:
  selector:
    app: book-review-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP
```

## Development Setup

### Development Environment
```bash
# Run development version with debugging enabled
docker-compose -f docker-compose.dev.yml up -d

# Access application
open http://localhost:8080

# Access H2 console (development only)
open http://localhost:8083

# Debug port (if enabled)
# Connect debugger to localhost:8081
```

### Live Development
```bash
# Mount source code for live development (not recommended for production)
docker run -d \
  --name book-review-dev \
  -p 8080:8080 \
  -p 8081:8081 \
  -v $(pwd)/src:/app/src:ro \
  -e SPRING_PROFILES_ACTIVE=docker,dev \
  -e SPRING_DEVTOOLS_RESTART_ENABLED=true \
  book-review-app:1.0.0
```

## Monitoring and Logging

### Health Monitoring
```bash
# Check application health
curl http://localhost:8080/actuator/health

# Get application info
curl http://localhost:8080/actuator/info

# View metrics
curl http://localhost:8080/actuator/metrics
```

### Log Management
```bash
# View container logs
docker logs book-review-app

# Follow logs in real-time
docker logs -f book-review-app

# View specific number of log lines
docker logs --tail 100 book-review-app
```

### Metrics Collection
Integrate with monitoring solutions:
- **Prometheus**: Add micrometer-registry-prometheus dependency
- **Grafana**: Use provided dashboards for Spring Boot applications
- **ELK Stack**: Configure logstash for log collection
- **Jaeger**: Add distributed tracing for microservices

## Troubleshooting

### Common Issues

#### Application Won't Start
```bash
# Check container status
docker ps -a

# View container logs
docker logs book-review-app

# Check resource usage
docker stats book-review-app

# Common fixes:
# 1. Insufficient memory (increase --memory limit)
# 2. Port already in use (change port mapping)
# 3. Missing environment variables
```

#### Health Check Failures
```bash
# Manual health check
curl -v http://localhost:8080/actuator/health

# Check if application is responding
docker exec book-review-app curl -f http://localhost:8080/actuator/health

# Common fixes:
# 1. Application startup time too long (increase healthcheck start_period)
# 2. Database connection issues (check DB_PASSWORD)
# 3. Insufficient resources (increase memory/CPU limits)
```

#### Performance Issues
```bash
# Monitor resource usage
docker stats book-review-app

# Check JVM metrics
curl http://localhost:8080/actuator/metrics/jvm.memory.used

# Optimization tips:
# 1. Tune JVM options (-Xmx, -Xms)
# 2. Enable G1 garbage collector
# 3. Increase container resource limits
```

#### Security Issues
```bash
# Scan image for vulnerabilities
trivy image book-review-app:1.0.0

# Check running processes
docker exec book-review-app ps aux

# Verify user permissions
docker exec book-review-app id

# Common fixes:
# 1. Update base image version
# 2. Update dependencies
# 3. Review security configuration
```

### Debug Mode
```bash
# Enable debug logging
docker run -d \
  -p 8080:8080 \
  -e LOGGING_LEVEL_COM_BOOKREVIEW=DEBUG \
  -e SPRING_PROFILES_ACTIVE=docker,debug \
  book-review-app:1.0.0
```

### Container Inspection
```bash
# Inspect container configuration
docker inspect book-review-app

# Enter container for debugging (security consideration)
docker exec -it book-review-app /bin/sh

# Check file permissions
docker exec book-review-app ls -la /app/
```

## Best Practices

### Security
- Always run containers as non-root user
- Use specific image tags, not `latest`
- Regularly scan for vulnerabilities
- Implement resource limits
- Use read-only filesystems where possible
- Keep base images and dependencies updated

### Performance
- Configure appropriate JVM heap sizes
- Use health checks for container orchestration
- Implement proper logging configuration
- Monitor resource usage and metrics
- Use multi-stage builds to reduce image size

### Operations
- Use Docker Compose for local development
- Implement proper backup strategies for data volumes
- Set up monitoring and alerting
- Use infrastructure as code (IaC) for deployment
- Implement CI/CD pipelines with security scanning

For more detailed information, refer to the security policy and application documentation.

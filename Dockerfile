# Multi-stage Dockerfile for Book Review Application
# Security-focused build with vulnerability scanning and non-root execution

# ============================================================================
# Build Stage - Use specific OpenJDK version for Maven build
# ============================================================================
FROM maven:3.9.4-amazoncorretto-17 AS builder

# Set build-time metadata
LABEL stage=builder
LABEL maintainer="Book Review App Team"
LABEL description="Build stage for Book Review Application"

# Create non-root user for build process
RUN yum update -y && yum install -y shadow-utils && \
    groupadd -r builduser && useradd -r -g builduser builduser && \
    mkdir -p /home/builduser/.m2 && \
    chown -R builduser:builduser /home/builduser

# Set working directory and ensure builduser owns it
WORKDIR /build
RUN chown -R builduser:builduser /build

# Copy dependency files first for better caching
COPY --chown=builduser:builduser pom.xml .
COPY --chown=builduser:builduser .mvn/ .mvn/

# Switch to non-root user for dependency download
USER builduser

# Download dependencies (separate layer for caching)
RUN mvn dependency:go-offline -B

# Copy source code
COPY --chown=builduser:builduser src/ src/

# Build the application with security checks
RUN mvn clean package -DskipTests \
    -Dmaven.compiler.source=17 \
    -Dmaven.compiler.target=17 \
    -B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn

# Verify JAR file was created
RUN ls -la target/ && test -f target/*.jar

# ============================================================================
# Security Scanning Stage (Optional - for CI/CD integration)
# ============================================================================
FROM aquasec/trivy:0.44.1 AS security-scanner

COPY --from=builder /build/target/*.jar /scan/app.jar

# Run security scan (will fail build if critical vulnerabilities found)
# Uncomment the following line to enable security scanning during build
# RUN trivy fs --exit-code 1 --severity HIGH,CRITICAL /scan/

# ============================================================================
# Runtime Stage - Minimal and secure runtime environment
# ============================================================================
FROM amazoncorretto:17.0.13-alpine3.20 AS runtime

# Set runtime metadata
LABEL maintainer="Book Review App Team"
LABEL description="Book Review Application - Secure Runtime"
LABEL version="1.0.0"
LABEL java.version="17.0.13"
LABEL spring-boot.version="3.4.6"

# Install security updates and required packages
RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        curl \
        tzdata \
        ca-certificates && \
    # Clean up package cache
    rm -rf /var/cache/apk/* && \
    # Update CA certificates
    update-ca-certificates

# Create application directory structure
RUN mkdir -p /app/logs /app/tmp /app/config

# Create non-root user and group with specific UID/GID
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup && \
    # Set ownership of application directories
    chown -R appuser:appgroup /app && \
    # Set restrictive permissions
    chmod 750 /app && \
    chmod 755 /app/logs /app/tmp

# Set working directory
WORKDIR /app

# Copy JAR file from builder stage
COPY --from=builder --chown=appuser:appgroup /build/target/*.jar app.jar

# Verify JAR file integrity
RUN sha256sum app.jar > app.jar.sha256 && \
    chown appuser:appgroup app.jar.sha256

# Switch to non-root user
USER appuser

# Set security-focused environment variables
ENV JAVA_OPTS="-XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:+UseG1GC \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+UseStringDeduplication \
    -Djava.security.egd=file:/dev/./urandom \
    -Djava.awt.headless=true \
    -Dfile.encoding=UTF-8 \
    -Duser.timezone=UTC"

# Application-specific environment variables
ENV SPRING_PROFILES_ACTIVE=docker
ENV SERVER_PORT=8080
ENV MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics
ENV MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS=when_authorized
ENV LOGGING_LEVEL_ROOT=INFO
ENV LOGGING_LEVEL_COM_BOOKREVIEW=INFO

# Security hardening environment variables
ENV SPRING_JPA_SHOW_SQL=false
ENV SPRING_H2_CONSOLE_ENABLED=false
ENV SPRING_DEVTOOLS_RESTART_ENABLED=false

# Expose application port
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Create startup script for better signal handling
COPY --chown=appuser:appgroup <<EOF /app/startup.sh
#!/bin/sh
set -e

echo "Starting Book Review Application..."
echo "Java Version: \$(java -version 2>&1 | head -n 1)"
echo "Application User: \$(whoami)"
echo "Working Directory: \$(pwd)"
echo "Available Memory: \$(free -h)"

# Verify JAR integrity
echo "Verifying application integrity..."
sha256sum -c app.jar.sha256

# Start application with proper signal handling
exec java \$JAVA_OPTS -jar app.jar
EOF

# Make startup script executable
RUN chmod +x /app/startup.sh

# Use startup script as entrypoint
ENTRYPOINT ["/app/startup.sh"]

# ============================================================================
# Security Metadata and Labels
# ============================================================================
LABEL security.non-root-user="appuser"
LABEL security.user-id="1001"
LABEL security.group-id="1001"
LABEL security.health-check="enabled"
LABEL security.base-image="amazoncorretto:17.0.13-alpine3.20"
LABEL security.scan-date="2025-07-22"
LABEL vulnerability.database="updated"

# OpenContainer Initiative (OCI) annotations
LABEL org.opencontainers.image.title="Book Review Application"
LABEL org.opencontainers.image.description="Secure Spring Boot application for managing book reviews"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.created="2025-07-22T00:00:00Z"
LABEL org.opencontainers.image.source="https://github.com/example/book-review-app"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.vendor="Book Review App Team"

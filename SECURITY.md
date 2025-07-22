# Security Policy for Book Review Application Docker Image

## Supported Versions

The following versions of the Book Review Application are currently supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Features

### Image Security
- **Base Image**: Uses specific versioned Amazon Corretto OpenJDK 17 Alpine image
- **Multi-stage Build**: Separates build and runtime environments
- **Non-root User**: Runs as user ID 1001 (appuser) with minimal privileges
- **Read-only Filesystem**: Container filesystem is read-only where possible
- **No Shell Access**: Minimal attack surface with no unnecessary tools
- **Vulnerability Scanning**: Integrated Trivy scanning in build process

### Runtime Security
- **Security Context**: Drops all Linux capabilities except essential ones
- **Resource Limits**: CPU and memory limits to prevent resource exhaustion
- **Health Checks**: Comprehensive health monitoring
- **Secrets Management**: Environment variable-based configuration
- **Network Isolation**: Dedicated Docker network with controlled access

### Application Security
- **Input Validation**: Comprehensive validation using Spring Boot Validation
- **SQL Injection Prevention**: JPA/Hibernate ORM with parameterized queries
- **XSS Protection**: Thymeleaf template engine with automatic escaping
- **CSRF Protection**: Spring Security CSRF protection (when enabled)
- **Secure Headers**: HTTP security headers for production deployment
- **Session Management**: Secure session configuration
- **Error Handling**: No sensitive information in error messages

## Reporting a Vulnerability

If you discover a security vulnerability in this application, please follow these steps:

1. **Do not** disclose the vulnerability publicly until it has been addressed
2. Send a detailed report to the security team at: security@bookreview-app.com
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact assessment
   - Suggested fix (if available)

### Response Timeline

- **Initial Response**: Within 24 hours of receiving the report
- **Investigation**: 1-3 business days for initial assessment
- **Fix Development**: 3-7 business days depending on complexity
- **Release**: Security fixes are prioritized and released as soon as possible

## Security Best Practices for Deployment

### Container Security
```bash
# Run with non-root user
docker run --user 1001:1001 book-review-app:1.0.0

# Use read-only root filesystem
docker run --read-only book-review-app:1.0.0

# Drop all capabilities
docker run --cap-drop=ALL --cap-add=SETUID --cap-add=SETGID book-review-app:1.0.0

# Limit resources
docker run --memory=512m --cpus=0.5 book-review-app:1.0.0
```

### Network Security
```bash
# Create isolated network
docker network create --driver bridge book-review-network

# Run container in isolated network
docker run --network book-review-network book-review-app:1.0.0
```

### Secrets Management
```bash
# Use environment variables for secrets (not recommended for production)
docker run -e DB_PASSWORD=secure_password book-review-app:1.0.0

# Better: Use Docker secrets or external secret management
docker run --env-file secrets.env book-review-app:1.0.0
```

## Security Checklist

### Pre-deployment
- [ ] Vulnerability scan completed with acceptable results
- [ ] Base image is up-to-date
- [ ] Dependencies are up-to-date
- [ ] Security configuration reviewed
- [ ] Secrets are properly managed
- [ ] Resource limits are configured
- [ ] Network isolation is implemented

### Runtime Monitoring
- [ ] Container health checks are functioning
- [ ] Resource usage is monitored
- [ ] Security logs are collected and analyzed
- [ ] Vulnerability scanning is scheduled
- [ ] Access controls are in place
- [ ] Backup and recovery procedures are tested

## Security Updates

Security updates for this application are released as needed. Subscribe to notifications by:
- Watching the repository for releases
- Following security advisories
- Monitoring Docker Hub for image updates

## Compliance

This Docker image follows security best practices including:
- OWASP Top 10 mitigation strategies
- CIS Docker Benchmark guidelines
- NIST Cybersecurity Framework principles
- Docker Security Best Practices

## Contact

For security-related questions or concerns:
- Email: security@bookreview-app.com
- Security Advisory: Check repository issues with "security" label
- Emergency: Contact maintainers directly through repository

# Container Development Best Practices

## User Management

### Non-Root User Benefits
- 🛡️ **Enhanced Security**: Limits potential damage from security breaches
- 🔒 **Reduced Privileges**: Prevents unauthorized system modifications
- 🔄 **Best Practice**: Follows container security principles

### User Configuration

```dockerfile
ARG USER=udx
ARG UID=500
ARG GID=500

RUN groupadd -g $GID $USER && \
    useradd -u $UID -g $GID -m $USER
```

## Dockerfile Arguments

### Benefits of Using ARGs
- 🔧 **Parameterization**: Easy to customize builds
- 🎯 **Flexibility**: Adapt to different environments
- 🏗️ **Reusability**: Same Dockerfile, different configurations

### Common ARGs
```dockerfile
ARG USER=udx
ARG UID=500
ARG GID=500
ARG HOME=/home/udx
```

## Permission Management

### UID/GID Importance
- 📁 **File Access**: Consistent access across host and containers
- 🤝 **Shared Resources**: Proper permissions for mounted volumes
- 🔐 **Security**: Controlled access to resources

### Best Practices
1. Use consistent UID/GID across environments
2. Document required permissions
3. Verify file ownership after operations

## Container Security

### Running as Non-Root
- Prevents privileged access
- Limits system modification capabilities
- Follows principle of least privilege

### Security Checklist
- [ ] Use non-root user
- [ ] Set appropriate file permissions
- [ ] Limit mounted volumes
- [ ] Use read-only filesystems where possible

## Environment Setup

### Container User Context
- Application-specific user
- Limited privileges
- No system administration capabilities

### Directory Permissions
```bash
chown -R $USER:$USER /app
chmod -R 755 /app
```

## Tips and Tricks

1. **Testing User Setup**:
   ```bash
   docker run --rm -it myimage whoami
   docker run --rm -it myimage id
   ```

2. **Debugging Permissions**:
   ```bash
   docker run --rm -it myimage ls -la /app
   docker run --rm -it myimage stat /app
   ```

3. **Volume Mounting**:
   ```bash
   docker run -v $(pwd):/app:ro myimage  # Read-only mount
   ```
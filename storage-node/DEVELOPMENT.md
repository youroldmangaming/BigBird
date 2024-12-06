# Storage Node Development Guide

[← Back to Index](README.md) | [Troubleshooting Guide](TROUBLESHOOTING.md) | [Architecture Guide →](ARCHITECTURE.md)

---

## Table of Contents
- [Development Environment](#development-environment)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Development Tools](#development-tools)
- [Service Development](#service-development)
- [Release Process](#release-process)
- [Continuous Integration](#continuous-integration)
- [Performance Testing](#performance-testing)
- [Troubleshooting Development](#troubleshooting-development)
- [Contributing](#contributing)

## Development Environment

### Prerequisites
- Docker Engine
- Docker Compose
- Python 3.x
- Git
- Code editor with shell support

### Setup Development Environment
```bash
# Clone repository
git clone <repository-url>
cd storage-node

# Create development branch
git checkout -b dev/feature-name

# Install development dependencies
pip install pytest pytest-cov pylint black

# Setup pre-commit hooks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
black .
pylint *.py
pytest
EOF
chmod +x .git/hooks/pre-commit
```

## Project Structure

```
storage-node/
├── src/                    # Source code
│   ├── services/          # Service configurations
│   ├── scripts/           # Utility scripts
│   └── tests/             # Test files
├── docs/                  # Documentation
├── config/                # Configuration templates
├── tools/                 # Development tools
└── examples/             # Example configurations
```

## Development Workflow

### 1. Code Style

#### Python
```python
# Use Black formatting
black .

# Follow PEP 8
pylint *.py

# Type hints
def process_data(input_data: dict) -> List[str]:
    pass
```

#### Shell Scripts
```bash
# Use shellcheck
shellcheck *.sh

# Follow Google Shell Style Guide
# https://google.github.io/styleguide/shellguide.html
```

### 2. Testing

#### Unit Tests
```python
# test_monitor.py
import pytest
from monitor import StorageMonitor

def test_service_check():
    monitor = StorageMonitor()
    assert monitor.check_service("nfs") in ["running", "stopped"]
```

#### Integration Tests
```python
# test_integration.py
def test_nfs_mount():
    result = subprocess.run(["mount", "-t", "nfs", ...])
    assert result.returncode == 0
```

#### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=.

# Run specific test
pytest test_monitor.py -k test_service_check
```

### 3. Documentation

#### Code Documentation
```python
def check_service_health(service_name: str) -> Dict[str, Any]:
    """
    Check the health status of a specified service.

    Args:
        service_name: Name of the service to check

    Returns:
        Dict containing service status information
        {
            "status": "running"|"stopped",
            "uptime": int,
            "memory_usage": float
        }

    Raises:
        ServiceNotFoundError: If service doesn't exist
    """
    pass
```

#### API Documentation
```bash
# Generate API docs
sphinx-build -b html docs/source docs/build
```

## Development Tools

### 1. Debugging

```python
# Add debug logging
import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Debug specific service
docker-compose up storage-node
docker attach storage-node
```

### 2. Profiling

```python
# Profile code
import cProfile
profiler = cProfile.Profile()
profiler.enable()
# ... code to profile ...
profiler.disable()
profiler.print_stats()
```

### 3. Monitoring

```bash
# Monitor container
docker stats storage-node

# View logs
docker-compose logs -f
```

## Service Development

### 1. Adding New Services

1. Create service configuration:
```ini
# supervisord.conf
[program:new-service]
command=/usr/local/bin/new-service
priority=50
autorestart=true
```

2. Update Docker configuration:
```dockerfile
# Dockerfile.storage
RUN apt-get install -y new-service
```

3. Add management support:
```bash
# manage.sh
"new-service")
    handle_service "new-service" "$2"
    ;;
```

### 2. Modifying Services

1. Test changes:
```bash
# Test in development container
docker-compose -f docker-compose.dev.yml up

# Verify service
./manage.sh status new-service
```

2. Update documentation:
```markdown
## New Service

### Configuration
Service-specific configuration details...

### Usage
How to use the new service...
```

## Release Process

### 1. Version Control

```bash
# Create release branch
git checkout -b release/v1.0.0

# Update version
sed -i 's/version=.*/version="1.0.0"/' setup.py

# Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"
```

### 2. Testing

```bash
# Run full test suite
pytest --runslow

# Test installation
./setup.sh --test

# Verify all services
./manage.sh verify-all
```

### 3. Documentation

```bash
# Update changelog
cat >> CHANGELOG.md << EOF
## [1.0.0] - $(date +%Y-%m-%d)
### Added
- New feature X
### Changed
- Modified Y
### Fixed
- Bug Z
EOF
```

## Continuous Integration

### GitHub Actions
```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: pytest
```

### Local CI Testing
```bash
# Run CI checks locally
./tools/ci-check.sh

# Build test container
docker build -f Dockerfile.test .
```

## Performance Testing

### 1. Load Testing
```python
# test_load.py
def test_concurrent_access():
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(access_test) for _ in range(100)]
        results = [f.result() for f in futures]
```

### 2. Benchmarking
```bash
# Network performance
iperf3 -c localhost -p 445

# Disk I/O
fio --name=test --rw=randwrite --size=1G
```

## Troubleshooting Development

### Common Issues

1. Build failures:
```bash
# Clean Docker cache
docker system prune -a

# Rebuild with no cache
docker-compose build --no-cache
```

2. Test failures:
```bash
# Run with verbose output
pytest -vv

# Debug specific test
pytest --pdb test_file.py::test_name
```

### Development Tools

1. Log analysis:
```bash
# Parse logs
./tools/parse-logs.py

# Generate report
./tools/generate-report.py
```

2. Debugging tools:
```bash
# Network debugging
tcpdump -i any port 445

# Process monitoring
htop -p $(pgrep -d',' -f storage-node)
```

## Contributing

1. Fork repository
2. Create feature branch
3. Implement changes
4. Add tests
5. Update documentation
6. Submit pull request

### Pull Request Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update

## Testing
Description of testing performed

## Documentation
Links to updated documentation

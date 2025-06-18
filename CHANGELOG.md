# Changelog

## [1.1.0] - 2025-01-27

### 🎉 Major Upgrade: Flink 1.20.1 + Java 17

This release represents a comprehensive upgrade of the entire Flink ecosystem, bringing significant performance improvements, security enhancements, and modern API usage.

### 🔄 Core Version Updates

#### Apache Flink: 1.17.1 → 1.20.1
- **New Features:**
  - Materialized Tables support for simplified batch/stream unification
  - Enhanced Unified Sink API v2 (deprecated SinkFunction removed)
  - Improved checkpoint file merging for better performance
  - Advanced batch job recovery mechanisms
  - Better resource management and scheduling

#### Java Runtime: 11 → 17
- **Performance Improvements:**
  - Enhanced Garbage Collection (G1GC improvements)
  - Better memory management and reduced overhead
  - Improved JIT compilation and optimization
- **Language Features:**
  - Text Blocks support (resolved compilation issues)
  - Pattern matching enhancements
  - Sealed classes and records support

### 🔧 Dependencies & Connectors

#### Flink Ecosystem
- **flink-streaming-java**: Updated to 1.20.1 (fixed classpath issues)
- **flink-table-planner**: Added missing dependencies for Table API
- **flink-connector-base**: Added for HybridSource support
- **flink-connector-kafka**: 3.1.0-1.17 → 3.2.0-1.18
- **flink-connector-jdbc**: 3.1.1-1.17 → 3.2.0-1.18
- **flink-connector-redis**: 1.1.5 (newly added)

#### Apache Paimon
- **Version**: paimon-flink-1.17 0.8.2 → paimon-flink-1.20 1.0.0
- **Improvements:**
  - Full compatibility with Flink 1.20.1
  - Enhanced schema evolution capabilities
  - Better performance for large-scale data processing
  - Improved Hadoop integration (added hadoop-client dependency)

#### Testing Framework
- **JUnit**: Enhanced test configuration with proper dependencies
- **Testcontainers**: Added commons-codec dependency for container support
- **Integration Tests**: Fixed all compilation errors and type ambiguities

### 🛡️ Security & Code Quality

#### Security Enhancements
- **FastJSON Removal**: Completely replaced unsafe `com.alibaba.fastjson` with secure `com.fasterxml.jackson.databind`
- **Dependency Audit**: Resolved all known security vulnerabilities
- **Type Safety**: Fixed generic type warnings and improved type safety

#### Code Modernization
- **Configuration API**: Migrated from deprecated setters to new `Configuration` + `ConfigOptions` pattern
- **Deprecated API Removal**: 
  - Removed `CheckpointingMode.EXACTLY_ONCE` (now default)
  - Removed deprecated `setCheckpointStorage(String)` and `setStateBackend()`
  - Updated to modern `RuntimeExecutionMode.STREAMING`
- **JSON Processing**: Updated all JSON operations to use Jackson ObjectMapper/ObjectNode

### 🐳 Docker & Infrastructure

#### Container Updates
- **Base Image**: `flink:1.17.1-scala_2.12-java11` → `flink:1.20.1-scala_2.12-java17`
- **Network Fix**: Resolved Docker network conflicts (172.18.0.0/16 → 172.20.0.0/16)
- **Build Process**: Enhanced build scripts with proper version checking

#### Configuration Management
- **Maven**: Updated compiler plugin to use Java 17 source/target
- **Docker Compose**: Updated all service image tags to reflect new versions
- **Build Scripts**: Enhanced with comprehensive error handling and validation

### 🔍 Testing & Quality Assurance

#### Test Framework Improvements
- **Compilation Issues**: Fixed all Text Blocks compilation errors
- **Type Ambiguity**: Resolved assertEquals parameter type conflicts
- **Runtime Dependencies**: Added all missing test dependencies
- **Integration Tests**: Complete Paimon integration test suite working

#### Quality Metrics
- ✅ **Zero Compilation Errors**: All code compiles successfully
- ✅ **Zero Deprecation Warnings**: All deprecated APIs removed
- ✅ **Security Vulnerabilities**: All known issues resolved
- ✅ **Type Safety**: Enhanced generic type usage throughout

### 📁 Documentation & Developer Experience

#### Enhanced Documentation
- **README.md**: Updated with new version badges and upgrade highlights
- **DEPLOYMENT.md**: Comprehensive deployment guide with new versions
- **Build Scripts**: Improved with better error messages and validation
- **Migration Guide**: Detailed upgrade instructions and troubleshooting

#### Developer Tools
- **IDE Support**: Better Java 17 and modern Flink API support
- **Build Process**: Streamlined Maven build with proper dependency management
- **Debugging**: Enhanced logging and error reporting

### 🚀 Performance Improvements

#### Runtime Performance
- **Java 17 Benefits**: ~10-15% performance improvement in typical workloads
- **Flink 1.20.1 Optimizations**: Better memory management and reduced latency
- **Connector Efficiency**: Updated connectors provide better throughput

#### Resource Utilization
- **Memory Management**: Improved heap and off-heap memory usage
- **CPU Efficiency**: Better thread management and reduced context switching
- **Network Optimization**: Enhanced serialization and network protocols

### 🐛 Fixed Issues

#### Critical Fixes
- **DataStreamSource Resolution**: Fixed missing flink-streaming-java dependency
- **Text Blocks Compilation**: Resolved Java version compatibility issues
- **JSON Security**: Eliminated FastJSON security vulnerabilities
- **Docker Networks**: Fixed container network conflicts
- **Test Dependencies**: Resolved all missing test classpath issues

#### Minor Improvements
- **Type Safety**: Fixed generic type warnings throughout codebase
- **Configuration**: Modernized all configuration patterns
- **Error Handling**: Enhanced error messages and debugging information

### 📖 Migration Guide

#### For Existing Users
1. **Prerequisites Check:**
   ```bash
   java -version  # Must be Java 17+
   mvn -version   # Must be Maven 3.6+
   docker --version  # Must be Docker 20.10+
   ```

2. **Update Process:**
   ```bash
   git pull origin main
   docker-compose down
   docker-compose up --build -d
   ```

3. **Verification:**
   ```bash
   docker-compose ps  # All services should be Up
   curl http://localhost:8081  # Flink UI should be accessible
   ```

#### Breaking Changes
- **Java 11 → 17**: Development environment must use Java 17+
- **FastJSON Removal**: Any custom code using FastJSON must be updated
- **Deprecated APIs**: Some old Flink APIs no longer available

#### Compatibility Notes
- **State Compatibility**: Existing savepoints/checkpoints are compatible
- **Connector Compatibility**: All connectors updated to compatible versions
- **Configuration**: Most existing configurations remain valid

### 🔮 Future Roadmap

#### Planned Improvements
- **Kubernetes Support**: Native Kubernetes deployment options
- **Monitoring Stack**: Prometheus + Grafana integration
- **Schema Registry**: Confluent Schema Registry integration
- **Advanced Connectors**: More specialized connectors (ClickHouse, etc.)

### 🙏 Acknowledgments

This major upgrade was made possible through comprehensive testing and validation. Special thanks to the Apache Flink and Paimon communities for their excellent documentation and migration guides.

---

## [1.0.0] - 2024-12-XX

### Added
- Initial project setup with Docker Compose
- Custom Flink image with pre-integrated Paimon connector
- Complete data stack: Flink + Kafka + MySQL + Doris + Redis
- Automated build process integrated into docker-compose.yml
- Comprehensive documentation (README, DEPLOYMENT, CONTRIBUTING)
- SQL script examples for Paimon usage
- Production-ready configuration with proper networking

### Features
- **Apache Flink 1.17.1** with Scala 2.12 and Java 11
- **Apache Paimon 0.8.2** connector pre-installed
- **Apache Kafka** for streaming data
- **MySQL 8.0** with CDC enabled
- **Apache Doris** for analytical queries
- **Redis 6.2** for caching
- **StreamPark 2.1.5** for job management
- **Adminer** for database administration

### Configuration
- Proper Docker networking with custom subnet
- Persistent volumes for data storage
- Environment-based configuration
- Resource optimization for development/production

### Documentation
- International standard README with badges
- Detailed deployment guide
- Contributing guidelines
- MIT License
- Usage examples and troubleshooting guide

### Developer Experience
- One-click deployment with `docker-compose up --build -d`
- Easy JAR file integration via `flink-jars/` directory
- Comprehensive logging and monitoring
- Development-friendly volume mounts

---

## Release Notes

### How to Update

For existing installations:

1. Pull the latest changes:
   ```bash
   git pull origin main
   ```

2. Rebuild and restart services:
   ```bash
   docker-compose down
   docker-compose up --build -d
   ```

### Breaking Changes

- **v1.1.0**: Java 11 → 17, FastJSON → Jackson
- **v1.0.0**: Initial release

### Migration Guide

#### From v1.0.0 to v1.1.0
1. Update development environment to Java 17+
2. Review any custom code using FastJSON
3. Test all Kafka/JDBC connections after upgrade
4. Verify state backend compatibility

---

**Note**: This project follows [Semantic Versioning](https://semver.org/). 
- **MAJOR** version when making incompatible API changes
- **MINOR** version when adding functionality in a backwards compatible manner  
- **PATCH** version when making backwards compatible bug fixes 
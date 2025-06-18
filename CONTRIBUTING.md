# Contributing to Flink-Demo

First off, thank you for considering contributing to Flink-Demo! It's people like you that make this project great.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find that you don't need to create one. When you create a bug report, please include as many details as possible:

- **Use a clear and descriptive title** for the issue
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** to demonstrate the steps
- **Describe the behavior you observed** after following the steps
- **Explain which behavior you expected to see instead** and why
- **Include screenshots** if possible
- **Include your environment details** (OS, Docker version, etc.)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Use a clear and descriptive title** for the issue
- **Provide a step-by-step description** of the suggested enhancement
- **Provide specific examples** to demonstrate the steps
- **Describe the current behavior** and **explain which behavior you expected to see instead**
- **Explain why this enhancement would be useful** to most users

### Pull Requests

1. **Fork** the repository
2. **Create a branch** from `main` for your changes
3. **Make your changes** in the new branch
4. **Add tests** if applicable
5. **Ensure tests pass** and code follows the project's style
6. **Update documentation** if needed
7. **Submit a pull request**

## Development Setup

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Git

### Local Development

1. Clone your fork:
   ```bash
   git clone https://github.com/your-username/flink-demo.git
   cd flink-demo
   ```

2. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. Start the development environment:
   ```bash
   docker-compose up --build -d
   ```

4. Make your changes and test them thoroughly

5. Run tests (if applicable):
   ```bash
   # Add test commands here
   ```

## Style Guidelines

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

### Code Style

- Follow the existing code style in the project
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### Docker and Configuration

- Follow Docker best practices
- Use multi-stage builds when appropriate
- Minimize image size and layers
- Use environment variables for configuration
- Document any new environment variables

## Project Structure

```
flink-demo/
├── docker-compose.yml          # Main orchestration
├── flink/
│   └── Dockerfile             # Custom Flink image
├── flink-jars/                # JAR files
├── doris/                     # Doris configuration
├── sql-scripts/               # Database scripts
├── docs/                      # Documentation
├── tests/                     # Test files
└── README.md                  # Project documentation
```

## Testing

### Manual Testing

1. Start all services:
   ```bash
   docker-compose up --build -d
   ```

2. Verify all services are running:
   ```bash
   docker-compose ps
   ```

3. Test key functionality:
   - Flink Web UI accessible at http://localhost:8081
   - Paimon JAR loaded correctly
   - All dependent services running

### Automated Testing

If you add new features, please include appropriate tests:

- Unit tests for individual components
- Integration tests for service interactions
- End-to-end tests for complete workflows

## Documentation

### README Updates

When making changes, update the README.md if:
- Adding new features
- Changing configuration options
- Modifying setup instructions
- Adding new dependencies

### Code Documentation

- Add inline comments for complex logic
- Document all configuration options
- Include usage examples for new features

## Release Process

1. Update version numbers in relevant files
2. Update CHANGELOG.md with new features and fixes
3. Create a pull request with the changes
4. After approval, create a release tag

## Getting Help

If you need help with contributing:

- Check the [README.md](README.md) for setup instructions
- Look at existing issues for similar problems
- Create a new issue with the "question" label
- Join our community discussions

## Recognition

Contributors will be recognized in:
- GitHub contributors list
- Project documentation
- Release notes (for significant contributions)

Thank you for contributing to Flink-Demo! 🎉 
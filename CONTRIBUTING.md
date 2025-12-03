# Contributing to Bastion CI/CD Test

Thank you for your interest in contributing! This project is designed to help people learn about bastion hosts and infrastructure testing.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists
2. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Your environment (Terraform version, AWS region, etc.)

### Submitting Changes

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Update documentation if needed
   - Test your changes locally

4. **Test thoroughly**
   ```bash
   # Test Terraform changes
   cd terraform
   terraform init
   terraform validate
   terraform plan
   
   # Test scripts
   ./scripts/test-connectivity.sh
   ```

5. **Commit with clear messages**
   ```bash
   git commit -m "feat: add support for multiple availability zones"
   ```

6. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Development Guidelines

### Code Style

**Terraform:**
- Use descriptive resource names
- Add comments for complex configurations
- Follow HashiCorp's style guide
- Use variables for configurable values

**Bash Scripts:**
- Include error handling (`set -e`)
- Add colored output for better UX
- Provide helpful error messages
- Make scripts idempotent when possible

**Documentation:**
- Keep README up to date
- Add examples for new features
- Use clear, concise language

### Commit Messages

Follow conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `test:` Test updates
- `chore:` Maintenance tasks

Example: `feat: add support for custom VPC CIDR blocks`

## Ideas for Contributions

Looking for ideas? Here are some suggestions:

### Easy
- Improve error messages in scripts
- Add more comprehensive documentation
- Create video tutorial or blog post
- Add architecture diagrams

### Medium
- Support for multiple AWS regions
- Add CloudWatch monitoring
- Implement Session Manager integration
- Add support for different Linux distributions

### Advanced
- Multi-AZ deployment
- NAT Gateway for private subnet internet access
- VPC peering scenarios
- Container-based testing (replace EC2 with ECS/Fargate)

## Testing

Before submitting a PR, ensure:

- [ ] Terraform validates successfully
- [ ] Infrastructure provisions without errors
- [ ] All connectivity tests pass
- [ ] Resources destroy cleanly
- [ ] Documentation is updated
- [ ] No sensitive data in commits

## Questions?

Feel free to:
- Open an issue for discussion
- Reach out in pull request comments
- Suggest improvements to this guide

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers and help them learn
- Focus on what's best for the project
- Show empathy towards other contributors

Thank you for contributing! 🙏

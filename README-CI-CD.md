# Enterprise CI/CD Platform for Base Apparel Frontend

## Overview

This repository contains a comprehensive Enterprise-scale CI/CD platform built using AWS services, Docker, Kubernetes, and SonarQube. The platform provides automated testing, security scanning, and deployment strategies for the Base Apparel Frontend application.

## Architecture

### CI/CD Pipeline Components

1. **AWS CodePipeline** - Orchestrates the entire CI/CD workflow
2. **AWS CodeBuild** - Builds, tests, and packages the application
3. **AWS CodeDeploy** - Deploys to EC2 instances with blue-green strategy
4. **Amazon ECR** - Container registry for Docker images
5. **Amazon S3** - Artifact storage
6. **CloudWatch** - Monitoring and logging
7. **SonarQube** - Code quality and security analysis
8. **Kubernetes** - Container orchestration (alternative deployment)

### Security Features

- **Automated Security Scanning** with Trivy
- **Code Quality Analysis** with SonarQube
- **IAM Roles** with least privilege access
- **Encryption at rest** for all storage
- **Network Security Groups** and VPC isolation
- **Security Headers** in nginx configuration

### Deployment Strategies

1. **Blue-Green Deployment** via CodeDeploy
2. **Rolling Updates** in Kubernetes
3. **Canary Deployments** (configurable)
4. **Auto-rollback** on failures

## Prerequisites

### AWS Requirements
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker installed
- kubectl (for Kubernetes deployment)

### Required Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:*",
        "s3:*",
        "codebuild:*",
        "codedeploy:*",
        "codepipeline:*",
        "iam:*",
        "cloudwatch:*",
        "logs:*",
        "ec2:*",
        "vpc:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Quick Start

### 1. Infrastructure Deployment

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Create terraform.tfvars file
cat > terraform.tfvars << EOF
aws_region = "us-east-1"
environment = "production"
github_repository = "your-username/base-apparel-frontend"
github_branch = "main"
sonarqube_host = "https://sonarqube.your-domain.com"
sonarqube_token = "your-sonarqube-token"
EOF

# Plan the deployment
terraform plan

# Deploy the infrastructure
terraform apply
```

### 2. GitHub Integration

1. Go to AWS Console > Developer Tools > Settings > Connections
2. Find the connection created by Terraform
3. Click "Pending" and complete GitHub authorization
4. Update the connection status to "Available"

### 3. SonarQube Configuration

1. Store your SonarQube token in AWS Secrets Manager:
```bash
aws secretsmanager create-secret \
  --name "sonarqube-token" \
  --secret-string "your-sonarqube-token"
```

2. Update the CodeBuild project to use the secret:
```bash
aws codebuild update-project \
  --name base-apparel-frontend-build \
  --environment-variables name=SONARQUBE_TOKEN,value=sonarqube-token,type=SECRETS_MANAGER
```

### 4. Application Deployment

```bash
# Push code to trigger the pipeline
git add .
git commit -m "Initial deployment"
git push origin main
```

## Pipeline Stages

### 1. Source Stage
- **Trigger**: Code push to configured branch
- **Actions**: 
  - Clone repository from GitHub
  - Validate source code
  - Create source artifacts

### 2. Build Stage
- **Actions**:
  - Install dependencies (`npm ci`)
  - Run linting (`npm run lint`)
  - Execute unit tests (`npm run test:coverage`)
  - Security audit (`npm audit`)
  - Vulnerability scan (Trivy)
  - Code quality analysis (SonarQube)
  - Build Docker image
  - Push to ECR

### 3. Deploy Stage
- **Actions**:
  - Deploy to EC2 instances via CodeDeploy
  - Execute deployment scripts
  - Health checks and validation
  - Auto-rollback on failure

## Configuration Files

### Build Configuration (`buildspec.yml`)
- Multi-stage Docker build
- Security scanning with Trivy
- SonarQube integration
- ECR image push

### Deployment Configuration (`appspec.yml`)
- File deployment strategy
- Lifecycle hooks
- Health checks
- Rollback configuration

### Kubernetes Configuration
- Deployment with rolling updates
- Service and ingress configuration
- Horizontal Pod Autoscaler
- Network policies

### Terraform Configuration
- Infrastructure as Code
- VPC and networking
- IAM roles and policies
- Monitoring and alerting

## Monitoring and Observability

### CloudWatch Metrics
- Build success/failure rates
- Deployment metrics
- Application performance
- Error rates and latency

### Logs
- CodeBuild logs
- CodeDeploy logs
- Application logs
- nginx access/error logs

### Alerts
- Deployment failures
- Build failures
- High error rates
- Resource utilization

## Security Features

### Code Security
- **SonarQube Analysis**: Code quality, security hotspots, vulnerabilities
- **Trivy Scanning**: Container vulnerability scanning
- **npm Audit**: Dependency vulnerability scanning
- **ESLint**: Code quality and security rules

### Infrastructure Security
- **VPC Isolation**: Private subnets for application servers
- **IAM Roles**: Least privilege access
- **Encryption**: All data encrypted at rest and in transit
- **Security Groups**: Network-level access control

### Application Security
- **Security Headers**: XSS protection, content security policy
- **HTTPS**: SSL/TLS termination
- **Rate Limiting**: Protection against DDoS
- **Input Validation**: Client and server-side validation

## Deployment Strategies

### CodeDeploy (EC2)
```bash
# Blue-Green Deployment
aws deploy create-deployment \
  --application-name base-apparel-frontend \
  --deployment-group-name base-apparel-frontend-deployment-group \
  --s3-location bucket=artifacts-bucket,key=app.zip,bundleType=zip
```

### Kubernetes
```bash
# Apply Kubernetes manifests
kubectl apply -f kubernetes/

# Check deployment status
kubectl get pods -n production
kubectl get services -n production
kubectl get ingress -n production
```

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check CloudWatch logs for CodeBuild
   - Verify dependencies in package.json
   - Check SonarQube connectivity

2. **Deployment Failures**
   - Review CodeDeploy logs
   - Check EC2 instance health
   - Verify deployment scripts

3. **Pipeline Stuck**
   - Check GitHub connection status
   - Verify IAM permissions
   - Review CloudWatch alarms

### Debug Commands

```bash
# Check pipeline status
aws codepipeline get-pipeline-state --name base-apparel-frontend-pipeline

# View build logs
aws logs describe-log-streams --log-group-name /aws/codebuild/base-apparel-frontend

# Check ECR images
aws ecr describe-images --repository-name base-apparel-frontend

# Monitor deployment
aws deploy get-deployment --deployment-id <deployment-id>
```

## Best Practices

### Code Quality
- Maintain >80% test coverage
- Use ESLint for code consistency
- Regular SonarQube analysis
- Security-first development

### Infrastructure
- Use Infrastructure as Code (Terraform)
- Implement proper tagging
- Regular security updates
- Monitor resource utilization

### Deployment
- Test in staging environment first
- Use blue-green deployments
- Implement proper rollback strategies
- Monitor application health

### Security
- Regular security scans
- Keep dependencies updated
- Implement least privilege access
- Encrypt sensitive data

## Cost Optimization

### Recommendations
- Use Spot instances for non-critical workloads
- Implement auto-scaling
- Regular cleanup of unused resources
- Monitor and optimize resource usage

### Cost Monitoring
```bash
# Check ECR costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Monitor CodeBuild usage
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{"Dimensions":{"Key":"SERVICE","Values":["AWS CodeBuild"]}}'
```

## Support and Maintenance

### Regular Maintenance Tasks
- Update dependencies monthly
- Review and rotate secrets quarterly
- Update base images quarterly
- Review IAM permissions annually

### Backup and Recovery
- ECR images are versioned
- S3 artifacts are versioned
- Terraform state is backed up
- Application data backups (if applicable)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or support, please contact the DevOps team or create an issue in the repository. 
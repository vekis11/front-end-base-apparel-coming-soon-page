output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.frontend.name
}

output "s3_artifacts_bucket" {
  description = "Name of the S3 artifacts bucket"
  value       = aws_s3_bucket.artifacts.bucket
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.frontend.name
}

output "codedeploy_application_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.frontend.name
}

output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.frontend.deployment_group_name
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.frontend.name
}

output "codepipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.frontend.arn
}

output "github_connection_arn" {
  description = "ARN of the GitHub CodeStar connection"
  value       = aws_codestarconnections_connection.github.arn
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.frontend.name
}

output "deployment_failure_alarm_arn" {
  description = "ARN of the deployment failure CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.deployment_failure.arn
}

output "iam_roles" {
  description = "IAM roles created for the CI/CD platform"
  value = {
    codebuild_role_arn  = aws_iam_role.codebuild.arn
    codedeploy_role_arn = aws_iam_role.codedeploy.arn
    codepipeline_role_arn = aws_iam_role.codepipeline.arn
  }
}

output "docker_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.frontend.repository_url}"
}

output "deployment_instructions" {
  description = "Instructions for deploying the application"
  value = <<-EOT
    ========================================
    Enterprise CI/CD Platform Deployment
    ========================================
    
    Infrastructure has been deployed successfully!
    
    Next Steps:
    1. Connect your GitHub repository to the CodeStar connection:
       - Go to AWS Console > Developer Tools > Settings > Connections
       - Find the connection: ${aws_codestarconnections_connection.github.name}
       - Click "Pending" and complete the GitHub authorization
    
    2. Update your GitHub repository settings:
       - Repository: ${var.github_repository}
       - Branch: ${var.github_branch}
    
    3. Configure SonarQube integration:
       - SonarQube Host: ${var.sonarqube_host}
       - Store your SonarQube token in AWS Secrets Manager
    
    4. Deploy your application:
       - Push code to the configured branch
       - The pipeline will automatically trigger
    
    5. Monitor the deployment:
       - CodePipeline: ${aws_codepipeline.frontend.name}
       - CloudWatch Logs: ${aws_cloudwatch_log_group.frontend.name}
       - ECR Repository: ${aws_ecr_repository.frontend.repository_url}
    
    Important URLs:
    - ECR Repository: ${aws_ecr_repository.frontend.repository_url}
    - S3 Artifacts: ${aws_s3_bucket.artifacts.bucket}
    - CloudWatch Logs: /aws/codebuild/base-apparel-frontend
    
    Security Notes:
    - All resources are encrypted at rest
    - IAM roles follow least privilege principle
    - Network security groups are configured
    - Secrets are stored in AWS Secrets Manager
    
    For Kubernetes deployment:
    - Use the Kubernetes manifests in the kubernetes/ directory
    - Update the image URL in deployment.yaml
    - Apply with: kubectl apply -f kubernetes/
    
    EOT
} 
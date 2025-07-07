variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "your-username/base-apparel-frontend"
}

variable "github_branch" {
  description = "GitHub branch to deploy from"
  type        = string
  default     = "main"
}

variable "sonarqube_host" {
  description = "SonarQube server URL"
  type        = string
  default     = "https://sonarqube.your-domain.com"
}

variable "sonarqube_token" {
  description = "SonarQube authentication token"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "base-apparel.example.com"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "codebuild_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  
  validation {
    condition     = contains(["BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE"], var.codebuild_compute_type)
    error_message = "CodeBuild compute type must be one of: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM, BUILD_GENERAL1_LARGE."
  }
}

variable "codebuild_timeout" {
  description = "CodeBuild timeout in minutes"
  type        = number
  default     = 60
  
  validation {
    condition     = var.codebuild_timeout >= 5 && var.codebuild_timeout <= 480
    error_message = "CodeBuild timeout must be between 5 and 480 minutes."
  }
}

variable "ecr_image_retention_count" {
  description = "Number of ECR images to retain"
  type        = number
  default     = 30
  
  validation {
    condition     = var.ecr_image_retention_count >= 1 && var.ecr_image_retention_count <= 100
    error_message = "ECR image retention count must be between 1 and 100."
  }
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention must be one of the allowed values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Project     = "Base-Apparel-CI-CD"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
} 
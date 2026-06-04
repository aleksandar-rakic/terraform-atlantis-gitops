# Terraform + Atlantis GitOps

> PR-based infrastructure workflow on AWS — plan on PR, apply on merge. No direct `terraform apply` access.

[![Terraform CI](https://github.com/aleksandar-rakic/terraform-atlantis-gitops/actions/workflows/ci.yml/badge.svg)](https://github.com/aleksandar-rakic/terraform-atlantis-gitops/actions/workflows/ci.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.9-7B42BC?style=flat-square&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-eu--central--1-232F3E?style=flat-square&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

## How It Works

```
Developer opens PR with infrastructure changes
          │
          ▼
Atlantis automatically runs: terraform plan
          │
          ▼
Plan output posted as PR comment
          │
          ▼
Team reviews plan + approves PR
          │
          ▼
Atlantis runs: terraform apply (on merge)
          │
          ▼
Infrastructure updated. State locked in S3.
```

**No one runs `terraform apply` locally. Ever.**

## Stack

| Layer | Technology |
|-------|-----------|
| IaC | Terraform 1.9 |
| GitOps | [Atlantis](https://www.runatlantis.io) |
| Cloud | AWS (eu-central-1) |
| State | S3 + DynamoDB lock |
| Linting | TFLint + AWS ruleset |
| Security | Trivy IaC scan |
| Style | `terraform fmt` enforced |
| Pre-commit | pre-commit-terraform hooks |

## Repository Structure

```
.
├── atlantis.yaml               # Atlantis project config
├── .terraform-version          # Pinned Terraform version
├── .pre-commit-config.yaml     # Pre-commit hooks
├── .tflint.hcl                 # TFLint rules
│
├── modules/
│   ├── vpc/                    # VPC, subnets, NAT gateways, route tables
│   ├── rds/                    # RDS PostgreSQL (Multi-AZ)
│   ├── ecs/                    # ECS Fargate cluster + services
│   ├── alb/                    # Application Load Balancer
│   └── security-groups/        # Security group rules
│
└── environments/
    ├── staging/                # Staging environment
    └── production/             # Production environment
```

## Infrastructure Overview

```
                    Internet
                       │
              [Application Load Balancer]
                       │
          ┌────────────┴────────────┐
          │                         │
    [ECS Fargate]             [ECS Fargate]
    eu-central-1a             eu-central-1b
          │                         │
          └────────────┬────────────┘
                       │
              [RDS PostgreSQL 16]
               Multi-AZ, encrypted
```

## Environments

| Environment | Region | Instance |
|------------|--------|----------|
| staging | eu-central-1 | db.t4g.micro |
| production | eu-central-1 | db.r8g.large, Multi-AZ |

## Atlantis Workflow

### PR Workflow

```bash
# In a PR comment, trigger plan manually:
atlantis plan -p staging

# Apply after approval:
atlantis apply -p staging
```

### Requirements to Apply

- **staging**: At least 1 PR approval + branch is mergeable
- **production**: At least 1 PR approval + branch is mergeable + policy checks pass

## CI Pipeline

Every PR runs:
1. `terraform fmt -check -recursive`
2. TFLint with AWS ruleset
3. Trivy security scan (blocks on HIGH/CRITICAL)
4. `terraform plan` posted as PR comment

## Local Development

```bash
# Install tools
brew install terraform tflint trivy pre-commit

# Install pre-commit hooks
pre-commit install

# Format
terraform fmt -recursive

# Validate a module
cd modules/vpc
terraform init -backend=false
terraform validate
```

## License

MIT © [Aleksandar Rakić](https://github.com/aleksandar-rakic)

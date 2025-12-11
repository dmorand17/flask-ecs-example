# Flask ECS Example

A simple example of deploying a Flask application on AWS ECS using [Express Mode](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/express-service-overview.html).

## Overview

This project demonstrates how to containerize a Flask application and deploy it to AWS ECS using Express Mode, which simplifies the deployment process by automatically managing load balancers, networking, and scaling configuration.

## Development

### Requirements

Before you begin, ensure you have the following tools installed:

- **Python 3.14+** - The application runtime
- **Docker** - For containerization and local testing
- **[uv](https://docs.astral.sh/uv/)** - Fast Python package installer and resolver (for dependency management)
- **AWS CLI** - For interacting with AWS services during deployment

Optional tools:
- **[docker buildx](https://docs.docker.com/buildx/working-with-buildx/)** - For multi-platform builds (usually included with Docker Desktop)

### Build and Run Locally

```bash
# Build the Docker image
docker build -t flask-ecs-app .

# Run the container locally
docker run -d -p 5000:5000 flask-ecs-app
```

The application will be accessible at `http://localhost:5000`.

### Dependency Management

Lock dependencies in `requirements.txt`:

```bash
uv pip compile pyproject.toml -o requirements.txt
```

## Testing

Once the container is running locally, you can test the health endpoint:

```bash
curl http://localhost:5000/health
```

## Deployment

This project provides two approaches for deployment:
1. **Automated Scripts** - Use helper scripts in `scripts/ecs-express/` for simplified deployment
2. **Manual Commands** - Run AWS CLI commands directly for more control

### Prerequisites

- AWS CLI configured with appropriate credentials
- Docker installed and running
- ECR repository created (`flask-ecs-example`)
- Required IAM roles (see setup instructions below)

### Option 1: Using Deployment Scripts (Recommended)

The `scripts/ecs-express/` directory contains helper scripts to streamline the deployment process.

#### Step 1: Create Required IAM Roles

Before deploying for the first time, create the necessary IAM roles:

```bash
./scripts/ecs-express/create-roles.sh
```

This script creates:
- `ecsTaskExecutionRole` - Allows ECS tasks to pull images from ECR and write logs
- `ecsInfrastructureRoleForExpressServices` - Allows ECS to manage infrastructure for Express Mode services

#### Step 2: Create ECS Cluster and Service

Deploy the application to a new or existing cluster:

```bash
./scripts/ecs-express/create-ecs-application.sh <cluster-name>
```

Example:
```bash
./scripts/ecs-express/create-ecs-application.sh app-cluster
```

This script will:
- Create an ECS cluster with the specified name
- Deploy the Flask application as an Express Mode service
- Configure auto-scaling (min: 1 task, max: 2 tasks)
- Set up health checks on the `/health` endpoint
- Allocate 1024 CPU units and 2048 MB memory per task

### Option 2: Manual Deployment with AWS CLI

If you prefer more control or need to customize the deployment, you can run the AWS CLI commands directly.

#### Build and Push Image to ECR

This section covers building your Docker image for the ECS deployment platform and pushing it to Amazon Elastic Container Registry (ECR).

```bash
# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Login to ECR - authenticate Docker to your private ECR registry
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build the image for linux/amd64 platform (required for ECS)
# We use buildx to ensure cross-platform compatibility
# Option 1: Build using standard Dockerfile (traditional pip-based installation)
docker buildx build --platform linux/amd64 -t flask-ecs-app .

# Option 2: Build using Dockerfile with UV package manager (faster builds)
docker buildx build --platform linux/amd64 -f Dockerfile-uv -t flask-ecs-app .

# Tag the image with your ECR repository URL
# This formats the image name to match ECR's naming convention
docker tag flask-ecs-app:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/flask-ecs-example:latest

# Push the image to ECR so ECS can pull it during deployment
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/flask-ecs-example:latest
```

**Note:** The `--platform linux/amd64` flag is important because ECS tasks run on Linux AMD64 architecture. Without this flag, images built on Apple Silicon (ARM) Macs won't run correctly on ECS.

#### Create IAM Roles (First Time Only)

```bash
# Create task execution role
aws iam create-role --role-name ecsTaskExecutionRole \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "ecs-tasks.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }'

# Create infrastructure role for Express services
aws iam create-role --role-name ecsInfrastructureRoleForExpressServices \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "ecs.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }'

# Attach AWS managed policies
aws iam attach-role-policy --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam attach-role-policy --role-name ecsInfrastructureRoleForExpressServices \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices
```

#### Create ECS Service

Create a new ECS Express Mode service:

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecs create-express-gateway-service \
    --execution-role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole" \
    --infrastructure-role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsInfrastructureRoleForExpressServices" \
    --primary-container '{
        "image": "'${AWS_ACCOUNT_ID}'.dkr.ecr.us-east-1.amazonaws.com/flask-ecs-example:latest",
        "containerPort": 5000,
        "environment": [{
            "name": "ENV",
            "value": "Prod"
        },
        {
            "name": "DEBUG",
            "value": "false"
        }]
    }' \
    --cluster app-cluster \
    --service-name "flask-ecs-app" \
    --cpu "1024" \
    --memory "2048" \
    --health-check-path "/health" \
    --scaling-target '{"minTaskCount":1,"maxTaskCount":2}' \
    --monitor-resources
```

#### Update ECS Service

Update an existing service with a new image:

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecs update-express-gateway-service \
  --service-arn "arn:aws:ecs:us-east-1:${AWS_ACCOUNT_ID}:service/default/flask-ecs-app" \
  --primary-container '{
    "image": "'${AWS_ACCOUNT_ID}'.dkr.ecr.us-east-1.amazonaws.com/flask-ecs-example:latest"
  }'
```

## References

- [AWS ECS Express Service Getting Started Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/express-service-getting-started.html)
- [AWS ECS Express Mode Overview](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/express-service-overview.html)
- [Automating Deployment of Flask to AWS ECS with GitHub Actions](https://hbayraktar.medium.com/automating-deployment-of-a-flask-application-to-aws-ecs-with-github-actions-c256192eb8ad)
- [Deep Dive into uv Dockerfiles by Astral: Image Size, Performance & Best Practices](https://medium.com/@benitomartin/deep-dive-into-uv-dockerfiles-by-astral-image-size-performance-best-practices-5790974b9579)

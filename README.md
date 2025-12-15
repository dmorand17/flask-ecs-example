# Flask ECS Example

A simple example of deploying a Flask application on AWS ECS using [Express Mode](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/express-service-overview.html).

## Overview

This project demonstrates how to containerize a Flask application and deploy it to AWS ECS using Express Mode, which simplifies the deployment process by automatically managing load balancers, networking, and scaling configuration.

**Continuous Deployment:** This project uses GitHub Actions to automatically build and deploy your application to ECS whenever code is pushed to the `main` branch. See the [CI/CD](#cicd-with-github-actions) section for details.

## Deployment

### Prerequisites

- AWS CLI configured with appropriate credentials
- Docker installed and running
- ECR repository created (`flask-ecs-example`)
- Required IAM roles (see setup instructions below)
- GitHub repository with Actions enabled (for CI/CD)

### Initial Setup with Deployment Scripts

The `scripts/ecs-express/` directory contains helper scripts to streamline the initial deployment setup.

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

**Note:** ECS Express Mode manages health check configuration automatically. The service will perform health checks on the `/health` endpoint with AWS-managed defaults.

### CI/CD with GitHub Actions

Once your ECS service is created, GitHub Actions will automatically handle deployments when you push code to the `main` branch.

#### Workflow Overview

The deployment workflow (`.github/workflows/deploy.yaml`) consists of two jobs:

1. **Build Job** - Builds the Docker image and pushes it to ECR with a unique tag (commit SHA + timestamp)
2. **Deploy Job** - Updates the ECS service with the new image and waits for the deployment to stabilize

#### Required GitHub Secrets and Variables

Configure the following in your GitHub repository settings:

**Variables** (Settings → Secrets and variables → Actions → Variables):
- `ASSUME_ROLE_ARN` - ARN of the IAM role for OIDC authentication (e.g., `arn:aws:iam::123456789012:role/GitHubActionsRole`)
- `ECR_REPO` - Full ECR repository URI (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/flask-ecs-example`)
- `ECS_SERVICE_ARN` - ARN of your ECS service (e.g., `arn:aws:ecs:us-east-1:123456789012:service/app-cluster/flask-ecs-app`)

#### How It Works

1. **Push to main branch** - Any commit to `main` triggers the workflow
2. **Build & Push** - Docker image is built and pushed to ECR with a unique tag
3. **Deploy** - ECS service is updated with the new image
4. **Summary** - Deployment details are shown in the GitHub Actions UI

#### Manual Triggering

You can also manually trigger a deployment from the GitHub Actions tab using the "Run workflow" button.

### Manual Deployment with AWS CLI

If you prefer to deploy manually or need to customize the deployment, you can use the AWS CLI commands directly.

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

## Development

### Requirements

Before you begin, ensure you have the following tools installed:

- **Python 3.14+** - The application runtime
- **Docker** - For containerization and local testing
- **[uv](https://docs.astral.sh/uv/)** - Fast Python package installer and resolver (for dependency management)
- **AWS CLI** - For interacting with AWS services during deployment (optional for local dev)

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

### Manual Build and Push to ECR

If you need to manually build and push an image to ECR (for testing or troubleshooting), follow these steps:

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

## Testing

Once the container is running locally, you can test the endpoints:

```bash
# Test the default route
curl http://localhost:5000/

# Test the health check endpoint
curl http://localhost:5000/health
```

Both endpoints return JSON responses.

## Troubleshooting

### Slow Health Checks

If your ECS service is taking too long to show as healthy during deployments:

1. **Ensure your Flask app starts quickly** - Your application should respond to `/health` immediately after starting
2. **Verify the health endpoint returns 200 OK** - Test locally: `curl http://localhost:5000/health`
3. **Monitor CloudWatch logs** - Check for startup errors or slow initialization
4. **Check task startup time** - View the ECS console to see how long tasks take to reach RUNNING state

ECS Express Mode uses AWS-managed health check settings that cannot be customized directly. The typical time to healthy status is 30-60 seconds.

### Deployment Failures

If deployments fail or tasks keep restarting:

1. **Check CloudWatch Logs** - View container logs for errors in the AWS Console
2. **Verify ECR image** - Ensure the image was pushed successfully and is accessible
3. **Check IAM roles** - Verify `ecsTaskExecutionRole` has ECR pull permissions
4. **Test locally** - Always test with `docker run` before deploying to ECS
5. **Review GitHub Actions logs** - Check the workflow run for detailed error messages

### GitHub Actions Failures

If the GitHub Actions workflow fails:

1. **Check GitHub Variables** - Ensure `ASSUME_ROLE_ARN`, `ECR_REPO`, and `ECS_SERVICE_ARN` are set correctly
2. **Verify OIDC Configuration** - Ensure your AWS IAM role trusts GitHub's OIDC provider
3. **Check IAM Permissions** - The assumed role needs permissions for ECR push and ECS update operations
4. **Review workflow logs** - Click on the failed job in GitHub Actions for detailed error messages

## References

- [AWS ECS Express Service Getting Started Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/express-service-getting-started.html)
- [AWS ECS Express Mode Overview](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/express-service-overview.html)
- [Automating Deployment of Flask to AWS ECS with GitHub Actions](https://hbayraktar.medium.com/automating-deployment-of-a-flask-application-to-aws-ecs-with-github-actions-c256192eb8ad)
- [Deep Dive into uv Dockerfiles by Astral: Image Size, Performance & Best Practices](https://medium.com/@benitomartin/deep-dive-into-uv-dockerfiles-by-astral-image-size-performance-best-practices-5790974b9579)
- [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

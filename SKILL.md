---
name: airfire-cicd
description: Implement USFS AirFire compliant CI/CD pipelines using GitHub Actions, conforming to branching, environmental, security, and architectural footprint standards.
---

# USFS AirFire CI/CD Standards Skill

## Purpose
This skill guides AI agents in implementing and maintaining GitHub Actions pipelines, security configurations, and deployment strategies that comply with the official USFS AirFire CI/CD standards.

---

## 1. Branching & Environment Conventions

### The Two-Environment Standard
AirFire standardizes strictly on a lean two-environment architecture to minimize cost and management overhead:
- **`dev`**: Active testing, integration, and development verification.
- **`prod`**: User-facing production environment. Requires manual approval gates.
*Do not introduce additional environments (like staging or test) unless explicitly requested.*

### Triggers & Branching Map
- **Pull Requests (targeting `main`/`master`)**: Trigger linting, unit tests, and validation checks. No deployments are made.
- **Pushes (merges to `main`/`master`)**: Trigger automatic build and deployment to the `dev` environment.
- **Release Tags (matching `vM.m.r` where M, m, r are SemVer integers)**: Trigger build and deployment to the `prod` environment.
  - Deploying to `prod` **MUST** pass through a GitHub Environment gate named `prod` requiring manual administrative approval.

---

## 2. Security Best Practices

### Workflow Action Pinning
- Always pin GitHub Actions to their major version (e.g. `uses: actions/checkout@v4`) rather than commit SHAs. This permits automatic patch/security updates.

### Cloud Authentication via AWS OIDC
- **Never** store static AWS Access Keys (`AKIA...`) in GitHub Secrets.
- Use OpenID Connect (OIDC) to request short-lived credentials from AWS Security Token Service (STS).
- Workflows requesting OIDC credentials must declare:
  ```yaml
  permissions:
    id-token: write
    contents: read
  ```
- Assume the IAM role using the official configuration action:
  ```yaml
  - name: Configure AWS Credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
      aws-region: us-west-2
  ```

### Application Secret Security (AWS Secrets Manager)
- Use AWS Secrets Manager for all application runtime secrets.
- Ensure the following properties are configured:
  1. Dedicated KMS encryption keys.
  2. Least-privilege IAM policies.
  3. Automatic rotation policies.
  4. CloudTrail auditing for access logs.

---

## 3. Architectural Footprints

When writing or updating deployment steps, determine which footprint the application targets:

### Legacy Footprint (EC2 + Docker Compose + Fabric)
- Hosted on standalone EC2 instances.
- Orchestrated locally using `docker-compose.yml`.
- Deployment is executed by the runner calling a Python **Fabric** script to connect via SSH, run `docker compose pull`, and restart containers.
- Monitored using **Prefect** workflows.

### Modern Footprint (AWS ECS + Fargate)
- Serverless container orchestration.
- Deployment is executed by the runner using the AWS CLI/ECS API to register a new Task Definition and update the Service.
- No SSH keys, direct SSH access, or Fabric script execution allowed.
- Application routing is managed by Application Load Balancers (ALBs).

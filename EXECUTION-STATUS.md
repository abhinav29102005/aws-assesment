# Verified execution status

## Local checks completed

- Node.js 22.22.0: 5 HTTP application tests passed, exit code 0.
- Intentional assertion failure in a separate copy: 4 tests passed, 1 failed, exit code 1.
- JavaScript and Bash syntax and YAML/JSON parsing passed.
- Root static, test, EC2 and Beanstalk packaging commands were executed locally and passed; JUnit output and deployment artifact layouts were checked.
- Docker build/run not executed: local daemon access was denied.

## AWS cloud execution (`ap-southeast-2`, account `774569413000`)

Note: Initial checks in `us-east-1` hit explicit SCP denials (`p-hcfss492`), whereas `ap-southeast-2` (Sydney) permits CI/CD resource creation.

### Assignment 1 — Static Website Deployment (GitHub -> CodePipeline -> S3): **Succeeded**
- S3 bucket `academy-cicd-web-774569413000-sydney` created with static website hosting and public-read bucket policy.
- CodeConnections GitHub connection `academy-assignment-github` (`6f8bcbb5-def2-4a4c-af5d-1e5738f9ab12`) authorized and `AVAILABLE` for `abhinav29102005/aws-assesment`.
- CodePipeline `academy-static` (V2, GitHub push webhook on `main`) updated to deploy `SourceArtifact` directly to S3.
- Commit `a28922d57b6d6aab8e67529c56be394287d44d24` triggered execution `15f66865-12a1-4b75-b8ad-c7e34501f7fc` (**Succeeded**), and `http://academy-cicd-web-774569413000-sydney.s3-website-ap-southeast-2.amazonaws.com/` serves `Version 1.0.1` live.

### Assignments 2–5 — Provisioned Resources & Account-Verification Blocker
- **Assignment 2 (CodeBuild):** Projects `academy-static-package` and `academy-tests` created. `StartBuild` fails with `AccountLimitExceededException: Cannot have more than 0 builds in queue for the account` (all CodeBuild concurrency quotas are `0.0`, and `RequestServiceQuotaIncrease` returns `AccessDeniedException: Unable to perform this operation. Please contact AWS Support`).
- **Assignment 3 (EC2 + CodeDeploy):** IAM roles (`academy-ec2-codedeploy-role`, `academy-ec2-codedeploy-profile`, `academy-codedeploy-service-role`), security group `academy-codedeploy-sg` (`sg-0ea8483ab4c021e8e`), and CodeDeploy application `academy-ec2-app` (`6d16d8e4-4fdf-40a9-9654-e8731c1dc51b`) created. `RunInstances` fails with `Blocked: This account is currently blocked and not recognized as a valid account` (requires AWS Support account verification).
- **Assignment 4 (Elastic Beanstalk):** Application `academy-beanstalk-app` created; environment provisioning requires EC2 `RunInstances`, which is blocked by the same account verification hold.
- **Assignment 5 (ECR + Docker):** ECR repository `774569413000.dkr.ecr.ap-southeast-2.amazonaws.com/academy-cicd-app` created; CodeBuild Docker build/push is blocked by the `0.0` CodeBuild concurrency quota.

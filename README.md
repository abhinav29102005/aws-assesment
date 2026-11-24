# AWS Academy CI/CD Assignment

Implementations follow the supplied assignment order:

1. `01-static` - S3 static website deployment using CodePipeline
2. `02-codebuild` - Node.js application tests and build artifacts
3. `03-codedeploy` - EC2 deployment lifecycle hooks
4. `04-beanstalk` - Immutable deployment and environment settings
5. `05-container` - Docker builds and ECR publication

Deployment instructions are in `RUNBOOK.md`. Configuration files do not establish that cloud execution succeeded. Check the execution status document for verified results and restrictions.

This repository uses one main branch with five exercise directories. Build and deployment stages must select the relevant subdirectory; see the monorepo buildspecs and packaging scripts.

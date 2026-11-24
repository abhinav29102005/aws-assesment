# AWS Academy CI/CD Assignment

Five exercises in the original assignment order. All source remains on `main` in one repository.

| Assignment | Source | Root buildspec |
|---|---|---|
| 1 Static website | `01-static` | `buildspec-static.yml` |
| 2 Build and tests | `02-codebuild` | `buildspec-tests.yml` |
| 3 EC2 CodeDeploy | `03-codedeploy` | `buildspec-ec2.yml` |
| 4 Elastic Beanstalk | `04-beanstalk` | `buildspec-beanstalk.yml` |
| 5 Docker and ECR | `05-container` | `buildspec-container.yml` |

Read [RUNBOOK.md](RUNBOOK.md) for execution steps and [EXECUTION-STATUS.md](EXECUTION-STATUS.md) for verified results. Root buildspecs select the correct directory and emit deployable artifacts without the parent directory. Do not feed the entire repository ZIP directly to a website, CodeDeploy, or Beanstalk deployment action.

Local tests: `cd 02-codebuild && node --test app.test.js` with Node.js 22 or later. The intentionally failing test script should be used only on a temporary branch and reverted afterwards. No credentials belong in this repository.

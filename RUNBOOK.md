# AWS Academy CI/CD assignment package

This package implements the source code and deployment configuration for all five assignments in the supplied brief. **Cloud execution is blocked by organization-level service restrictions on the authenticated account.** Local application tests passed (5/5); the intentionally broken version failed as expected (4 pass, 1 fail; exit code 1). No cloud success, endpoint, deployment ID, image digest, or screenshot is claimed.

## Start here

Use the supplied GitHub repository with all five numbered folders on main. The root monorepo buildspecs select each exercise directory and package only the corresponding runtime/deployment files. Each pipeline needs a CodeBuild packaging or test stage before deployment. Node.js 22 or newer is required. There are no npm dependencies.

Start the Academy lab, wait for its AWS console access, and use its allowed region and temporary session credentials. Never commit credentials. Before creating resources run `aws sts get-caller-identity` and confirm the account is the intended lab. The old default credentials were invalid. A separate academy-cicd sign-in profile was subsequently authenticated. Its organization service control policy denied key service checks; see EXECUTION-STATUS.md. No existing profile was overwritten.

Academy permissions differ by course. First confirm access to CodePipeline, CodeBuild, CodeDeploy, EC2, Beanstalk, ECR, S3 and CodeConnections. Check the budget and restrictions. An `AccessDenied` is a lab permission constraint, not proof of broken application code. Use an instructor-approved role only when its trust policy supports the relevant service; do not assume a general `LabRole` can be used by every service. If service-role creation or a service itself is blocked, record the denial and ask the instructor for supported permissions.

For a fresh copy of this repository, run from the repository root:

```bash
git init -b main
git add .
git commit -m 'Add AWS Academy CI/CD demo'
git remote add origin https://github.com/abhinav29102005/aws-assesment.git
git push -u origin main
```

Create a GitHub connection in AWS Developer Tools > Connections (CodeConnections). Complete the GitHub browser authorization and confirm `AVAILABLE`. A connection created only by API stays pending until browser authorization. Grant access only to these repositories. Use this connection in pipeline source actions with `main`, ZIP output, and automatic source change detection. For pipeline templates see `pipeline-templates/`; supply real ARNs and names before creating pipelines. Do not create duplicate push triggers for the same pipeline.

## 1 Automated static website deployment

Architecture: GitHub main → CodePipeline source → S3 deployment → website bucket.

1. In S3 create a globally unique website bucket and a **separate private** pipeline artifact bucket in the lab region. Enable default encryption and keep artifacts private.
2. On the website bucket enable static website hosting, index `index.html`, error `error.html`. For this public demonstration only, allow public object reads by adjusting the website bucket's Block Public Access settings and applying `01-static/bucket-policy.example.json` with the real bucket name. Account-level public-access blocks must also permit it. Never apply this policy to the artifact bucket. The public website contains no secrets. If the lab forbids public S3 websites, report the restriction rather than claiming that a private bucket endpoint meets the task.
3. Create pipeline `academy-static`, source this repository on `main`; add a CodeBuild stage with root `buildspec-static.yml` and deploy its output artifact. Deploy provider Amazon S3, select website bucket and **Extract file before deploy**. The static build emits only index.html, styles.css and error.html. The S3 action must consume that build output, not the complete source ZIP.
4. Run the pipeline once and open the **website endpoint** from S3 Properties (not a private S3 object URL). The page should display Version 1.0.0. Capture source revision, successful deploy action, and endpoint.
5. Change visible version to 1.0.1 in `index.html`, commit and push. Do not upload files manually. Observe the new pipeline execution and refresh the endpoint. Record the revision and updated version.

S3 website endpoints use HTTP. Use the exact endpoint shown for your region instead of constructing its hostname. A direct S3 deploy does not remove old keys; delete retired content deliberately if that is part of a later exercise.

## 2 Build and test automation

Architecture: GitHub push or PR → CodeBuild → private S3 artifacts and test reports.

1. Use the second repository. In CodeBuild create `academy-tests` using GitHub and an authorized connection, main branch, managed Linux image that supports Node.js 22, small compute, no VPC unless required. Buildspec is root `buildspec-tests.yml`. Do not enable privileged mode for this test-only project.
2. Choose an instructor-approved CodeBuild service role; enable CloudWatch Logs. Give it access to the specific private artifact bucket and report group. Select S3 ZIP artifacts, with a build-ID namespace or unique path so results do not overwrite one another.
3. Enable webhook rebuilds. `webhook-filters.json` defines two OR groups: push to main; PR created/updated/reopened targeting main. Restrict source connection to this repository. Do not give untrusted PR builds secrets or ECR deployment privileges.
4. Run a build. The buildspec selects Node.js 22, writes JUnit XML, runs five tests, and copies runtime files to `dist` only after the tests pass. CodeBuild uploads `dist` as its artifact. Save build ID, commit, test report, logs and artifact key.
5. From a clean checkout run:

```bash
git switch -c demo/failing-test
bash introduce-failure.sh
git add app.test.js
git commit -m 'Demonstrate failing CI test'
git push -u origin demo/failing-test
```

Open a PR into main. Confirm CodeBuild runs, reports a version mismatch and fails. `on-failure: ABORT` prevents application packaging after the failed test. Test-report collection is diagnostic and can still occur on failed builds. Do not merge the intentionally failing PR. Restore the test in the same branch with `git restore --source=main -- app.test.js`, commit and push; confirm the new PR build passes. Close the demo PR.

Run locally with `node --test app.test.js`. The intentional failure expects 9.9.9 while the application returns 1.0.0. This validates real assertion failure, not a forced `exit 1`.

## 3 EC2 deployment with CodeDeploy

Architecture: GitHub main → CodePipeline ZIP → CodeDeploy in place → tagged Ubuntu EC2.

1. Launch an instructor-approved Ubuntu instance and instance size in the lab region. Attach an approved EC2 instance profile that can read the specific pipeline artifacts and decrypt their KMS key if used. Tag it `Project=academy-codedeploy`. Ensure outbound connectivity to CodeDeploy/S3 and required OS package sources. Restrict SSH to your IP or use Session Manager. Allow inbound TCP 8080 from your testing IP to view this demo.
2. On the instance install a supported Node.js 22+ runtime at `/usr/bin/node` using an approved distribution method. Verify `/usr/bin/node --version`. The installer here deliberately does not silently add a third-party package repository. Also install curl.
3. Copy `install-agent-ubuntu.sh` to the instance, set `AWS_REGION`, run it, and verify the CodeDeploy agent is active. This uses the AWS regional resource-kit bucket and the `latestv2` installer; confirm OS/agent compatibility against the linked AWS documentation for the chosen Ubuntu release.
4. In CodeDeploy create application `academy-ec2`, compute EC2/on-premises. Create group `academy-ec2-group` with an approved **CodeDeploy service role**, deployment type **in place**, instance tag above, configuration `CodeDeployDefault.OneAtATime`, without a load balancer for this small lab. Enable automatic rollback on deployment failure. A single-instance in-place deployment can interrupt service; this lab does not claim zero downtime.
5. Create pipeline `academy-ec2-pipeline` with GitHub source main, a CodeBuild test/package stage using root `buildspec-ec2.yml`, then CodeDeploy action targeting that application/group. The root `appspec.yml` maps application files and the systemd unit. Hooks stop the previous service, verify runtime and create the user, install file permissions, start the service and validate `/health`.
6. Run deployment; watch CodePipeline and CodeDeploy instance lifecycle events. On EC2 run `systemctl status academy-app` and `curl --fail http://127.0.0.1:8080/health`. Open `http://PUBLIC_IP:8080/` from the permitted IP.
7. Change the version to 1.0.1 and its unit-test expectation, commit and push. Capture the new execution and application response. Record a deployment ID and successful ValidateService event.

`ApplicationStop` uses the previous deployed revision and is skipped on the first deployment. The stop hook tolerates an absent unit. Absolute install paths avoid dependence on the agent's working directory. `file_exists_behavior: OVERWRITE` permits subsequent revisions. The app runs as an unprivileged system account. Node runtime and agent installation are host prerequisites, not deployment claims.

## 4 Elastic Beanstalk deployment

Architecture: GitHub main → CodePipeline → Beanstalk Standard Node.js web environment.

1. Use the fourth repository. Create a Beanstalk **Standard**, Web server, current supported Node.js 22+ platform environment. Configure a load-balanced environment with at least two healthy instances across appropriate availability zones; choose lab-permitted instance types. Select the approved Beanstalk service role and EC2 instance profile. Create the environment and wait for healthy status before adding the pipeline.
2. `Procfile` starts `node app.js`. The app obeys Beanstalk's injected `PORT`. `.ebextensions/deployment.config` selects immutable application deployments and immutable configuration updates; `/health` is the process health path. Confirm these settings in the environment configuration after initial creation. Immutable deployments temporarily require replacement instances and quota/budget headroom.
3. Set `APP_ENV=staging` in environment properties. The JSON options files can be applied using `aws elasticbeanstalk update-environment --environment-name YOUR_ENV --option-settings file://options-staging.json`. Do not set the PORT property manually. A second independently provisioned environment can use `options-production.json` for production; alternatively change the same demonstration environment's property and record that it is a configuration demonstration, not two separate deployments.
4. Create pipeline `academy-beanstalk` from the fourth GitHub repository main, a CodeBuild test/package stage using root `buildspec-beanstalk.yml`, then deployment provider Elastic Beanstalk, selecting the real application and environment. Source ZIP must have `package.json`, `app.js`, `Procfile`, and `.ebextensions` at its root.
5. Check initial endpoint and health. Start `APP_URL=https://YOUR_ENDPOINT bash check-availability.sh > availability.log` using the actual scheme/URL shown by AWS. Push a version change to main. Monitor CodePipeline, Beanstalk events, environment health and the request log during the replacement process. Save old/new versions and execution ID.
6. Verify response includes `environment: staging`; set the production option, wait for ready/healthy, and verify `environment: production`. Capture the properties and responses without secrets.

An ordinary single-instance or all-at-once deployment does not demonstrate zero downtime. Immutable deployment protects the serving fleet until replacements pass health checks, but actual availability must still be measured. The included request loop provides sampled evidence only, not a universal availability guarantee. If the Academy lab cannot provision the required topology, record the restriction and do not claim zero downtime.

## 5 Docker image build and ECR publish

Architecture: GitHub main → CodePipeline source → privileged CodeBuild → ECR.

1. Use the fifth repository. In ECR create private `academy-demo`, immutable tags, encryption enabled, and the lab-approved scanning configuration. Record its repository URI. Optional CLI creation: `aws ecr create-repository --repository-name academy-demo --image-tag-mutability IMMUTABLE`. This command needs valid credentials and does not run automatically in this package.
2. Create CodeBuild project `academy-container`, source CodePipeline, artifacts CodePipeline, managed Linux image supporting Node.js 22 and Docker, **privileged mode enabled**. Use root `buildspec-container.yml`. Define nonsecret `ECR_REPOSITORY_URI` as the exact URI. AWS provides `AWS_DEFAULT_REGION`, source revision and build number.
3. Its role needs CloudWatch Logs, the pipeline artifact bucket, `ecr:GetAuthorizationToken` (resource `*`, because that action cannot be scoped), and push actions on the one repository: `BatchCheckLayerAvailability`, `InitiateLayerUpload`, `UploadLayerPart`, `CompleteLayerUpload`, `PutImage`. Add `BatchGetImage`/`GetDownloadUrlForLayer` only if needed for pulling private base images. Do not grant registry-wide administration.
4. Create `academy-container-pipeline`: GitHub source main → CodeBuild `academy-container`. Output artifact name `ImageDefinitions`. Docker uses an unprivileged runtime user and health check. The buildspec tests the application, builds and tags, then pushes only if `CODEBUILD_BUILD_SUCCEEDING` is 1. Tag is 12 characters of commit plus build number, so a rebuild of the same commit does not collide with immutable tags.
5. Push an app update and matching test version. Capture source revision, successful build/test phases, ECR login/build/push log without credentials, image tag, digest and scan result. Verify with `aws ecr describe-images --repository-name academy-demo --image-ids imageTag=ACTUAL_TAG`.
6. Locally, if Docker is available: `docker build -t academy-demo:local .`, then `docker run --rm -p 8080:8080 -e APP_ENV=container academy-demo:local`. Check `/health`. Docker build/run has **not** been verified here because this session cannot access the Docker daemon.

Optional ECS extension: create an ECS/Fargate cluster, compatible task definition/container named `academy-app` exposing 8080, execution role with ECR pull and logs permissions, networking and load balancer health checks, and a healthy service. Add an **Amazon ECS standard deploy action** consuming `ImageDefinitions` and `imagedefinitions.json`. This couples the service update to a successful pipeline build; pushing a tag into ECR alone does not automatically update an existing ECS service. The optional extension is not provisioned in this package.

## Packaging and checks

Each folder can also be exported as a separate source root, but the configured repository uses root buildspecs for the monorepo. `tools/package-sources.py` generates clean ZIP source bundles in a directory you supply; no parent folder is added. The test build produces runtime files separately in CodeBuild. Keep transient local logs and credentials out of source bundles.

Local verification: JavaScript syntax, shell syntax and YAML/JSON parsing passed. The shared app's five HTTP tests passed on Node.js 22.22.0. The copied intentionally broken test yielded 4 passed, 1 failed, exit 1. CloudFormation, cloud IAM permissions, AWS build images, Docker execution, host hooks, trigger events and live endpoints still require actual AWS validation. The included report makes the same distinction.

## Evidence needed before final submission

For every exercise record account alias or redacted account, region, repository URL, main commit, resource names, pipeline/build/deployment IDs, UTC time, screenshots and endpoint where applicable. Do not include AWS access tokens. Save initial and updated application responses to establish that code pushes cause the change. For exercise 2 save both failed and recovered builds. For exercise 4 save health events and the availability log spanning the deployment. For exercise 5 record digest and tag.

## Cleanup after evidence capture

Confirm resources belong to this lab. Disable the lab pipelines and webhooks first. Terminate Beanstalk environments and wait for termination; delete unused application versions/application. If used, remove ECS service/tasks, cluster and associated load balancer resources. Terminate the dedicated EC2 instance and remove its dedicated volumes/security group as appropriate. Delete lab CodePipeline pipelines, CodeBuild projects, CodeDeploy groups/application, ECR demo images/repository, and lab-only S3 objects including versions and buckets. Remove lab-only connection and log groups if no longer shared. Do not delete existing/shared lab roles, default VPC resources or unrelated buckets. Merely ending a browser session does not establish that resources were deleted.

## Official references

- S3 deploy action: https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-S3Deploy.html
- CodeBuild buildspec: https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html
- Webhook filters: https://docs.aws.amazon.com/codebuild/latest/APIReference/API_WebhookFilter.html
- CodeDeploy Ubuntu agent: https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install-ubuntu.html
- CodeDeploy hooks: https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html
- Beanstalk deployment choices: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.deploy-existing-version.html
- CodeBuild ECR sample: https://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html

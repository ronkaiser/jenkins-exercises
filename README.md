#### This project is for the DevOps bootcamp exercise for

#### "Build Automation with Jenkins"

## Overview

This Node.js application is built and deployed through a Jenkins declarative pipeline. Pipeline **logic** lives in a separate [jenkins-exercises-shared-library](https://github.com/ronkaiser/jenkins-exercises-shared-library) repository; this repo contains a thin `Jenkinsfile` that orchestrates stages and passes project-specific values (app directory, Docker image name, Git remote).

## Jenkins Pipeline (`Jenkinsfile`)

The pipeline automates version bumping, testing, Docker image publishing, and committing the result back to Git.

```groovy
@Library('jenkins-shared-library') _
```

### Pipeline stages

| Stage | Shared library step | What it does |
|-------|---------------------|--------------|
| **increment version** | `incrementversion()` | Runs `npm version minor` in `app/`, sets `env.IMAGE_NAME` to `{version}-{BUILD_NUMBER}`. |
| **run tests** | `runtests()` | Installs dependencies and runs the Jest test suite in `app/`. |
| **build and push docker image** | `buildImage()`, `dockerLogin()`, `dockerPush()` | Builds from repo root, logs in to Docker Hub, pushes the tagged image. |
| **commit to git** | `commitToGit(repoUrl, branch, credentialsId)` | Commits the version bump and pushes to `main`. |

Stages that operate on the Node.js app run inside `dir(env.APP_DIR)`. Docker build and Git commit run at the **repository root** (where the `Dockerfile` and `.git` live).

### Shared library

| Item | Value |
|------|-------|
| **Repository** | [github.com/ronkaiser/jenkins-exercises-shared-library](https://github.com/ronkaiser/jenkins-exercises-shared-library) |
| **Library name** | `jenkins-shared-library` |
| **Default branch** | `main` |

See the shared library README for step parameters, folder structure, and reuse in other projects.

### Required Jenkins setup

Before running the pipeline, configure these items in Jenkins:

- **Global Pipeline Library** named `jenkins-shared-library` pointing at the shared library repo (`main` branch). See [Jenkins shared libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/).
- **Node.js tool** named `node` (Manage Jenkins → Tools).
- **Credentials** stored in Jenkins (not in either repo):
  - `docker-hub-repo` — username/password for Docker Hub (used by `dockerLogin()` in the shared library).
  - `github-pat-devops-08` — GitHub username and personal access token (PAT) for pushing commits (passed to `commitToGit()`).

### How credentials are handled

Secrets are never hardcoded in the `Jenkinsfile` or committed to Git. Sensitive steps live in the shared library and use `withCredentials`, which injects values at runtime from the Jenkins credentials store.

**Docker Hub (`dockerLogin` in shared library)**

```groovy
withCredentials([usernamePassword(credentialsId: 'docker-hub-repo', ...)]) {
    sh 'echo $PASS | docker login -u $USER --password-stdin'
}
```

The password is piped to `docker login` via stdin instead of being passed as a command-line flag.

**GitHub (`commitToGit` in shared library)**

```groovy
commitToGit(
    'https://github.com/ronkaiser/jenkins-exercises.git',
    'main',
    'github-pat-devops-08'
)
```

The remote URL has **no embedded credentials**. Username and password are supplied only during `git pull` and `git push` via a temporary credential helper inside `Git.commitVersionBump()`.

### Security design choices

**1. Git credential helper instead of credentials in the URL**

```groovy
// Avoid this pattern
sh "git push https://${USER}:${PASS}@github.com/..."
```

Problems with that approach:

- Groovy double-quoted strings interpolate secrets before the shell runs, which can leak them into pipeline logs if masking fails.
- Special characters in passwords can break URL parsing.
- The full authenticated URL may appear in error messages or debug output.

The shared library uses a temporary Git credential helper:

```groovy
git -c "credential.helper=!f() { echo username=$GIT_USER; echo password=$GIT_PASS; }; f" push origin HEAD:main
```

**2. `GIT_USER` / `GIT_PASS` instead of `USER` / `PASS`**

On Unix systems, `USER` is already a standard environment variable (the OS login name, e.g. `jenkins`). Using `USER` as a credential variable name can cause conflicts when shell commands expand `$USER`. The Git step uses `GIT_USER` and `GIT_PASS` to avoid that ambiguity.

**3. Idempotent commit**

```groovy
sh 'git diff --cached --quiet || git commit -m "ci: version bump"'
```

`git commit` fails when there is nothing to commit. The `||` guard skips the commit when there are no staged changes.

**4. Rebase before push**

```groovy
git pull --rebase origin main
git push origin HEAD:main
```

If `main` moved forward while the build was running, pulling with rebase first replays the version-bump commit on top of the latest remote history.

## Tests

The project uses the Jest library for tests (see the `test` script in `package.json`). There is one test (`server.test.js`) that checks whether `index.html` exists.

To run tests locally:

```bash
cd app
npm install
npm run test
```

To see a failing test, remove or rename `index.html` and run tests again.

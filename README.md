#### This project is for the DevOps bootcamp exercise for

#### "Build Automation with Jenkins"

## Jenkins Pipeline (`Jenkinsfile`)

The project includes a declarative Jenkins pipeline that automates version bumping, testing, Docker image publishing, and committing the result back to Git.

### Pipeline stages

| Stage | What it does |
|-------|----------------|
| **increment version** | Runs `npm version minor` in `app/`, then sets `IMAGE_NAME` to `{version}-{BUILD_NUMBER}` for a unique Docker tag. |
| **run tests** | Installs dependencies and runs the Jest test suite. |
| **build and push docker image** | Builds the image, logs in to Docker Hub, and pushes the tagged image. |
| **commit to git** | Commits the version bump to the repo and pushes to `main`. |

### Required Jenkins setup

Before running the pipeline, configure these items in Jenkins:

- **Node.js tool** named `node` (Manage Jenkins → Tools).
- **Credentials** stored in Jenkins (not in the repo):
  - `docker-hub-repo` — username/password for Docker Hub.
  - `github-pat-devops-08` — GitHub username and personal access token (PAT) for pushing commits.

### How credentials are handled

Secrets are never hardcoded in the `Jenkinsfile` or committed to Git. Each sensitive step wraps its shell commands in a `withCredentials` block, which injects values at runtime from the Jenkins credentials store.

**Docker Hub (build stage)**

```groovy
withCredentials([usernamePassword(credentialsId: 'docker-hub-repo', ...)]) {
    sh 'echo $PASS | docker login -u $USER --password-stdin'
}
```

The password is piped to `docker login` via stdin instead of being passed as a command-line flag. That keeps it out of the process list and reduces the chance of it appearing in logs.

**GitHub (commit stage)**

```groovy
withCredentials([usernamePassword(credentialsId: 'github-pat-devops-08', passwordVariable: 'GIT_PASS', usernameVariable: 'GIT_USER')]) {
    sh "git remote set-url origin https://github.com/ronkaiser/jenkins-exercises.git"
    // pull and push use a credential helper (see below)
}
```

The remote URL is set **without** credentials embedded in it. Credentials are only supplied during `git pull` and `git push`, so they are not persisted in `.git/config` on the Jenkins agent.

### Security design choices

**1. Git credential helper instead of credentials in the URL**

An early approach embeds credentials directly in the push URL:

```groovy
// Avoid this pattern
sh "git push https://${USER}:${PASS}@github.com/..."
```

Problems with that approach:

- Groovy double-quoted strings interpolate secrets before the shell runs, which can leak them into pipeline logs if masking fails.
- Special characters in passwords can break URL parsing.
- The full authenticated URL may appear in error messages or debug output.

The pipeline instead uses a temporary Git credential helper that supplies username and password only when Git needs them:

```groovy
git -c "credential.helper=!f() { echo username=$GIT_USER; echo password=$GIT_PASS; }; f" push origin HEAD:main
```

Credentials stay out of the remote URL and are not written to disk.

**2. `GIT_USER` / `GIT_PASS` instead of `USER` / `PASS`**

On Unix systems, `USER` is already a standard environment variable (the OS login name, e.g. `jenkins`). Using `USER` as a credential variable name can cause conflicts when shell commands expand `$USER` — the system value may be used instead of the Jenkins credential. Renaming to `GIT_USER` and `GIT_PASS` avoids that ambiguity.

**3. Idempotent commit**

```groovy
sh 'git diff --cached --quiet || git commit -m "ci: version bump"'
```

`git commit` fails with a non-zero exit code when there is nothing to commit. The `||` guard skips the commit when there are no staged changes, so a re-run or edge case does not fail the whole pipeline unnecessarily.

**4. Rebase before push**

```groovy
git pull --rebase origin main
git push origin HEAD:main
```

If `main` moved forward while the build was running (another merge or concurrent job), a plain push would fail. Pulling with rebase first replays the version-bump commit on top of the latest remote history, reducing push conflicts.

##### Test
The project uses jest library for tests. (see "test" script in package.json)
There is 1 test (server.test.js) in the project that checks whether the main index.html file exists in the project. 

To run the nodejs test:

    npm run test

Make sure to download jest library before running test, otherwise jest command defined in package.json won't be found.

    npm install

In order to see failing test, remove index.html or rename it and run tests.

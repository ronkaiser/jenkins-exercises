pipeline{
    agent any
    tools {
        nodejs 'node'
    }
    environment {
        APP_DIR = 'app'
    }
    stages{
        stage("increment version"){
            steps{
                script {
                    dir(env.APP_DIR) {
                        incrementversion()
                    }
                }
            }
        }
        stage("run tests"){
            steps{
                dir(env.APP_DIR) {
                    echo "run tests"
                    sh 'npm install && npm test'
                }
            }
        }
        stage("build and push docker image"){
            steps{
                script {
                    echo "building the docker image..."
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-repo', passwordVariable: 'PASS', usernameVariable: 'USER')]){
                        sh "docker build -t ronkaiser86/myapp:${env.IMAGE_NAME} ."
                        sh 'echo $PASS | docker login -u $USER --password-stdin'
                        sh "docker push ronkaiser86/myapp:${env.IMAGE_NAME}"
                    }
                }
            }
        }
        stage("commit to git"){
            steps{
                script{
                    withCredentials([usernamePassword(credentialsId: 'github-pat-devops-08', passwordVariable: 'GIT_PASS', usernameVariable: 'GIT_USER')]){
                        sh 'git config --global user.email "jenkins@example.com"'
                        sh 'git config --global user.name "jenkins"'

                        sh 'git status'
                        sh 'git branch'
                        sh 'git config --list'

                        sh "git remote set-url origin https://github.com/ronkaiser/jenkins-exercises.git"
                        sh 'git add .'
                        sh 'git diff --cached --quiet || git commit -m "ci: version bump"'
                        sh '''
                            git -c "credential.helper=!f() { echo username=$GIT_USER; echo password=$GIT_PASS; }; f" pull --rebase origin main
                            git -c "credential.helper=!f() { echo username=$GIT_USER; echo password=$GIT_PASS; }; f" push origin HEAD:main
                        '''
                    }
                }
            }
        }
    }
}
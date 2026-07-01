@Library('jenkins-shared-library') _

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
                    runtests()
                }
            }
        }
        stage("build and push docker image"){
            steps{
                script {
                    def imageName = "ronkaiser86/myapp:${env.IMAGE_NAME}"
                    buildImage(imageName)
                    dockerLogin()
                    dockerPush(imageName)
                }
            }
        }
        stage("commit to git") {
            steps {
                script {
                    commitToGit(
                        'https://github.com/ronkaiser/jenkins-exercises.git',
                        'main',
                        'github-pat-devops-08'
                    )
                }
            }
        }
    }
}
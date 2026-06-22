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
                        echo "incrementing app version..."
                        sh 'npm version minor --no-git-tag-version'

                        def pkg = readJSON file: 'package.json'
                        def version = pkg.version

                        env.IMAGE_NAME = "${version}-${env.BUILD_NUMBER}"
                        echo "Image tag: ${env.IMAGE_NAME}"
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
    }
}
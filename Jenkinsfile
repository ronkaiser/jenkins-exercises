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
                dir(env.APP_DIR) {
                    echo "incrementing app version..."
                    sh 'npm version minor -no-git-tag-version'
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
    }
}
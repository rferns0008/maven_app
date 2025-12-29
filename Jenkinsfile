pipeline {
    agent any

    tools {
        maven 'maven-3.9.9'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Maven') {
            steps {
                sh 'mvn -version'
            }
        }

        stage('Build Maven App') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                        docker build -t rferns/maven-app:latest .
                        docker push rferns/maven-app:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy via Ansible') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                        set -e
                        ansible-playbook ansible/deploy.yml \
                          -i ansible/hosts.ini
                    '''
                }
            }
        }
    }
}

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

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t my-app:latest .'
            }
        }

		stage('Deploy via Ansible') {
			steps {
				sshagent(credentials: ['ec2-ssh-key']) {
					sh '''
						ansible-playbook ansible/deploy.yml \
						-i ansible/hosts.ini
					'''
				}
			}
		}
	}
}

pipeline {
    agent any

    options {
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Read target host from Ansible inventory') {
            steps {
                script {
                    def targetHost = powershell(
                        script: '''
                        Get-Content ansible\\hosts.ini |
                        Where-Object { $_ -and $_ -notmatch '^\\s*#' } |
                        Select-Object -First 1
                        ''',
                        returnStdout: true
                    ).trim()

                    if (!targetHost) {
                        error "No valid host found in ansible/hosts.ini"
                    }

                    echo "Target host resolved as: ${targetHost}"
                    env.TARGET_HOST = targetHost
                }
            }
        }

        stage('Build') {
            steps {
                echo "Running Maven build (system Maven)"
                bat 'mvn -version'
                bat 'mvn clean package'
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploying to ${env.TARGET_HOST}"
                bat '''
                wsl ansible-playbook ansible/deploy.yml ^
                  -i ansible/hosts.ini ^
                  --extra-vars "target_host=%TARGET_HOST%"
                '''
            }
        }
    }

    post {
        always {
            script {
                // cleanWs MUST run inside a workspace context
                cleanWs()
            }
        }
    }
}
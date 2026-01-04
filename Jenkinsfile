pipeline {
    agent any

    environment {
        MAVEN_HOME = tool name: 'Maven', type: 'maven'
        PATH = "${MAVEN_HOME}\\bin;${env.PATH}"
    }

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
                    /*
                     * Read first non-empty line from ansible/hosts.ini
                     * Windows-safe implementation
                     */
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
                echo "Starting Maven build..."
                bat 'mvn clean package'
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploying to ${env.TARGET_HOST}"

                /*
                 * Use Ansible from Windows
                 * Assumes ansible is installed and available in PATH
                 */
                bat '''
                ansible-playbook ansible/deploy.yml ^
                  -i ansible/hosts.ini ^
                  --extra-vars "target_host=%TARGET_HOST%"
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully"
        }
        failure {
            echo "Pipeline failed — check stage logs above"
        }
        always {
            cleanWs()
        }
    }
}
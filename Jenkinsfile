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
                echo "Running Maven build"
                bat 'mvn -version'
                bat 'mvn clean package'
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    bat '''
                    REM ===============================
                    REM Prepare SSH key inside WSL
                    REM ===============================

                    wsl mkdir -p /tmp/jenkins-ssh

                    REM Convert Windows key path to WSL path
                    for /f %%i in ('wsl wslpath "%SSH_KEY%"') do set WSL_KEY=%%i

                    REM Copy key and secure permissions
                    wsl cp "%WSL_KEY%" /tmp/jenkins-ssh/id_rsa
                    wsl chmod 600 /tmp/jenkins-ssh/id_rsa

                    REM ===============================
                    REM Run Ansible deploy
                    REM ===============================

                    wsl ansible-playbook ansible/deploy.yml ^
                      -i ansible/hosts.ini ^
                      -u %SSH_USER% ^
                      --private-key /tmp/jenkins-ssh/id_rsa ^
                      --ssh-common-args="-o StrictHostKeyChecking=no"
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                cleanWs()
            }
        }
    }
}

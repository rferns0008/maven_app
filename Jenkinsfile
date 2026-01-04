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
                    REM =====================================
                    REM Prepare SSH key inside WSL
                    REM =====================================

                    wsl mkdir -p /tmp/jenkins-ssh

                    REM Convert Windows path -> WSL path
                    for /f %%i in ('wsl wslpath "%SSH_KEY%"') do set WSL_KEY=%%i

                    REM Copy key and set permissions
                    wsl cp "%WSL_KEY%" /tmp/jenkins-ssh/id_rsa
                    wsl chmod 600 /tmp/jenkins-ssh/id_rsa

                    REM =====================================
                    REM Run Ansible deployment
                    REM =====================================

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
                try {
                    cleanWs(
                        deleteDirs: true,
                        disableDeferredWipeout: true,
                        notFailBuild: true
                    )
                } catch (err) {
                    echo "Workspace cleanup skipped (Windows file lock): ${err}"
                }
            }
        }
    }
}
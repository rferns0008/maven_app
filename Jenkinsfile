pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Read target host from Ansible inventory') {
            steps {
                script {
                    env.TARGET_HOST = sh(
                        script: '''
                            awk 'NF {print $1; exit}' ansible/hosts.ini
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Target host resolved from hosts.ini: ${env.TARGET_HOST}"
                }
            }
        }

        stage('Build') {
            steps {
                echo "Build stage placeholder"
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo "Deploying to ${env.TARGET_HOST}"

                    withCredentials([
                        sshUserPrivateKey(
                            credentialsId: 'ec2-ssh-key',
                            keyFileVariable: 'SSH_KEY',
                            usernameVariable: 'SSH_USER'
                        )
                    ]) {
                        sh """
                            export ANSIBLE_HOST_KEY_CHECKING=False
                            ansible-playbook \
                              -i ansible/hosts.ini \
                              ansible/deploy.yml \
                              --private-key ${SSH_KEY} \
                              -u ${SSH_USER} \
                              --extra-vars "target_host=${env.TARGET_HOST}"
                        """
                    }
                }
            }
        }
    }
}

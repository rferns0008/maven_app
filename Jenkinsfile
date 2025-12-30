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
                    def TARGET_HOST = sh(
                        script: '''
                            awk 'NF {print $1; exit}' ansible/hosts.ini
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Target host resolved from hosts.ini: ${TARGET_HOST}"
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
                    echo "Deploying to ${TARGET_HOST}"

                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook \
                          -i ansible/hosts.ini \
                          ansible/deploy.yml \
                          --extra-vars "target_host=${TARGET_HOST}"
                    """
                }
            }
        }
    }
}

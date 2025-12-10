pipeline {
    agent any

    environment {
        IMAGE_REPO = "rferns/maven-app"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${IMAGE_REPO}:${IMAGE_TAG}"

        ANSIBLE_PLAY = "ansible/deploy.yml"
        ANSIBLE_INV  = "ansible/hosts.ini"

        EC2_HOST = ""   // will be filled dynamically
    }

    stages {

        /* ---------------------------------------------------------- */
        stage('Checkout Code') {
            steps { checkout scm }
        }

        /* ---------------------------------------------------------- */
        stage('Locate hosts.ini') {
            steps {
                script {
                    sh "echo '=== DEBUG: WORKSPACE CONTENTS ===' && ls -R ${WORKSPACE}"

                    // Search for hosts.ini anywhere in the workspace
                    def foundFile = sh(
                        script: "find ${WORKSPACE} -type f -name 'hosts.ini' | head -1",
                        returnStdout: true
                    ).trim()

                    if (!foundFile) {
                        error("""
ERROR: hosts.ini not found anywhere in workspace!

Expected one:
 - ${WORKSPACE}/ansible/hosts.ini
 - ${WORKSPACE}/maven_app/ansible/hosts.ini

Fix your repo structure OR update Jenkinsfile paths.
""")
                    }

                    env.ANSIBLE_INV = foundFile
                    echo "FOUND hosts.ini at: ${env.ANSIBLE_INV}"
                }
            }
        }

        /* ---------------------------------------------------------- */
        stage('Read EC2 IP from hosts.ini') {
            steps {
                script {
                    echo "Reading EC2 IP from: ${env.ANSIBLE_INV}"

                    EC2_HOST = sh(
                        script: "grep -Eo '[0-9]{1,3}(\\.[0-9]{1,3}){3}' ${env.ANSIBLE_INV} | head -1",
                        returnStdout: true
                    ).trim()

                    echo "DEBUG: Extracted EC2_HOST='${EC2_HOST}'"

                    if (!EC2_HOST) {
                        error("ERROR: No valid IP found inside ${env.ANSIBLE_INV}")
                    }
                }
            }
        }

        /* ---------------------------------------------------------- */
        stage('Build Maven App') {
            steps { sh "mvn clean package -DskipTests" }
        }

        /* ---------------------------------------------------------- */
        stage('Build Docker Image') {
            steps { sh "docker build -t ${FULL_IMAGE} ." }
        }

        /* ---------------------------------------------------------- */
        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'dockerhub-creds',
                                     usernameVariable: 'DC_USER',
                                     passwordVariable: 'DC_PASS')
                ]) {
                    sh """
                        echo "$DC_PASS" | docker login -u "$DC_USER" --password-stdin
                        docker push ${FULL_IMAGE}
                        docker logout
                    """
                }
            }
        }

        /* ---------------------------------------------------------- */
        stage('Deploy via Ansible') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ansible-ssh-key',
                                      keyFileVariable: 'SSH_KEY')
                ]) {

                    sh """
                        echo "=== Running Ansible Deployment ==="

                        export ANSIBLE_HOST_KEY_CHECKING=False

                        # Prepare SSH key
                        cp ${SSH_KEY} ./key.pem
                        chmod 600 ./key.pem

                        ansible-playbook ${ANSIBLE_PLAY} \
                            -i ${ANSIBLE_INV} \
                            --private-key ./key.pem \
                            --extra-vars "docker_image=${FULL_IMAGE} target_host=${EC2_HOST}"
                    """
                }
            }
        }
    }

    post {
        success { echo "SUCCESS — Docker EC2 Deployment Completed: ${FULL_IMAGE}" }
        failure { echo "FAILED — Check logs." }
    }
}

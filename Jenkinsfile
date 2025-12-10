pipeline {
    agent any

    environment {
        IMAGE_REPO = "rferns/maven-app"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${IMAGE_REPO}:${IMAGE_TAG}"

        ANSIBLE_PLAY = "./ansible/deploy.yml"
        ANSIBLE_INV  = ""    // dynamically located
        EC2_HOST     = ""    // extracted from hosts.ini
    }

    stages {

        /* --------------------------------------------------------------- */
        stage('Checkout Code') {
            steps { checkout scm }
        }

        /* --------------------------------------------------------------- */
        /* DEBUG WORKSPACE STRUCTURE                                       */
        /* --------------------------------------------------------------- */
        stage('Debug Workspace') {
            steps {
                sh """
                    echo "=== DEBUG: WORKSPACE PATH ==="
                    pwd

                    echo "=== DEBUG: ROOT CONTENTS ==="
                    ls -la

                    echo "=== DEBUG: RECURSIVE LISTING ==="
                    ls -R .

                    echo "=== DEBUG: SEARCHING FOR hosts.ini ==="
                    find . -type f -name 'hosts.ini' -print || true
                """
            }
        }

        /* --------------------------------------------------------------- */
        /* LOCATE hosts.ini ANYWHERE IN WORKSPACE                          */
        /* --------------------------------------------------------------- */
        stage('Locate hosts.ini') {
            steps {
                script {
                    echo "=== Locating hosts.ini in workspace ==="

                    def hostsFile = sh(
                        script: "find ${WORKSPACE} -type f -name 'hosts.ini' | head -1",
                        returnStdout: true
                    ).trim()

                    echo "DEBUG: hostsFile='${hostsFile}'"

                    if (!hostsFile) {
                        error("""
ERROR: hosts.ini not found anywhere in workspace!

Expected a file like:
/var/lib/jenkins/workspace/<job>/ansible/hosts.ini
""")
                    }

                    env.ANSIBLE_INV = hostsFile
                    echo "FOUND hosts.ini at: ${env.ANSIBLE_INV}"

                    echo "=== hosts.ini contents ==="
                    sh "cat ${env.ANSIBLE_INV}"
                }
            }
        }

        /* --------------------------------------------------------------- */
        /* EXTRACT EC2 IP FROM hosts.ini                                   */
        /* --------------------------------------------------------------- */
        stage('Read EC2 IP from hosts.ini') {
            steps {
                script {
                    EC2_HOST = sh(
                        script: "grep -Eo '[0-9]{1,3}(\\.[0-9]{1,3}){3}' ${ANSIBLE_INV} | head -1",
                        returnStdout: true
                    ).trim()

                    if (!EC2_HOST) {
                        error("ERROR: No valid IP found inside ${ANSIBLE_INV}")
                    }

                    echo "Using EC2 host: ${EC2_HOST}"
                }
            }
        }

        /* --------------------------------------------------------------- */
        stage('Build Maven App') {
            steps {
                sh "mvn clean package -DskipTests"
            }
        }

        /* --------------------------------------------------------------- */
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ."
            }
        }

        /* --------------------------------------------------------------- */
        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DC_USER',
                        passwordVariable: 'DC_PASS'
                    )
                ]) {
                    sh """
                        echo "$DC_PASS" | docker login -u "$DC_USER" --password-stdin
                        docker push ${FULL_IMAGE}
                        docker logout
                    """
                }
            }
        }

        /* --------------------------------------------------------------- */
        stage('Deploy via Ansible') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ansible-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    )
                ]) {

                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False

                        echo "Deploying to: ${EC2_HOST}"

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
        success { echo "SUCCESS — Docker pipeline completed: ${FULL_IMAGE}" }
        failure { echo "FAILED — check logs." }
    }
}

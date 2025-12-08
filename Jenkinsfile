pipeline {
    agent any

    environment {
        IMAGE_REPO = "rferns/maven-app"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${IMAGE_REPO}:${IMAGE_TAG}"

        ANSIBLE_PLAY = "./ansible/deploy.yml"
        ANSIBLE_INV  = "./ansible/hosts.ini"

        EC2_HOST = ""
    }

    stages {

        stage('Checkout Code') {
            steps { checkout scm }
        }

        stage('Read EC2 IP from hosts.ini') {
            steps {
                script {
                    EC2_HOST = sh(
                        script: "grep -Eo '^[0-9]{1,3}(\\.[0-9]{1,3}){3}' ansible/hosts.ini | head -1",
                        returnStdout: true
                    ).trim()

                    if (!EC2_HOST) {
                        error("No valid IP found in ansible/hosts.ini")
                    }

                    echo "Using EC2 host: ${EC2_HOST}"
                }
            }
        }

        stage('Build Maven App') {
            steps {
                sh "mvn clean package -DskipTests"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DC_USER',
                    passwordVariable: 'DC_PASS'
                )]) {

                    sh """
                        echo "$DC_PASS" | docker login -u "$DC_USER" --password-stdin
                        docker push ${FULL_IMAGE}
                        docker logout
                    """
                }
            }
        }

        stage('Deploy via Ansible') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ansible-ssh-key',
                    keyFileVariable: 'SSH_KEY'
                )]) {

                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        cp ${SSH_KEY} ./key.pem
                        chmod 600 ./key.pem

                        ansible-playbook ${ANSIBLE_PLAY} \
                            -i ${ANSIBLE_INV} \
                            --private-key ./key.pem \
                            --extra-vars "docker_image=${FULL_IMAGE}"
                    """
                }
            }
        }
    }

    post {
        success { echo "Docker pipeline completed successfully: ${FULL_IMAGE}" }
        failure { echo "Docker pipeline failed — check logs." }
    }
}

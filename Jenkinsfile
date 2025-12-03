pipeline {
    agent any

    environment {
        IMAGE_REPO = "rferns/maven-app"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${IMAGE_REPO}:${IMAGE_TAG}"

        ANSIBLE_PLAY = "./ansible/deploy.yml"
        ANSIBLE_INV  = "./ansible/hosts.ini"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/rferns0008/maven_app.git', branch: 'main'
            }
        }

        stage('Build Maven App') {
            steps {
                sh """
                    mvn clean package -DskipTests
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${FULL_IMAGE} .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DC_USER', passwordVariable: 'DC_PASS')]) {

                    sh """
                        echo "$DC_PASS" | docker login -u "$DC_USER" --password-stdin
                        docker push ${FULL_IMAGE}
                        docker logout
                    """
                }
            }
        }

        stage('Deploy App to EC2 via Ansible') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ansible-ssh-key',
                    keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {

                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        cp ${SSH_KEY} ./key.pem
                        chmod 600 ./key.pem

                        ansible-playbook ${ANSIBLE_PLAY} -i ${ANSIBLE_INV} \
                        --private-key ./key.pem \
                        --extra-vars "docker_image=${FULL_IMAGE}"
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully! Deployed: ${FULL_IMAGE}"
        }
        failure {
            echo "Pipeline failed — Check logs."
        }
    }
}

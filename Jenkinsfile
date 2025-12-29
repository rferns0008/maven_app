pipeline {
    agent any

    environment {
        IMAGE_REPO = "rferns/maven-app"
        IMAGE_TAG  = "latest"
        FULL_IMAGE = "${IMAGE_REPO}:${IMAGE_TAG}"

        ANSIBLE_PLAY = "./ansible/deploy.yml"
        ANSIBLE_INV  = ""
        EC2_HOST     = ""
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Debug Workspace') {
            steps {
                sh '''
                    echo "=== WORKSPACE ==="
                    pwd
                    echo "=== CONTENTS ==="
                    ls -la
                    echo "=== FIND hosts.ini ==="
                    find . -type f -name hosts.ini -print
                '''
            }
        }

		stage('Locate hosts.ini') {
			steps {
				script {
				// HARD-CODE repo-relative path (this is correct practice)
					def inventoryPath = 'ansible/hosts.ini'

				// Validate using LOCAL variable ONLY
				if (!fileExists(inventoryPath)) {
					error("ERROR: hosts.ini not found at ${inventoryPath}")
				}

				echo "FOUND hosts.ini at: ${inventoryPath}"
				sh "cat ${inventoryPath}"

				// Export ONLY after validation, for later stages
				env.ANSIBLE_INV = inventoryPath
				}
			}
		}

		stage('Read EC2 IP from hosts.ini') {
			steps {
				script {
					def inventoryPath = 'ansible/hosts.ini'
					def content = readFile(inventoryPath)

					def matcher = (content =~ /\b(\d{1,3}\.){3}\d{1,3}\b/)
					if (!matcher.find()) {
						error("ERROR: No EC2 IP found in ${inventoryPath}")
					}

					env.EC2_HOST = matcher.group(0)
					echo "Using EC2 host: ${env.EC2_HOST}"
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
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DC_USER',
                        passwordVariable: 'DC_PASS'
                    )
                ]) {
                    sh '''
                        echo "$DC_PASS" | docker login -u "$DC_USER" --password-stdin
                        docker push ${FULL_IMAGE}
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy via Ansible') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ansible-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    )
                ]) {
                    sh '''
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        cp ${SSH_KEY} ./key.pem
                        chmod 600 ./key.pem

                        ansible-playbook ${ANSIBLE_PLAY} \
                          -i ${ANSIBLE_INV} \
                          --private-key ./key.pem \
                          --extra-vars "docker_image=${FULL_IMAGE} target_host=${EC2_HOST}"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "SUCCESS — Pipeline completed: ${FULL_IMAGE}"
        }
        failure {
            echo "FAILED — check logs."
        }
    }
}

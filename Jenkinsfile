pipeline {
    agent any

    environment {
        IMAGE_REPO = "rferns/maven-app"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${IMAGE_REPO}:${IMAGE_TAG}"

        ANSIBLE_PLAY = "ansible/deploy.yml"

        // Will be discovered dynamically (no hardcoded IP)
        ANSIBLE_INV  = ""
        EC2_HOST     = ""
    }

    stages {

        /* --------------------------------------------------------------- */
        stage('Checkout Code') {
            steps { checkout scm }
        }

	stage('Debug Workspace') {
    	    steps {
        	sh """
            	   echo '=== DEBUG: WORKSPACE PATH ==='
                   pwd

            	echo '=== DEBUG: GIT TOP LEVEL ==='
            	git rev-parse --show-toplevel || true

            	echo '=== DEBUG: ROOT DIRECTORY CONTENTS ==='
            	ls -la

            	echo '=== DEBUG: RECURSIVE LISTING ==='
            	ls -R .

            	echo '=== DEBUG: SEARCHING FOR hosts.ini ==='
            	find . -type f -name 'hosts.ini' -print || true
        	"""
    }
}

        /* --------------------------------------------------------------- */
        /*  FIND hosts.ini ANYWHERE in the workspace                       */
        /* --------------------------------------------------------------- */
	stage('Locate hosts.ini') {
    	    steps {
        	script {
            	    sh "echo '=== DEBUG: FINDING hosts.ini IN WORKSPACE ==='; pwd; ls -R ."

            	    def hostsFile = sh(
                	script: "find . -type f -name 'hosts.ini' | head -1",
                	returnStdout: true
            	    ).trim()

            	    if (!hostsFile) {
               	        error("""
		        ERROR: hosts.ini not found anywhere in workspace!
                        """)
            }

            env.ANSIBLE_INV = hostsFile
            echo "FOUND hosts.ini at: ${env.ANSIBLE_INV}"
        }
    }
}

        /* --------------------------------------------------------------- */
        /*  READ EC2 IP FROM ansible/hosts.ini                             */
        /* --------------------------------------------------------------- */
        stage('Extract EC2 IP') {
            steps {
                script {
                    sh "echo '=== Parsing IP from: ${env.ANSIBLE_INV} ==='; cat ${env.ANSIBLE_INV}"

                    EC2_HOST = sh(
                        script: "grep -Eo '[0-9]{1,3}(\\.[0-9]{1,3}){3}' ${env.ANSIBLE_INV} | head -1",
                        returnStdout: true
                    ).trim()

                    if (!EC2_HOST) {
                        error("ERROR: No valid IP found in ${env.ANSIBLE_INV}")
                    }

                    echo "Using EC2 Host: ${EC2_HOST}"
                }
            }
        }

        /* --------------------------------------------------------------- */
        stage('Build Maven App') {
            steps { sh "mvn clean package -DskipTests" }
        }

        /* --------------------------------------------------------------- */
        stage('Build Docker Image') {
            steps { sh "docker build -t ${FULL_IMAGE} ." }
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

                        echo "Deploying to host: ${EC2_HOST}"

                        # Prepare SSH key for Ansible
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
        failure { echo "DEPLOYMENT FAILED — Check logs." }
    }
}

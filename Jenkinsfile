pipeline {
    agent any

    environment {
        // Ensure this repo exists in your DockerHub
        IMAGE_REPO = "ravitejasimhadri75/fullstack-cicd-demo"
        // Ensure this ID matches what you added in Jenkins Credentials
        DOCKER_CRED_ID = "dockerhub-creds" 
        IMAGE_TAG = "${env.BUILD_ID}"
    }
    
   

    tools {
        maven 'maven3'   
        nodejs 'node'    
        // nodejs 'node' // Uncomment if you have Node installed in Global Tools
    }

    stages {
      
			stage('Checkout') {
			  steps {
				checkout scm
			 }
		}


		stage('Build Frontend (optional)') {
		  steps {
			script {
			  if (fileExists('frontend/package.json')) {
				dir('frontend') {
				  // npm ci fails if no package-lock; adjust if needed
				  sh 'npm ci || npm install'
				  // run build if script exists
				  sh 'npm run build || echo "no frontend build script or build skipped"'
				}
			  } else {
				echo "No frontend found, skipping frontend stage."
			  }
			}
		  }
		}

    stage('Build Frontend Docker Image') {
    steps {
        script {
            echo "Building Frontend Docker Image..."

            // Move into frontend so Dockerfile.frontend is found
            dir('frontend') {
                // Build Angular image
                def frontendImg = docker.build("${IMAGE_REPO}-frontend:${IMAGE_TAG}", "-f Dockerfile.frontend .")
                
                // Store image reference for pushing in next stage
                env.FRONTEND_IMAGE = "${IMAGE_REPO}-frontend:${IMAGE_TAG}"
            }
        }
    }
  }

  stage('Push Frontend Docker Image') {
    steps {
        script {
            echo "Pushing Frontend Docker Image to DockerHub..."

            docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CRED_ID}") {

                def img = docker.image(env.FRONTEND_IMAGE)

                img.push()          // Push version tag
                img.tag('latest')   // Also push latest
                img.push('latest')
            }
        }
    }
}



		stage('Build Backend') {
			steps {
				dir('backend') {
					// Windows 'bat' command
					bat 'mvn -B clean package -DskipTests=false'
				}
			}
		}
		   
		stage('Unit Tests (backend)') {
			steps {
				dir('backend') {
					bat 'mvn -B test'
				}
			}
		}
        
        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('MySonar') {
                    // Note: In Windows BAT, use ^ for line breaks, not \
                    bat """
                        mvn -B -f backend/pom.xml sonar:sonar ^
                        -Dsonar.projectKey=fullstack-cicd-demo.backend ^
                        -Dsonar.projectName="Fullstack CI/CD Demo - Backend" ^
                        -Dsonar.host.url=%SONAR_HOST_URL% ^
                        -Dsonar.login=%SONAR_AUTH_TOKEN%
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Quality Gate failed: ${qg.status}"
                        } else {
                            echo "Quality Gate passed: ${qg.status}"
                        }
                    }
                }
            }
        }

       

		stage('Build Docker Image') {
			steps {
				script {
					echo "Building Docker Image..."
					// Change directory to 'backend' so Docker finds the Dockerfile there
					
						// This builds the image and tags it locally
						docker.build("${IMAGE_REPO}:${IMAGE_TAG}")
				   
				}
			}
		}

        stage('Trivy Image Scan') {
          steps {
            script {
              echo "Preparing Trivy cache volume..."
              bat 'docker volume create trivy-cache || echo "volume exists"'
        
              echo "Saving Docker image to tar..."
              bat "docker save ${IMAGE_REPO}:${IMAGE_TAG} -o image.tar"
        
              echo "Scanning image.tar with Trivy (increased timeout + more resources)..."
              // Increase timeout to 10 minutes, allow container to use up to 4GB RAM and 2 CPUs
              // Adjust --memory / --cpus values if your Docker Desktop / host can't allocate that much.
              bat """
                docker run --rm --memory 4g --cpus 2 -v trivy-cache:/root/.cache/trivy -v %CD%:/workspace \
                  aquasec/trivy:latest image --input /workspace/image.tar \
                  --format json -o /workspace/trivy-report.json --severity HIGH,CRITICAL --exit-code 1 --timeout 10m
              """
        
              echo "Archiving Trivy JSON report..."
              archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: false
        
              // cleanup the tar
              bat 'del /Q image.tar || echo "no tar to delete"'
            }
          }
		}



		stage('Push Docker Image') {
			steps {
				script {
					echo "Pushing to Docker Hub..."
					// Log in to Docker Hub
					docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CRED_ID}") {
						// We wrap the image string again to use the push method
						def img = docker.image("${IMAGE_REPO}:${IMAGE_TAG}")
						
						// Push the specific version tag
						img.push()
						
						// Tag and push 'latest'
						img.tag('latest')
						img.push('latest')
					}
				}
			}
		}
		}

    post {
        always {
            // Clean up workspace to save disk space
            cleanWs()
        }
        success {
            echo "SUCCESS: ${IMAGE_REPO}:${IMAGE_TAG} pushed."
        }
        failure {
            echo "Build FAILED. Check console log."
        }
    }
}

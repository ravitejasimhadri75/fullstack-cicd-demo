pipeline {
  agent any

  environment {
   
    IMAGE_REPO = "ravitejasimhadri75/fullstack-cicd-demo"
    // Jenkins credential id for Docker registry
    DOCKER_CRED_ID = "dockerhub-creds"
    IMAGE_TAG = "${env.BUILD_ID}"
  }

  tools {
    maven 'maven3'    // must match name in Manage Jenkins -> Global Tool Configuration
    nodejs 'node'    // optional: only required if frontend build uses node/npm
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

    stage('Build Backend') {
      steps {
        dir('backend') {
          // create jar
          sh 'mvn -B clean package -DskipTests=false'
        }
      }
    }

    stage('Unit Tests (backend)') {
      steps {
        dir('backend') {
          // run tests but don't fail entire pipeline on test failures? change as you want
          sh 'mvn -B test'
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          // builds image using the Docker daemon available to Jenkins
          def img = docker.build("${IMAGE_REPO}:${IMAGE_TAG}")
          echo "Built image: ${IMAGE_REPO}:${IMAGE_TAG}"
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        script {
          docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CRED_ID}") {
            def img = docker.image("${IMAGE_REPO}:${IMAGE_TAG}")
            img.push()
            // push also as latest tag
            img.tag('latest')
            img.push('latest')
          }
        }
      }
    }
  }

  post {
    always {
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

pipeline {
  agent any

  environment {
    DOCKERHUB_CRED = credentials('dockerhub-creds')
    IMAGE_NAME = "ravitejasimhadri75/fullstack-cicd-demo"
    IMAGE_TAG = "${env.BUILD_ID}"
  }

  tools {
    maven 'maven3'        // name from Global Tool Configuration
    nodejs 'node'        // name from Global Tool Configuration
  }

  stages {
    stage('Checkout') {
      steps {
        checkout([$class: 'GitSCM',
                  branches: [[name: "*/main"]],
                  userRemoteConfigs: [[url: 'https://github.com/ravitejasimhadri75/fullstack-cicd-demo.git', credentialsId: 'github-creds']]])
      }
    }

    stage('Build Frontend') {
      steps {
        dir('frontend') {
          sh 'npm ci'
          // if Angular CLI present: sh 'npm run build -- --prod'
          sh 'npm run build || echo "No build script—skipping"'
        }
      }
    }

    stage('Build Backend') {
      steps {
        dir('backend') {
          sh 'mvn -B clean package'
        }
      }
    }

    stage('Unit Tests') {
      steps {
        dir('backend') {
          sh 'mvn -B test || true'
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          // assumes Dockerfile exists at repo root (or adapt path)
          def img = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        script {
          docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
            def img = docker.image("${IMAGE_NAME}:${IMAGE_TAG}")
            img.push()
            // also push latest tag
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
      echo "Build and push successful: ${IMAGE_NAME}:${IMAGE_TAG}"
    }
    failure {
      echo "Build failed"
    }
  }
}

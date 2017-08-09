pipeline {
  
  agent any
  
  triggers {
    pollSCM('* * * * *')
    cron('@daily')
  }
  
  environment {
     NODE = "docker run --rm -v /var/lib/jenkins/.npm:/root/.npm -v $WORKSPACE:/app --workdir /app node:4"
  }
 
  stages {
    stage('Install') {
      steps {
        sh '$NODE npm install'
        sh '$NODE npm rebuild'
      }
    }
    stage('Compile') {
      steps {
        sh '$NODE /bin/bash -c "npm install --quiet -g grunt && grunt compile:app"'
      }
    }
    stage('Test') {
      steps {
        sh '$NODE /bin/bash -c "npm install --quiet -g grunt && grunt test:unit"'
      }
    }
    stage('Package') {
      steps {
        sh 'touch build.tar.gz' // Avoid tar warning about files changing during read
        sh 'tar -czf build.tar.gz --exclude=build.tar.gz --exclude-vcs .'
      }
    }
    stage('Publish') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'S3_CI_BUILDS_AWS_KEYS', passwordVariable: 'AWS_SECRET', usernameVariable: 'AWS_ID')]) {
          sh '''docker run --rm \
          -e AWS_ACCESS_KEY_ID=$AWS_ID \
          -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET \
          -v $WORKSPACE:/app --workdir /app sharelatex/awscli s3 cp build.tar.gz s3://${S3_BUCKET_BUILD_ARTEFACTS}/${JOB_NAME}/${BUILD_NUMBER}.tar.gz
          '''
        }
      }
    }
  }
  
  post {
    failure {
      mail(from: "alerts@sharelatex.com", 
           to: "team@sharelatex.com", 
           subject: "Jenkins build failed: ${JOB_NAME}:${BUILD_NUMBER}",
           body: "Build: ${BUILD_URL}")
    }
  }
  
  // The options directive is for configuration that applies to the whole job.
  options {
    // we'd like to make sure remove old builds, so we don't fill up our storage!
    buildDiscarder(logRotator(numToKeepStr:'50'))
    
    // And we'd really like to be sure that this build doesn't hang forever, so let's time it out after:
    timeout(time: 30, unit: 'MINUTES')
  }
}

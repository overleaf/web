pipeline {
  
  agent any
  
  triggers {
    pollSCM('* * * * *')
    cron('@daily')
  }
  
  environment {
     NODE = "docker run --rm -u 111 -v /var/lib/jenkins/.npm:/.npm -v $WORKSPACE:/app --workdir /app node:6.9.5"
  }
 
  stages {
    stage('Clone Dependencies') {
      steps {
        sh 'rm -rf public/brand modules'
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'public/brand'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@github.com:sharelatex/brand-sharelatex']]])
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'app/views/external'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@github.com:sharelatex/external-pages-sharelatex']]])
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'modules'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@github.com:sharelatex/web-sharelatex-modules']]])
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'modules/admin-panel'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@github.com:sharelatex/admin-panel']]])
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'modules/groovehq'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@bitbucket.org:sharelatex/groovehq']]])
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'modules/references-search'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@bitbucket.org:sharelatex/references-search.git']]])
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'modules/tpr-webmodule'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@github.com:sharelatex/tpr-webmodule.git ']]])
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'modules/learn-wiki'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@bitbucket.org:sharelatex/learn-wiki-web-module.git']]])
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'modules/templates'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@github.com:sharelatex/templates-webmodule.git']]])
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'modules/track-changes'], [$class: 'CloneOption', shallow: true]], userRemoteConfigs: [[credentialsId: 'GIT_DEPLOY_KEY', url: 'git@github.com:sharelatex/track-changes-web-module.git']]])
        sh 'rm -rf node_modules/*'
      }
    }
    stage('Install') {
      steps {
        sh 'mv app/views/external/robots.txt public/robots.txt'
        sh 'mv app/views/external/googlebdb0f8f7f4a17241.html public/googlebdb0f8f7f4a17241.html'
        sh '$NODE npm install'
        sh '$NODE npm rebuild'
      }
    }
    stage('Compile') {
      steps {
        sh '$NODE /bin/bash -c "npm install --quiet -g grunt && grunt compile  --verbose"'
      }
    }
    stage('Smoke Test') {
      steps {
        sh '$NODE /bin/bash -c "npm install --quiet -g grunt && grunt compile:smoke_tests"'
      }
    }
    stage('Minify') {
      steps {
        sh '$NODE /bin/bash -c "npm install --quiet -g grunt && grunt compile:minify"'
      }
    }
    stage('Unit Test') {
      steps {
        sh '$NODE /bin/bash -c "npm install --quiet -g grunt && env NODE_ENV=development grunt test:unit --reporter=tap"'
      }
    }
    stage('Package') {
      steps {
        sh 'rm -rf ./node_modules/grunt*'
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
  
  //post {
  //  failure {
      //mail(from: "alerts@sharelatex.com", 
      //     to: "team@sharelatex.com", 
      //     subject: "Jenkins build failed: ${JOB_NAME}:${BUILD_NUMBER}",
      //     body: "Build: ${BUILD_URL}")
  //  }
  //}
  
  // The options directive is for configuration that applies to the whole job.
  options {
    // we'd like to make sure remove old builds, so we don't fill up our storage!
    buildDiscarder(logRotator(numToKeepStr:'50'))
    
    // And we'd really like to be sure that this build doesn't hang forever, so let's time it out after:
    timeout(time: 30, unit: 'MINUTES')
  }
}

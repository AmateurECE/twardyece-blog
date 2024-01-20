pipeline {
  agent any
  stages {
    stage('Build') {
      steps {
        checkout scm
        sh '''#!/usr/bin/flake-run
        bundle install
        bundle exec jekyll build
        '''
        sh "cp -a ${WORKSPACE}/_site/* ${HOME}/sitedata/blog/"
      }
    }
  }

  triggers {
    githubPush()
  }
}

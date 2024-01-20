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
        sh '''#!/bin/bash
        mkdir -p ${HOME}/sitedata/blog
        cp -a ${WORKSPACE}/_site/* ${HOME}/sitedata/blog/
        '''
      }
    }
  }

  triggers {
    githubPush()
  }
}

pipeline {
  agent any
  stages {
    stage('Build') {
      steps {
        checkout scm
        nix 'nix develop -v --command bash -c "bundle install && bundle exec jekyll build"'
        sh "cp -a ${WORKSPACE}/_site/* ${HOME}/blog/"
      }
    }
  }
}

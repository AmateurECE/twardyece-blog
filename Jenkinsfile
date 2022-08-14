node {
    stage('Build') {
        checkout scm
        sh '''#!/bin/bash -l
        bundle install
        bundle exec jekyll build --trace
        '''
        sh "cp -a ${WORKSPACE}/_site/* ${HOME}/blog/"
    }
}

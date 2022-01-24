node {
    stage('Build') {
        checkout scm
        sh '''#!/bin/bash -l
        bundle install --path ~/.local/gems
        bundle exec jekyll build
        '''
        sh "cp -a ${WORKSPACE}/_site/* ${HOME}/blog/"
    }
}

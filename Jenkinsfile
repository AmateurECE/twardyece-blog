node {
    stage('Build') {
        checkout scm
        sh '''#!/bin/bash -l
        bundle install
        GRAPHVIZ_DOT=/usr/bin/dot bundle exec jekyll build --trace
        '''
        sh "cp -a ${WORKSPACE}/_site/* ${HOME}/blog/"
    }
}

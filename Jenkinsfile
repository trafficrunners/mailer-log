pipeline {
    agent any

    environment {
        RAILS_ENV = 'test'
        BUNDLE_PATH = 'vendor/bundle'
        NODE_ENV = 'test'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        timestamps()
        ansiColor('xterm')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "Checked out commit: $(git rev-parse HEAD)"'
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Ruby') {
                    steps {
                        sh '''
                            set -ex
                            ruby --version
                            bundle --version
                            bundle config set --local path vendor/bundle
                            bundle install --jobs 4 --retry 3
                        '''
                    }
                }
                stage('Node') {
                    steps {
                        dir('frontend') {
                            sh '''
                                set -ex
                                node --version
                                npm --version
                                npm ci
                            '''
                        }
                    }
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    sh '''
                        set -ex
                        npm run build
                    '''
                }
            }
        }

        stage('Setup Database') {
            steps {
                dir('spec/dummy') {
                    sh '''
                        set -ex
                        bundle exec rake db:create db:migrate
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    set -ex
                    bundle exec rspec spec \
                        --format documentation \
                        --format RspecJunitFormatter \
                        --out tmp/rspec_results.xml
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'tmp/rspec_results.xml'
                }
            }
        }
    }

    post {
        success {
            echo 'Build successful!'
        }
        failure {
            echo 'Build failed!'
        }
        cleanup {
            deleteDir()
        }
    }
}

pipeline {
    agent {
        label 'ruby'
    }

    environment {
        RAILS_ENV = 'test'
        BUNDLE_PATH = 'vendor/bundle'
        NODE_ENV = 'test'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout mailer_log
                checkout scm

                // Checkout gmbmanager as sibling (required for running specs)
                dir('../gmbmanager') {
                    git branch: 'master',
                        credentialsId: 'github-credentials',
                        url: 'git@github.com:trafficrunners/gmbmanager.git'
                }
            }
        }

        stage('Setup Host App') {
            steps {
                dir('../gmbmanager') {
                    sh '''
                        bundle config set --local path vendor/bundle
                        bundle config set --local without 'development'
                        bundle install --jobs 4 --retry 3
                    '''

                    sh 'bundle exec rails db:test:prepare'
                }
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Ruby') {
                    steps {
                        sh '''
                            bundle config set --local path vendor/bundle
                            bundle install --jobs 4 --retry 3
                        '''
                    }
                }
                stage('Node') {
                    steps {
                        dir('frontend') {
                            sh 'npm ci'
                        }
                    }
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm run build'
                }
            }
        }

        stage('Run Tests') {
            steps {
                dir('../gmbmanager') {
                    sh '''
                        bundle exec rspec ../mailer_log/spec \
                            --format progress \
                            --format RspecJunitFormatter \
                            --out ../mailer_log/tmp/rspec_results.xml
                    '''
                }
            }
            post {
                always {
                    junit 'tmp/rspec_results.xml'
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
            cleanWs()
        }
    }
}

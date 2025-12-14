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
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
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

        stage('Setup Database') {
            steps {
                dir('spec/dummy') {
                    sh 'bundle exec rake db:create db:migrate'
                }
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    bundle exec rspec spec \
                        --format progress \
                        --format RspecJunitFormatter \
                        --out tmp/rspec_results.xml
                '''
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
            deleteDir()
        }
    }
}

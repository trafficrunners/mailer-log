pipeline {
    agent any

    environment {
        RAILS_ENV = 'test'
        BUNDLE_PATH = 'vendor/bundle'
        NODE_ENV = 'test'
        PATH = '/home/jenkins/.rbenv/shims:/home/jenkins/.rbenv/bin:/home/jenkins/.nvm/versions/node/v20.18.0/bin:/usr/local/bin:/usr/bin:/bin'
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
                echo "Workspace: ${env.WORKSPACE}"
                echo "Node: ${env.NODE_NAME}"
            }
        }

        stage('Environment Check') {
            steps {
                sh 'echo "=== Environment Check ==="'
                sh 'whoami'
                sh 'pwd'
                sh 'ruby --version'
                sh 'bundle --version'
                sh 'node --version'
                sh 'npm --version'
                sh 'git rev-parse --short HEAD'
                sh 'echo "========================="'
            }
        }

        stage('Install Ruby Dependencies') {
            steps {
                sh 'bundle config set --local path vendor/bundle'
                sh 'bundle install --jobs 4 --retry 3'
            }
        }

        stage('Install Node Dependencies') {
            steps {
                dir('frontend') {
                    sh 'npm ci'
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
                    sh 'bundle exec rake db:create db:migrate || bundle exec rake db:migrate'
                }
            }
        }

        stage('Run Tests') {
            steps {
                sh 'bundle exec rspec spec --format documentation --format RspecJunitFormatter --out tmp/rspec_results.xml'
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

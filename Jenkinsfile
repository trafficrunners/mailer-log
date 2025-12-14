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
                script {
                    echo "Workspace: ${env.WORKSPACE}"
                    echo "Node: ${env.NODE_NAME}"
                    echo "Commit: ${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
                }
            }
        }

        stage('Environment Check') {
            steps {
                sh '''#!/bin/bash
                    echo "=== Environment Check ==="
                    echo "User: $(whoami)"
                    echo "PWD: $(pwd)"
                    echo "Ruby: $(ruby --version 2>&1 || echo 'not found')"
                    echo "Bundle: $(bundle --version 2>&1 || echo 'not found')"
                    echo "Node: $(node --version 2>&1 || echo 'not found')"
                    echo "NPM: $(npm --version 2>&1 || echo 'not found')"
                    echo "========================="
                '''
            }
        }

        stage('Install Ruby Dependencies') {
            steps {
                sh '''#!/bin/bash
                    set -e
                    echo "Installing Ruby dependencies..."
                    bundle config set --local path vendor/bundle
                    bundle install --jobs 4 --retry 3
                    echo "Ruby dependencies installed."
                '''
            }
        }

        stage('Install Node Dependencies') {
            steps {
                dir('frontend') {
                    sh '''#!/bin/bash
                        set -e
                        echo "Installing Node dependencies..."
                        npm ci
                        echo "Node dependencies installed."
                    '''
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    sh '''#!/bin/bash
                        set -e
                        echo "Building frontend..."
                        npm run build
                        echo "Frontend built."
                    '''
                }
            }
        }

        stage('Setup Database') {
            steps {
                dir('spec/dummy') {
                    sh '''#!/bin/bash
                        set -e
                        echo "Setting up database..."
                        bundle exec rake db:create db:migrate || bundle exec rake db:migrate
                        echo "Database ready."
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                sh '''#!/bin/bash
                    set -e
                    echo "Running tests..."
                    bundle exec rspec spec \
                        --format documentation \
                        --format RspecJunitFormatter \
                        --out tmp/rspec_results.xml
                    echo "Tests completed."
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
            sh 'echo "Failed at stage: ${STAGE_NAME:-unknown}" || true'
        }
        cleanup {
            deleteDir()
        }
    }
}

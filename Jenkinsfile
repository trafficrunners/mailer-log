pipeline {
    agent { label 'agent-2' }

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
                echo "Workspace: ${env.WORKSPACE}"
                echo "Node: ${env.NODE_NAME}"
            }
        }

        stage('Environment Check') {
            steps {
                script {
                    def result = sh(script: 'echo "=== Environment Check ===" && whoami && pwd && ruby --version && bundle --version && node --version && npm --version && git rev-parse --short HEAD && echo "========================="', returnStatus: true)
                    echo "Environment check completed with status: ${result}"
                }
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

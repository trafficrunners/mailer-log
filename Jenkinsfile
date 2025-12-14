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
                echo "Workspace: ${env.WORKSPACE}"
                echo "Node: ${env.NODE_NAME}"
            }
        }

        stage('Environment Check') {
            steps {
                withEnv(['PATH=/usr/local/bin:/usr/bin:/bin']) {
                    sh 'echo "=== Finding tools ==="'
                    sh 'find /home/jenkins -name ruby -type f 2>/dev/null | head -5 || echo "ruby not found in /home/jenkins"'
                    sh 'find /usr -name ruby -type f 2>/dev/null | head -5 || echo "ruby not found in /usr"'
                    sh 'ls -la /home/jenkins/.rbenv/shims/ 2>/dev/null | head -10 || echo "rbenv shims not found"'
                    sh 'ls -la /var/lib/jenkins/.rbenv/shims/ 2>/dev/null | head -10 || echo "var rbenv shims not found"'
                    sh 'echo "RBENV_ROOT=$RBENV_ROOT"'
                    sh 'cat /etc/environment 2>/dev/null || echo "no /etc/environment"'
                    sh 'cat ~/.bashrc 2>/dev/null | grep -E "(rbenv|PATH)" | head -10 || echo "no rbenv in bashrc"'
                    sh 'echo "=== Current PATH: $PATH ==="'
                }
            }
        }

        stage('Install Ruby Dependencies') {
            steps {
                withEnv(['PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/usr/local/bin:/usr/bin:/bin:/usr/pgsql-12/bin']) {
                    sh 'bundle config set --local path vendor/bundle'
                    sh 'bundle install --jobs 4 --retry 3'
                }
            }
        }

        stage('Install Node Dependencies') {
            steps {
                withEnv(['PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/usr/local/bin:/usr/bin:/bin:/usr/pgsql-12/bin']) {
                    dir('frontend') {
                        sh 'npm ci'
                    }
                }
            }
        }

        stage('Build Frontend') {
            steps {
                withEnv(['PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/usr/local/bin:/usr/bin:/bin:/usr/pgsql-12/bin']) {
                    dir('frontend') {
                        sh 'npm run build'
                    }
                }
            }
        }

        stage('Setup Database') {
            steps {
                withEnv(['PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/usr/local/bin:/usr/bin:/bin:/usr/pgsql-12/bin']) {
                    dir('spec/dummy') {
                        sh 'bundle exec rake db:create db:migrate || bundle exec rake db:migrate'
                    }
                }
            }
        }

        stage('Run Tests') {
            steps {
                withEnv(['PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/usr/local/bin:/usr/bin:/bin:/usr/pgsql-12/bin']) {
                    sh 'bundle exec rspec spec --format documentation --format RspecJunitFormatter --out tmp/rspec_results.xml'
                }
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

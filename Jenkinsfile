// Recommended plugins: Pipeline, JDK Tool, NodeJS, JUnit, Credentials Binding, SSH Agent.

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    tools {
        jdk 'jdk-21'
        maven 'maven-3.9'
        nodejs 'node-20'
    }

    parameters {
        booleanParam(
            name: 'DEPLOY',
            defaultValue: false,
            description: 'Deploy to the EC2 host after a successful build (main branch only)'
        )
        string(name: 'AWS_REGION', defaultValue: 'us-east-1',
            description: 'AWS region that hosts the ECR repositories')
        string(name: 'ECR_REPOSITORY', defaultValue: 'taskmanager',
            description: 'ECR repository prefix for the backend and frontend images')
        string(name: 'EC2_HOST', defaultValue: '',
            description: 'Public DNS name or IP address of the target EC2 host')
        string(name: 'EC2_USER', defaultValue: 'ubuntu',
            description: 'SSH user on the EC2 host')
        string(name: 'APP_DIR', defaultValue: '/opt/taskmanager',
            description: 'Directory on the EC2 host that holds the Compose file and .env')
        booleanParam(
            name: 'USE_BUNDLED_DB',
            defaultValue: false,
            description: 'Run the bundled MySQL container on the host instead of pointing DB_URL at RDS'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git rev-parse --short HEAD'
            }
        }

        stage('Build & test') {
            parallel {
                stage('Backend — mvn verify') {
                    steps {
                        dir('backend') {
                            sh 'mvn -B -ntp verify'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true,
                                  testResults: 'backend/target/surefire-reports/*.xml'
                        }
                    }
                }

                stage('Frontend — npm build') {
                    steps {
                        dir('frontend') {
                            sh 'npm ci'
                            sh 'npm run build'
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'frontend/dist/**', allowEmptyArchive: true
                        }
                    }
                }
            }
        }

        stage('Build & push images to ECR') {
            when {
                beforeAgent true
                expression { return env.BRANCH_NAME == 'main' || env.GIT_BRANCH == 'origin/main' }
            }
            steps {
                sh '''
                    set -eu
                    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                    REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

                    # Create the repositories on first run, then cap stored images.
                    LIFECYCLE='{"rules":[{"rulePriority":1,"description":"Keep last 10 images","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":10},"action":{"type":"expire"}}]}'
                    for REPO in backend frontend; do
                        FULL="$ECR_REPOSITORY/$REPO"
                        if ! aws ecr describe-repositories --repository-names "$FULL" --region "$AWS_REGION" >/dev/null 2>&1; then
                            echo "Creating ECR repository $FULL"
                            aws ecr create-repository --repository-name "$FULL" --region "$AWS_REGION" \
                                --image-scanning-configuration scanOnPush=true >/dev/null
                        fi
                        aws ecr put-lifecycle-policy --repository-name "$FULL" --region "$AWS_REGION" \
                            --lifecycle-policy-text "$LIFECYCLE" >/dev/null
                    done

                    aws ecr get-login-password --region "$AWS_REGION" \
                        | docker login --username AWS --password-stdin "$REGISTRY"

                    docker build -t "$REGISTRY/$ECR_REPOSITORY/backend:$GIT_COMMIT"  ./backend
                    docker build -t "$REGISTRY/$ECR_REPOSITORY/frontend:$GIT_COMMIT" ./frontend

                    docker push "$REGISTRY/$ECR_REPOSITORY/backend:$GIT_COMMIT"
                    docker push "$REGISTRY/$ECR_REPOSITORY/frontend:$GIT_COMMIT"
                '''
            }
        }

        stage('Deploy to EC2') {
            when {
                beforeAgent true
                allOf {
                    expression { return env.BRANCH_NAME == 'main' || env.GIT_BRANCH == 'origin/main' }
                    expression { return params.DEPLOY }
                }
            }
            environment {
                // Bind these in Jenkins (Manage Jenkins > Credentials):
                DB_URL      = credentials('taskmanager-db-url')      // Secret text
                DB_USERNAME = credentials('taskmanager-db-username') // Secret text
                DB_PASSWORD = credentials('taskmanager-db-password') // Secret text
                JWT_SECRET  = credentials('taskmanager-jwt-secret')  // Secret text
            }
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                        set -eu
                        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                        REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
                        BACKEND_IMAGE="$REGISTRY/$ECR_REPOSITORY/backend:$GIT_COMMIT"
                        FRONTEND_IMAGE="$REGISTRY/$ECR_REPOSITORY/frontend:$GIT_COMMIT"

                        SSH_OPTS="-o StrictHostKeyChecking=accept-new"
                        REMOTE="$EC2_USER@$EC2_HOST"

                        ssh $SSH_OPTS "$REMOTE" "mkdir -p '$APP_DIR'"
                        scp $SSH_OPTS docker-compose.prod.yml "$REMOTE:$APP_DIR/docker-compose.yml"

                        if [ "${USE_BUNDLED_DB:-false}" = "true" ]; then
                            scp $SSH_OPTS docker-compose.db.yml "$REMOTE:$APP_DIR/docker-compose.db.yml"
                            COMPOSE_ARGS="-f docker-compose.yml -f docker-compose.db.yml"
                        else
                            COMPOSE_ARGS="-f docker-compose.yml"
                        fi

                        umask 077
                        {
                            printf 'BACKEND_IMAGE=%s\\n'  "$BACKEND_IMAGE"
                            printf 'FRONTEND_IMAGE=%s\\n' "$FRONTEND_IMAGE"
                            printf 'DB_URL=%s\\n'          "$DB_URL"
                            printf 'DB_USERNAME=%s\\n'     "$DB_USERNAME"
                            printf 'DB_PASSWORD=%s\\n'     "$DB_PASSWORD"
                            printf 'JWT_SECRET=%s\\n'      "$JWT_SECRET"
                        } > .env.deploy
                        scp $SSH_OPTS .env.deploy "$REMOTE:$APP_DIR/.env"
                        rm -f .env.deploy

                        ssh $SSH_OPTS "$REMOTE" "cd '$APP_DIR' \
                            && aws ecr get-login-password --region '$AWS_REGION' \
                               | docker login --username AWS --password-stdin '$REGISTRY' \
                            && docker compose $COMPOSE_ARGS pull \
                            && docker compose $COMPOSE_ARGS up -d --remove-orphans"
                    '''
                }
            }
        }
    }

    post {
        success { echo 'Pipeline completed successfully.' }
        failure { echo 'Pipeline failed — check the stage logs above.' }
    }
}

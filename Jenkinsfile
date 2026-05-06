pipeline {
    agent any

    environment {
        AWS_REGION     = 'eu-west-2'
        ECR_REPOSITORY = 'damolak-task'
        IMAGE_TAG      = "${env.BRANCH_NAME == 'prod' ? 'prod' : 'dev'}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                sh '''
                    pip install -r app/requirements.txt
                    python -m pytest app/test_app.py -v
                '''
            }
        }

        stage('Build & Push') {
            steps {
                withCredentials([[
                    $class:            'AmazonWebServicesCredentialsBinding',
                    credentialsId:     'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                        ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        ECR_IMAGE_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

                        aws ecr get-login-password --region $AWS_REGION \
                          | docker login --username AWS --password-stdin $ECR_REGISTRY

                        docker build -t $ECR_IMAGE_URI app/
                        docker push $ECR_IMAGE_URI

                        echo $ECR_IMAGE_URI > ecr_image_uri.txt
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([[
                    $class:            'AmazonWebServicesCredentialsBinding',
                    credentialsId:     'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        ECR_IMAGE_URI=$(cat ecr_image_uri.txt)
                        chmod +x scripts/deploy.sh
                        ./scripts/deploy.sh $IMAGE_TAG $ECR_IMAGE_URI $AWS_REGION
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            sh 'rm -f ecr_image_uri.txt'
        }
        success {
            echo "Pipeline succeeded: ${IMAGE_TAG} deployed."
        }
        failure {
            echo "Pipeline failed."
        }
    }
}

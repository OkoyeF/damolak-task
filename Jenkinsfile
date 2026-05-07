pipeline {
    agent any

    environment {
        AWS_REGION     = 'eu-west-2'
        ECR_REPOSITORY = 'damolak-task'
        IMAGE_TAG      = "${env.BRANCH_NAME == 'prod' ? 'prod' : 'dev'}"
    }

        stage('Test') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate

                     pip install --upgrade pip
                     pip install -r app/requirements-test.txt

                     python -m pytest app/test_app.py -v
                 '''
            }
        }

        stage('Build & Push') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',     variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

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
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',     variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

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


   

 

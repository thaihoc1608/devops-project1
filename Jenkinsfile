pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'React-App'
    }

    stages {
        stage('Checkout') {
            steps {
                // Keo code tu Github ve
                checkout scm 
            }
        }

        stage('Build Docker Image') {           
            steps {
                echo "Đang đóng gói ứng dụng vào Docker Image..."
                sh "docker build -t ${DOCKER_IMAGE}:latest ."
            }
        }

        stage('Deploy to Container') {
            steps {
                echo "Đang triển khai ứng dụng lên container..."
                sh "docker stop ${DOCKER_IMAGE} || true"
                sh "docker rm ${DOCKER_IMAGE} || true"

                // Chạy container mới trên cổng 8081 (vì 8080 Jenkins dùng rồi)
                sh "docker run -d --name ${DOCKER_IMAGE} -p 8081:80 ${DOCKER_IMAGE}:latest"
                echo "Web đã online tại http://localhost:8081"
            }
        }
    }
}
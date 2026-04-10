pipeline {
    agent any

    environment {
        // Biến tĩnh thì vẫn để ở đây được
        IMAGE_NAME = "devops-web-app"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Khởi tạo Biến Môi trường') {
            steps {
                script {
                    // FIX #1: Kiểm tra chuỗi rỗng đúng cách trong Groovy
                    // docker ps chỉ in ra container ĐANG CHẠY
                    def blueExists = sh(script: "docker ps --filter name=${IMAGE_NAME}-blue --format '{{.Names}}'", returnStdout: true).trim()

                    // Groovy: chuỗi rỗng "" là falsy khi dùng toBoolean() or .isEmpty()
                    env.ACTIVE_ENV = blueExists.isEmpty() ? "green" : "blue"
                    env.TARGET_ENV = env.ACTIVE_ENV == "blue" ? "green" : "blue"

                    // Mapping cố định: blue=3001, green=3002
                    env.TARGET_PORT = env.TARGET_ENV == "blue" ? "3001" : "3002"
                    env.ACTIVE_PORT = env.ACTIVE_ENV == "blue" ? "3001" : "3002"

                    echo "🎯 Phát hiện nhà đang chạy: ${env.ACTIVE_ENV} (cổng ${env.ACTIVE_PORT})"
                    echo "🚀 Sẽ deploy code mới vào nhà: ${env.TARGET_ENV} ở cổng ${env.TARGET_PORT}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Đang đóng gói ứng dụng phiên bản mới..."
                sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
            }
        }

        stage('Deploy to Inactive Environment') {
            steps {
                echo "🔥 Triển khai vào nhà rảnh rỗi: ${env.TARGET_ENV} (Cổng ${env.TARGET_PORT})"
                sh "docker stop ${IMAGE_NAME}-${env.TARGET_ENV} || true"
                sh "docker rm ${IMAGE_NAME}-${env.TARGET_ENV} || true"
                sh "docker run -d --name ${IMAGE_NAME}-${env.TARGET_ENV} -p ${env.TARGET_PORT}:80 ${IMAGE_NAME}:${BUILD_NUMBER}"
            }
        }

        stage('Smoke Test (Kiểm định chất lượng)') {
            steps {
                echo "Đợi 10 giây để web khởi động..."
                sleep 10
                echo "Tiến hành gửi request kiểm tra nhà ${env.TARGET_ENV}..."
                // Jenkins chạy trong Docker container trên Windows
                // Phải dùng host.docker.internal để reach port trên host machine
                // localhost bên trong Jenkins container ≠ localhost của host
                sh "curl -f --retry 5 --retry-delay 5 --retry-connrefused http://host.docker.internal:${env.TARGET_PORT} || exit 1"
            }
        }

        stage('Switch Traffic (Bẻ lái giao thông)') {
            steps {
                echo "✅ Kiểm định thành công! Đang bẻ lái Nginx sang nhà ${env.TARGET_ENV}..."
                // FIX #3: Dùng heredoc thay vì echo một dòng dài để tránh lỗi escape ký tự
                sh """
                cat <<'EOF' > /tmp/nginx.conf
events {
    worker_connections 1024;
}
http {
    upstream frontend {
        server host.docker.internal:${env.TARGET_PORT};
    }
    server {
        listen 80;
        location / {
            proxy_pass http://frontend;
        }
    }
}
EOF

                docker cp /tmp/nginx.conf router-nginx:/etc/nginx/nginx.conf
                docker exec router-nginx nginx -s reload
                """
            }
        }
    }

    // NÚT ROLLBACK TỰ ĐỘNG
    post {
        failure {
            echo "🚨 BÁO ĐỘNG: Có lỗi xảy ra trong quá trình Deploy hoặc Test!"
            echo "🛡️ HỆ THỐNG ROLLBACK: Dừng nhà ${env.TARGET_ENV} lỗi. Khách hàng vẫn đang an toàn ở nhà ${env.ACTIVE_ENV}."
            sh "docker stop ${IMAGE_NAME}-${env.TARGET_ENV} || true"
            sh "docker rm ${IMAGE_NAME}-${env.TARGET_ENV} || true"
        }
        success {
            echo "🎉 Hoàn tất! Đang dọn dẹp nhà ${env.ACTIVE_ENV} cũ để tiết kiệm tài nguyên."
            sh "docker stop ${IMAGE_NAME}-${env.ACTIVE_ENV} || true"
            sh "docker rm ${IMAGE_NAME}-${env.ACTIVE_ENV} || true"
        }
    }
}
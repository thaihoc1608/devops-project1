pipeline {
    agent any

    environment {
        IMAGE_NAME = 'devops-web-app'

        // dung lenh docker ps de kiem tra xem container blue co dang chay hay khong 
        ACTIVE_ENV = sh(script: "docker ps | grep ${IMAGE_NAME}-blue || true", returnStdout: true).trim() ? "blue" : "green"

        //Neu blue dang chay thi se deploy green va nguoc lai
        TARGET_ENV = ACTIVE_ENV == "blue" ? "green" : "blue"
        TARGET_POT = TARGET_ENV == "blue" ? "3001" : "3002"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Dang dong goi ung dung phien ban moi"
                    sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
                }
            }
        }
        
        stage('Deploy to inactive Environment') {
            steps {
                echo "🔥 Triển khai vào nhà rảnh rỗi: ${TARGET_ENV} (Cổng ${TARGET_PORT})"
                // Dọn dẹp nhà mục tiêu cho sạch sẽ trước khi dọn vào
                sh "docker stop ${IMAGE_NAME}-${TARGET_ENV} || true"
                sh "docker rm ${IMAGE_NAME}-${TARGET_ENV} || true"
                
                // Khởi chạy thùng Docker mới
                sh "docker run -d --name ${IMAGE_NAME}-${TARGET_ENV} -p ${TARGET_PORT}:80 ${IMAGE_NAME}:${BUILD_NUMBER}"
            }
        }

        stage('Smoke Test (Kiểm định chất lượng)') {
            steps {
                echo "Đợi 5 giây để web khởi động..."
                sleep 5
                echo "Tiến hành gửi request kiểm tra nhà ${TARGET_ENV}..."
                // Lệnh curl này sẽ thử truy cập web. Nếu web lỗi, nó sẽ đánh sập Pipeline ngay tại đây!
                sh "curl -f http://host.docker.internal:${TARGET_PORT} || exit 1"
            }
        }

        stage('Switch Traffic') {
            steps {
                echo "✅ Kiểm định thành công! Đang bẻ lái Nginx sang nhà ${TARGET_ENV}..."
                // Tạo file cấu hình Nginx mới trỏ vào cổng của nhà vừa deploy
                sh """
                echo 'events { worker_connections 1024; } http { upstream frontend { server host.docker.internal:${TARGET_PORT}; } server { listen 80; location / { proxy_pass http://frontend; } } }' > /tmp/nginx.conf
                
                # Copy file mới vào cho bác bảo vệ
                docker cp /tmp/nginx.conf router-nginx:/etc/nginx/nginx.conf
                
                # Yêu cầu bác bảo vệ đọc lại sổ tay mà KHÔNG cần khởi động lại
                docker exec router-nginx nginx -s reload
                """
            }
        }
    }

    // NÚT ROLLBACK & DỌN DẸP TỰ ĐỘNG
    post {
        failure {
            echo "🚨 BÁO ĐỘNG: Có lỗi xảy ra trong quá trình Deploy hoặc Test!"
            echo "🛡️ HỆ THỐNG ROLLBACK: Dừng nhà ${TARGET_ENV} lỗi. Khách hàng vẫn đang an toàn ở nhà ${ACTIVE_ENV}."
            sh "docker stop ${IMAGE_NAME}-${TARGET_ENV} || true"
            sh "docker rm ${IMAGE_NAME}-${TARGET_ENV} || true"
        }
        success {
            echo "🎉 Hoàn tất! Đang dọn dẹp nhà ${ACTIVE_ENV} cũ để tiết kiệm tài nguyên."
            // Tùy chọn: Ông chủ có thể bỏ 2 dòng dưới nếu muốn giữ lại nhà cũ để dự phòng
            sh "docker stop ${IMAGE_NAME}-${ACTIVE_ENV} || true"
            sh "docker rm ${IMAGE_NAME}-${ACTIVE_ENV} || true"
        }
    }
}
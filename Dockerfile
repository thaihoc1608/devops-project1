#bước 1: build ứng dụng React
FROM node:18-alpine as build
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

#bước 2: Dùng Nginx để phục vụ file tĩnh sau khi build
FROM nginx:stable-alpine

# Copy kết quả build từ bước 1 vào thư mục mặc định của Nginx
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
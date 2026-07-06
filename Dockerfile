# Bước 1: Build ứng dụng bằng Maven với Java 21
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy toàn bộ code từ thư mục con attendance vào trong Docker
COPY ./attendance .

# Tiến hành đóng gói (Compile và tạo file .jar)
RUN mvn clean package -DskipTests

# Bước 2: Tạo môi trường chạy với JRE Java 21 gọn nhẹ
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# SỬA DÒNG NÀY: Chỉ định đích danh file jar dựa theo pom.xml của bạn
COPY --from=build /app/target/attendance-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
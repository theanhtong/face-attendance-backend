# Bước 1: Build ứng dụng bằng Maven với Java 21
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy toàn bộ code từ thư mục con attendance vào trong Docker
COPY ./attendance ./attendance

# Di chuyển hẳn vào thư mục chứa pom.xml để build
WORKDIR /app/attendance
RUN mvn clean package -DskipTests

# Bước 2: Tạo môi trường chạy với JRE Java 21 gọn nhẹ
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Copy file jar từ bước build sang (đường dẫn chuẩn sau khi thay đổi WORKDIR ở trên)
COPY --from=build /app/attendance/target/attendance-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
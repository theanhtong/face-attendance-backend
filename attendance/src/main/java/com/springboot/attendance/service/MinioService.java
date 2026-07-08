package com.springboot.attendance.service;

import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.Base64;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class MinioService {

    private final MinioClient minioClient;

    @Value("${minio.bucket-name}")
    private String bucketName;

    /**
     * Uploads a base64 encoded image to MinIO.
     * @return The object key/path in MinIO.
     */
    public String uploadFaceImage(UUID studentId, UUID embeddingId, String base64Image) {
        try {
            // 1. Ensure bucket exists
            boolean found = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucketName).build());
            if (!found) {
                minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucketName).build());
                log.info("Created MinIO bucket: {}", bucketName);
            }

            // 2. Decode base64 and parse metadata
            String base64Data = base64Image;
            String contentType = "image/jpeg";
            String extension = ".jpg";

            if (base64Image.contains(",")) {
                String[] parts = base64Image.split(",");
                String header = parts[0];
                base64Data = parts[1];
                if (header.contains("image/png")) {
                    contentType = "image/png";
                    extension = ".png";
                } else if (header.contains("image/webp")) {
                    contentType = "image/webp";
                    extension = ".webp";
                } else if (header.contains("image/gif")) {
                    contentType = "image/gif";
                    extension = ".gif";
                }
            }

            byte[] decodedBytes = Base64.getDecoder().decode(base64Data.trim());

            // 3. Define path: students/{studentId}/{embeddingId}{extension}
            String objectName = String.format("students/%s/%s%s", studentId, embeddingId, extension);

            // 4. Upload to MinIO
            try (InputStream inputStream = new ByteArrayInputStream(decodedBytes)) {
                minioClient.putObject(
                        PutObjectArgs.builder()
                                .bucket(bucketName)
                                .object(objectName)
                                .stream(inputStream, decodedBytes.length, -1)
                                .contentType(contentType)
                                .build()
                );
            }

            log.info("Uploaded face image to MinIO successfully: {}", objectName);
            return objectName;
        } catch (Exception e) {
            log.error("Failed to upload image to MinIO for student: {}, embedding: {}", studentId, embeddingId, e);
            throw new RuntimeException("MinIO upload failed: " + e.getMessage(), e);
        }
    }

    /**
     * Downloads file content from MinIO as bytes.
     */
    public byte[] downloadFaceImage(String objectKey) {
        try (InputStream stream = minioClient.getObject(
                GetObjectArgs.builder()
                        .bucket(bucketName)
                        .object(objectKey)
                        .build())) {
            return stream.readAllBytes();
        } catch (Exception e) {
            log.error("Failed to download image from MinIO for key: {}", objectKey, e);
            throw new RuntimeException("MinIO download failed: " + e.getMessage(), e);
        }
    }
}

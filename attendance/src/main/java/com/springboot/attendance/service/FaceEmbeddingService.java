package com.springboot.attendance.service;

import com.springboot.attendance.dto.request.FaceEmbeddingRequest;
import com.springboot.attendance.dto.response.FaceEmbeddingResponse;
import com.springboot.attendance.entity.FaceEmbedding;
import com.springboot.attendance.entity.ModelName;
import com.springboot.attendance.repository.FaceEmbeddingRepository;
import com.springboot.attendance.repository.StudentRepository;
import com.springboot.attendance.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FaceEmbeddingService {

    private final FaceEmbeddingRepository embeddingRepository;
    private final StudentRepository studentRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public FaceEmbeddingResponse getByStudent(UUID studentId) {
        return toResponse(embeddingRepository.findByStudentIdAndIsValidTrue(studentId)
                .orElseThrow(() -> new EntityNotFoundException("No active embedding for student: " + studentId)));
    }

    @Transactional
    public FaceEmbeddingResponse save(FaceEmbeddingRequest req, UUID createdById) {
        var student = studentRepository.findById(req.getStudentId())
                .orElseThrow(() -> new EntityNotFoundException("Student not found"));

        var createdBy = userRepository.findById(createdById)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        // Invalidate existing embedding nếu có
        embeddingRepository.findByStudentIdAndIsValidTrue(req.getStudentId())
                .ifPresent(e -> {
                    e.setValid(false);
                    embeddingRepository.save(e);
                });

        ModelName modelName;
        try {
            modelName = ModelName.valueOf(req.getModelName());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid model name: " + req.getModelName());
        }

        return toResponse(embeddingRepository.save(FaceEmbedding.builder()
                .student(student)
                .embedding(req.getEmbedding())
                .modelName(modelName)
                .embeddingDim(req.getEmbeddingDim())
                .createdBy(createdBy)
                .build()));
    }

    @Transactional
    public void invalidate(UUID studentId) {
        embeddingRepository.findByStudentIdAndIsValidTrue(studentId)
                .ifPresent(e -> {
                    e.setValid(false);
                    embeddingRepository.save(e);
                });
    }

    private FaceEmbeddingResponse toResponse(FaceEmbedding e) {
        return FaceEmbeddingResponse.builder()
                .id(e.getId())
                .studentId(e.getStudent().getId())
                .researchId(e.getStudent().getResearchId())
                .fullName(e.getStudent().getFullName())
                .modelName(e.getModelName().name())
                .embeddingDim(e.getEmbeddingDim())
                .isValid(e.isValid())
                .createdById(e.getCreatedBy().getId())
                .createdByName(e.getCreatedBy().getFullName())
                .createdAt(e.getCreatedAt())
                .updatedAt(e.getUpdatedAt())
                .build();
    }
}
package com.springboot.attendance.service;

import com.springboot.attendance.dto.request.StudentRequest;
import com.springboot.attendance.dto.response.StudentResponse;
import com.springboot.attendance.entity.Student;
import com.springboot.attendance.repository.StudentRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository studentRepository;

    @Transactional(readOnly = true)
    public List<StudentResponse> getAll() {
        return studentRepository.findAll().stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public StudentResponse getById(UUID id) {
        return toResponse(findOrThrow(id));
    }

    @Transactional(readOnly = true)
    public StudentResponse getByResearchId(String researchId) {
        return toResponse(studentRepository.findByResearchId(researchId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found: " + researchId)));
    }

    @Transactional
    public StudentResponse create(StudentRequest req) {
        if (studentRepository.existsByResearchId(req.getResearchId()))
            throw new IllegalArgumentException("Research ID already exists: " + req.getResearchId());

        return toResponse(studentRepository.save(Student.builder()
                .researchId(req.getResearchId())
                .build()));
    }

    @Transactional
    public StudentResponse update(UUID id, StudentRequest req) {
        var entity = findOrThrow(id);
        entity.setResearchId(req.getResearchId());
        return toResponse(studentRepository.save(entity));
    }

    @Transactional
    public void deactivate(UUID id) {
        var entity = findOrThrow(id);
        entity.setActive(false);
        studentRepository.save(entity);
    }

    private Student findOrThrow(UUID id) {
        return studentRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Student not found: " + id));
    }

    private StudentResponse toResponse(Student s) {
        return StudentResponse.builder()
                .id(s.getId())
                .researchId(s.getResearchId())
                .isActive(s.isActive())
                .enrolledAt(s.getEnrolledAt())
                .build();
    }
}
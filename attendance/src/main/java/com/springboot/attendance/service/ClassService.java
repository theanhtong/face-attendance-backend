package com.springboot.attendance.service;

import com.springboot.attendance.dto.request.ClassRequest;
import com.springboot.attendance.dto.response.ClassResponse;
import com.springboot.attendance.entity.Class;
import com.springboot.attendance.repository.ClassRepository;
import com.springboot.attendance.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ClassService {

    private final ClassRepository classRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<ClassResponse> getAll() {
        return classRepository.findAll().stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public ClassResponse getById(UUID id) {
        return toResponse(findOrThrow(id));
    }

    @Transactional(readOnly = true)
    public List<ClassResponse> getByLecturer(UUID lecturerId) {
        return classRepository.findByLecturerId(lecturerId).stream().map(this::toResponse).toList();
    }

    @Transactional
    public ClassResponse create(ClassRequest req) {
        if (classRepository.existsByClassCode(req.getClassCode()))
            throw new IllegalArgumentException("Class code already exists: " + req.getClassCode());

        var lecturer = userRepository.findById(req.getLecturerId())
                .orElseThrow(() -> new EntityNotFoundException("Lecturer not found"));

        var entity = Class.builder()
                .classCode(req.getClassCode())
                .subjectName(req.getSubjectName())
                .lecturer(lecturer)
                .academicYear(req.getAcademicYear())
                .term(req.getTerm())
                .build();

        return toResponse(classRepository.save(entity));
    }

    @Transactional
    public ClassResponse update(UUID id, ClassRequest req) {
        var entity = findOrThrow(id);
        var lecturer = userRepository.findById(req.getLecturerId())
                .orElseThrow(() -> new EntityNotFoundException("Lecturer not found"));

        entity.setClassCode(req.getClassCode());
        entity.setSubjectName(req.getSubjectName());
        entity.setLecturer(lecturer);
        entity.setAcademicYear(req.getAcademicYear());
        entity.setTerm(req.getTerm());

        return toResponse(classRepository.save(entity));
    }

    @Transactional
    public void deactivate(UUID id) {
        var entity = findOrThrow(id);
        entity.setActive(false);
        classRepository.save(entity);
    }

    private Class findOrThrow(UUID id) {
        return classRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Class not found: " + id));
    }

    private ClassResponse toResponse(Class c) {
        return ClassResponse.builder()
                .id(c.getId())
                .classCode(c.getClassCode())
                .subjectName(c.getSubjectName())
                .lecturerId(c.getLecturer().getId())
                .lecturerName(c.getLecturer().getFullName())
                .academicYear(c.getAcademicYear())
                .term(c.getTerm())
                .isActive(c.isActive())
                .createdAt(c.getCreatedAt())
                .build();
    }
}
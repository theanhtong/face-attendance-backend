package com.springboot.attendance.repository;

import com.springboot.attendance.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface StudentRepository extends JpaRepository<Student, UUID> {
    Optional<Student> findByResearchId(String researchId);
    boolean existsByResearchId(String researchId);
}
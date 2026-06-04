package com.springboot.attendance.repository;

import com.springboot.attendance.entity.Class;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ClassRepository extends JpaRepository<Class, UUID> {
    Optional<Class> findByClassCode(String classCode);
    List<Class> findByLecturerId(UUID lecturerId);
    List<Class> findByIsActiveTrue();
    boolean existsByClassCode(String classCode);
}
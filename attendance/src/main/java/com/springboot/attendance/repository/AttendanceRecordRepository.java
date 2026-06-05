package com.springboot.attendance.repository;

import com.springboot.attendance.entity.AttendanceRecord;
import com.springboot.attendance.entity.AttendanceStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AttendanceRecordRepository extends JpaRepository<AttendanceRecord, UUID> {
    Page<AttendanceRecord> findBySessionId(UUID sessionId, Pageable pageable);
    Page<AttendanceRecord> findByStudentId(UUID studentId, Pageable pageable);
    Optional<AttendanceRecord> findBySessionIdAndStudentId(UUID sessionId, UUID studentId);
    List<AttendanceRecord> findBySessionIdAndStatus(UUID sessionId, AttendanceStatus status);
}
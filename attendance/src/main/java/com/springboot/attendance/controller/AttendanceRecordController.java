package com.springboot.attendance.controller;

import com.springboot.attendance.dto.request.AttendanceOverrideRequest;
import com.springboot.attendance.dto.request.AttendanceRecordRequest;
import com.springboot.attendance.dto.response.AttendanceRecordResponse;
import com.springboot.attendance.service.AttendanceRecordService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/attendance")
@RequiredArgsConstructor
public class AttendanceRecordController {

    private final AttendanceRecordService attendanceService;

    @GetMapping("/session/{sessionId}")
    public ResponseEntity<List<AttendanceRecordResponse>> getBySession(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(attendanceService.getBySession(sessionId));
    }

    @GetMapping("/student/{studentId}")
    public ResponseEntity<List<AttendanceRecordResponse>> getByStudent(@PathVariable UUID studentId) {
        return ResponseEntity.ok(attendanceService.getByStudent(studentId));
    }

    @GetMapping("/{attendanceId}")
    public ResponseEntity<AttendanceRecordResponse> getById(@PathVariable UUID attendanceId) {
        return ResponseEntity.ok(attendanceService.getById(attendanceId));
    }

    @PostMapping("/mark")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<AttendanceRecordResponse> markPresent(
            @Valid @RequestBody AttendanceRecordRequest req) {
        return ResponseEntity.ok(attendanceService.markPresent(req));
    }

    @PatchMapping("/{attendanceId}/override")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<AttendanceRecordResponse> override(
            @PathVariable UUID attendanceId,
            @Valid @RequestBody AttendanceOverrideRequest req,
            @AuthenticationPrincipal UUID userId) {
        return ResponseEntity.ok(attendanceService.override(attendanceId, req, userId));
    }
}
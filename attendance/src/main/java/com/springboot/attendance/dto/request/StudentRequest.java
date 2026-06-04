package com.springboot.attendance.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class StudentRequest {
    @NotBlank
    @Size(max = 20)
    private String researchId;
}
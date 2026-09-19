package com.taskmanager.dto;

public record AuthResponse(
        String token,
        String tokenType,
        Long userId,
        String fullName,
        String email
) {
    public AuthResponse {
        tokenType = "Bearer";
    }
}
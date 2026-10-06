package com.pcfiletransfer.server.dto;

public record FileDto(
        String id,
        String name,
        long size,
        String contentType,
        long lastModified
) {
}

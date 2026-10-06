package com.pcfiletransfer.server.dto;

public record UploadSessionDto(
        String uploadId,
        long receivedBytes,
        long totalBytes,
        boolean complete
) {
}

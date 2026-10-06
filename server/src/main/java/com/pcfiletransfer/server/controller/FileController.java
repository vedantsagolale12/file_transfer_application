package com.pcfiletransfer.server.controller;

import com.pcfiletransfer.server.dto.FileDto;
import com.pcfiletransfer.server.dto.UploadSessionDto;
import com.pcfiletransfer.server.service.FileService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/api/v1")
public class FileController {
    private final FileService service;

    public FileController(FileService service) {
        this.service = service;
    }

    @GetMapping("/files")
    public List<FileDto> list() throws IOException {
        return service.list();
    }

    // Get metadata for one file.
    @GetMapping("/files/{id}")
    public FileDto metadata(
            @PathVariable String id
    ) throws IOException {
        return service.metadata(id);
    }

    /**
     * Download a file.
     *
     * Range handling (206 Partial Content, 416 Range Not Satisfiable,
     * Content-Range, Content-Length) is done by Spring MVC automatically
     * when a GET returns a Resource, so no manual parsing is needed.
     */
    @GetMapping("/files/{id}/download")
    public ResponseEntity<Resource> download(
            @PathVariable String id
    ) throws IOException {

        Resource resource = service.resource(id);

        HttpHeaders headers = new HttpHeaders();

        // UTF-8 aware: emits filename*= for non-ASCII names.
        headers.setContentDisposition(
                ContentDisposition.attachment()
                        .filename(
                                resource.getFilename(),
                                StandardCharsets.UTF_8
                        )
                        .build()
        );

        headers.set(HttpHeaders.ACCEPT_RANGES, "bytes");

        return ResponseEntity.ok()
                .headers(headers)
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(resource);
    }

    // Upload a complete file.
    @PostMapping(
            value = "/files/upload",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public FileDto upload(
            @RequestParam("file") MultipartFile file
    ) throws IOException {
        return service.upload(file);
    }

    // Start a resumable upload.
    @PostMapping("/uploads")
    public UploadSessionDto start(
            @RequestParam String filename,
            @RequestParam long totalBytes
    ) throws IOException {
        return service.startUpload(
                filename,
                totalBytes
        );
    }

    // Upload a chunk.
    @PutMapping(
            value = "/uploads/{uploadId}",
            consumes = MediaType.APPLICATION_OCTET_STREAM_VALUE
    )
    public UploadSessionDto chunk(
            @PathVariable String uploadId,
            @RequestHeader("Upload-Offset") long offset,
            HttpServletRequest request
    ) throws IOException {
        return service.appendChunk(
                uploadId,
                offset,
                request.getInputStream()
        );
    }

    // Check resumable upload progress.
    @GetMapping("/uploads/{uploadId}")
    public UploadSessionDto status(
            @PathVariable String uploadId
    ) throws IOException {
        return service.uploadStatus(uploadId);
    }

    // Cancel an upload.
    @DeleteMapping("/uploads/{uploadId}")
    public ResponseEntity<Void> cancel(
            @PathVariable String uploadId
    ) throws IOException {
        service.cancelUpload(uploadId);

        return ResponseEntity.noContent().build();
    }

    // Delete a stored file.
    @DeleteMapping("/files/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable String id
    ) throws IOException {
        service.delete(id);

        return ResponseEntity.noContent().build();
    }
}
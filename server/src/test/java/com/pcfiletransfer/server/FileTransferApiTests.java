package com.pcfiletransfer.server;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class FileTransferApiTests {

    @TempDir
    static Path tempDir;

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("file-transfer.storage.location", () -> tempDir.toAbsolutePath().toString());
        registry.add("file-transfer.rate-limit.requests-per-minute", () -> "1000");
    }

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static String uploadedFileId;

    @Test
    @Order(1)
    void testHealthEndpoint() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.service").value("PC File Transfer Server"))
                .andExpect(jsonPath("$.addresses").isArray());
    }

    @Test
    @Order(2)
    void testListFiles_initiallyEmpty() throws Exception {
        mockMvc.perform(get("/api/v1/files"))
                .andExpect(status().isOk())
                .andExpect(content().json("[]"));
    }

    @Test
    @Order(3)
    void testUploadMultipartFile_success() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-document.txt",
                MediaType.TEXT_PLAIN_VALUE,
                "Hello, world! This is a test file for transfer.".getBytes(StandardCharsets.UTF_8)
        );

        MvcResult result = mockMvc.perform(multipart("/api/v1/files/upload").file(file))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("test-document.txt"))
                .andExpect(jsonPath("$.size").value(47))
                .andExpect(jsonPath("$.id").isString())
                .andReturn();

        JsonNode jsonNode = objectMapper.readTree(result.getResponse().getContentAsString());
        uploadedFileId = jsonNode.get("id").asText();
        assertThat(uploadedFileId).isNotBlank();
    }

    @Test
    @Order(4)
    void testUploadMultipartFile_emptyFile_returnsBadRequest() throws Exception {
        MockMultipartFile emptyFile = new MockMultipartFile(
                "file",
                "empty.txt",
                MediaType.TEXT_PLAIN_VALUE,
                new byte[0]
        );

        mockMvc.perform(multipart("/api/v1/files/upload").file(emptyFile))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Bad Request"))
                .andExpect(jsonPath("$.message").value("Empty files are not accepted"));
    }

    @Test
    @Order(5)
    void testGetFileMetadata_success() throws Exception {
        mockMvc.perform(get("/api/v1/files/" + uploadedFileId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(uploadedFileId))
                .andExpect(jsonPath("$.name").value("test-document.txt"))
                .andExpect(jsonPath("$.size").value(47));
    }

    @Test
    @Order(6)
    void testGetFileMetadata_notFound() throws Exception {
        String nonExistentId = Base64.getUrlEncoder().withoutPadding()
                .encodeToString("non-existent-file.txt".getBytes(StandardCharsets.UTF_8));

        mockMvc.perform(get("/api/v1/files/" + nonExistentId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Not Found"))
                .andExpect(jsonPath("$.message").value("File not found"));
    }

    @Test
    @Order(7)
    void testGetFileMetadata_invalidId_badRequest() throws Exception {
        mockMvc.perform(get("/api/v1/files/invalid!!base64=="))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Bad Request"))
                .andExpect(jsonPath("$.message").value("Invalid file ID"));
    }

    @Test
    @Order(8)
    void testDownloadFile_fullContent() throws Exception {
        mockMvc.perform(get("/api/v1/files/" + uploadedFileId + "/download"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCEPT_RANGES, "bytes"))
                .andExpect(header().string(HttpHeaders.CONTENT_DISPOSITION, org.hamcrest.Matchers.containsString("test-document.txt")))
                .andExpect(content().string("Hello, world! This is a test file for transfer."));
    }

    @Test
    @Order(9)
    void testDownloadFile_rangeRequest() throws Exception {
        mockMvc.perform(get("/api/v1/files/" + uploadedFileId + "/download")
                        .header(HttpHeaders.RANGE, "bytes=0-4"))
                .andExpect(status().isPartialContent())
                .andExpect(header().string(HttpHeaders.CONTENT_RANGE, "bytes 0-4/47"))
                .andExpect(content().string("Hello"));
    }

    @Test
    @Order(10)
    void testListFiles_afterUpload() throws Exception {
        mockMvc.perform(get("/api/v1/files"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].name").value("test-document.txt"));
    }

    @Test
    @Order(11)
    void testResumableUpload_fullLifecycle() throws Exception {
        byte[] chunk1 = "Part1-".getBytes(StandardCharsets.UTF_8);
        byte[] chunk2 = "Part2-".getBytes(StandardCharsets.UTF_8);
        byte[] chunk3 = "Part3".getBytes(StandardCharsets.UTF_8);
        long totalBytes = chunk1.length + chunk2.length + chunk3.length;

        // 1. Start upload session
        MvcResult startResult = mockMvc.perform(post("/api/v1/uploads")
                        .param("filename", "resumable.dat")
                        .param("totalBytes", String.valueOf(totalBytes)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.uploadId").isString())
                .andExpect(jsonPath("$.receivedBytes").value(0))
                .andExpect(jsonPath("$.totalBytes").value(totalBytes))
                .andExpect(jsonPath("$.complete").value(false))
                .andReturn();

        JsonNode startJson = objectMapper.readTree(startResult.getResponse().getContentAsString());
        String uploadId = startJson.get("uploadId").asText();

        // 2. Check initial status
        mockMvc.perform(get("/api/v1/uploads/" + uploadId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.uploadId").value(uploadId))
                .andExpect(jsonPath("$.receivedBytes").value(0))
                .andExpect(jsonPath("$.complete").value(false));

        // 3. Upload chunk 1 (offset 0)
        mockMvc.perform(put("/api/v1/uploads/" + uploadId)
                        .contentType(MediaType.APPLICATION_OCTET_STREAM)
                        .header("Upload-Offset", 0)
                        .content(chunk1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.receivedBytes").value(chunk1.length))
                .andExpect(jsonPath("$.complete").value(false));

        // 4. Test conflict on bad offset (try offset 0 again)
        mockMvc.perform(put("/api/v1/uploads/" + uploadId)
                        .contentType(MediaType.APPLICATION_OCTET_STREAM)
                        .header("Upload-Offset", 0)
                        .content(chunk2))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message", org.hamcrest.Matchers.containsString("Offset mismatch")));

        // 5. Upload chunk 2 (correct offset)
        mockMvc.perform(put("/api/v1/uploads/" + uploadId)
                        .contentType(MediaType.APPLICATION_OCTET_STREAM)
                        .header("Upload-Offset", chunk1.length)
                        .content(chunk2))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.receivedBytes").value(chunk1.length + chunk2.length))
                .andExpect(jsonPath("$.complete").value(false));

        // 6. Upload chunk 3 (completes upload)
        mockMvc.perform(put("/api/v1/uploads/" + uploadId)
                        .contentType(MediaType.APPLICATION_OCTET_STREAM)
                        .header("Upload-Offset", chunk1.length + chunk2.length)
                        .content(chunk3))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.receivedBytes").value(totalBytes))
                .andExpect(jsonPath("$.complete").value(true));

        // 7. Verify session is completed and removed
        mockMvc.perform(get("/api/v1/uploads/" + uploadId))
                .andExpect(status().isNotFound());

        // 8. Verify the new file is in file list and can be downloaded
        MvcResult listResult = mockMvc.perform(get("/api/v1/files"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andReturn();

        JsonNode listJson = objectMapper.readTree(listResult.getResponse().getContentAsString());
        String resumableId = null;
        for (JsonNode item : listJson) {
            if ("resumable.dat".equals(item.get("name").asText())) {
                resumableId = item.get("id").asText();
                break;
            }
        }
        assertThat(resumableId).isNotNull();

        mockMvc.perform(get("/api/v1/files/" + resumableId + "/download"))
                .andExpect(status().isOk())
                .andExpect(content().string("Part1-Part2-Part3"));
    }

    @Test
    @Order(12)
    void testResumableUpload_cancelLifecycle() throws Exception {
        // Start session
        MvcResult startResult = mockMvc.perform(post("/api/v1/uploads")
                        .param("filename", "to-cancel.dat")
                        .param("totalBytes", "1000"))
                .andExpect(status().isOk())
                .andReturn();

        String uploadId = objectMapper.readTree(startResult.getResponse().getContentAsString())
                .get("uploadId").asText();

        // Cancel session
        mockMvc.perform(delete("/api/v1/uploads/" + uploadId))
                .andExpect(status().isNoContent());

        // Session should be gone
        mockMvc.perform(get("/api/v1/uploads/" + uploadId))
                .andExpect(status().isNotFound());

        // Cancelling again should return 404
        mockMvc.perform(delete("/api/v1/uploads/" + uploadId))
                .andExpect(status().isNotFound());
    }

    @Test
    @Order(13)
    void testDeleteFile_success() throws Exception {
        mockMvc.perform(delete("/api/v1/files/" + uploadedFileId))
                .andExpect(status().isNoContent());

        // Verify metadata returns 404 now
        mockMvc.perform(get("/api/v1/files/" + uploadedFileId))
                .andExpect(status().isNotFound());

        // Deleting again should return 404
        mockMvc.perform(delete("/api/v1/files/" + uploadedFileId))
                .andExpect(status().isNotFound());
    }

    @Test
    @Order(14)
    void testResumableUpload_invalidSize_returnsBadRequest() throws Exception {
        mockMvc.perform(post("/api/v1/uploads")
                        .param("filename", "invalid.dat")
                        .param("totalBytes", "0"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Bad Request"))
                .andExpect(jsonPath("$.message").value("Invalid upload size"));
    }

    @Test
    @Order(15)
    void testResumableUpload_chunkExceedsRemaining_returnsContentTooLarge() throws Exception {
        MvcResult startResult = mockMvc.perform(post("/api/v1/uploads")
                        .param("filename", "overflow.dat")
                        .param("totalBytes", "10"))
                .andExpect(status().isOk())
                .andReturn();

        String uploadId = objectMapper.readTree(startResult.getResponse().getContentAsString())
                .get("uploadId").asText();

        byte[] oversized = new byte[20];
        mockMvc.perform(put("/api/v1/uploads/" + uploadId)
                        .contentType(MediaType.APPLICATION_OCTET_STREAM)
                        .header("Upload-Offset", 0)
                        .content(oversized))
                .andExpect(status().isPayloadTooLarge())
                .andExpect(jsonPath("$.message").value("Chunk exceeds remaining upload size"));

        // Clean up
        mockMvc.perform(delete("/api/v1/uploads/" + uploadId))
                .andExpect(status().isNoContent());
    }
}

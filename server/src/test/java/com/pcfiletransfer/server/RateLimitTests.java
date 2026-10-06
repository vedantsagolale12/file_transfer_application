package com.pcfiletransfer.server;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.file.Path;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class RateLimitTests {

    @TempDir
    static Path tempDir;

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("file-transfer.storage.location", () -> tempDir.toAbsolutePath().toString());
        registry.add("file-transfer.rate-limit.requests-per-minute", () -> "2");
    }

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testRateLimit_exceededReturns429() throws Exception {
        // Request 1: ok
        mockMvc.perform(get("/api/v1/health").with(request -> {
            request.setRemoteAddr("192.168.1.100");
            return request;
        })).andExpect(status().isOk());

        // Request 2: ok
        mockMvc.perform(get("/api/v1/health").with(request -> {
            request.setRemoteAddr("192.168.1.100");
            return request;
        })).andExpect(status().isOk());

        // Request 3: 429 Too Many Requests
        mockMvc.perform(get("/api/v1/health").with(request -> {
            request.setRemoteAddr("192.168.1.100");
            return request;
        })).andExpect(status().isTooManyRequests())
           .andExpect(content().json("{\"error\":\"Rate limit exceeded\"}"));

        // Different IP address should still succeed
        mockMvc.perform(get("/api/v1/health").with(request -> {
            request.setRemoteAddr("192.168.1.101");
            return request;
        })).andExpect(status().isOk());
    }
}

package com.pcfiletransfer.server.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@Configuration
public class StorageConfig {
    @Bean
    public Path storageRoot(
            @Value("${file-transfer.storage.location}")
            String location
    ) throws IOException {
        Path root = Path.of(location).toAbsolutePath().normalize();
        Files.createDirectories(root);
        Files.createDirectories(root.resolve(".uploads"));
        return root.toRealPath();
    }
}

package com.pcfiletransfer.server.service;

import com.pcfiletransfer.server.dto.FileDto;
import com.pcfiletransfer.server.dto.UploadSessionDto;
import com.pcfiletransfer.server.exception.ApiException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.channels.FileChannel;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Stream;

@Service
public class FileService {
    private static final int MAX_NAME_LENGTH = 180;

    private final Path root;
    private final Path uploadDirectory;
    private final long maxUploadBytes;
    private final int maxListItems;

    private final Map<String, UploadState> uploads =
            new ConcurrentHashMap<>();

    private record UploadState(
            String name,
            long total,
            Path path
    ) {
    }

    public FileService(
            Path storageRoot,
            @Value("${file-transfer.max-upload-bytes}")
            long maxUploadBytes,
            @Value("${file-transfer.max-list-items}")
            int maxListItems
    ) {
        // Normalize so that parent comparisons in resolve()/candidate() work.
        this.root = storageRoot.toAbsolutePath().normalize();
        this.uploadDirectory = this.root.resolve(".uploads");
        this.maxUploadBytes = maxUploadBytes;
        this.maxListItems = maxListItems;

        try {
            Files.createDirectories(this.root);
            Files.createDirectories(this.uploadDirectory);
            cleanLeftovers();
        } catch (IOException ex) {
            throw new UncheckedIOException(
                    "Unable to initialize storage", ex
            );
        }
    }

    /**
     * Upload sessions live in memory only, so after a restart any
     * .part files are orphaned. Remove them.
     */
    private void cleanLeftovers() throws IOException {
        try (Stream<Path> stream = Files.list(uploadDirectory)) {
            for (Path p : (Iterable<Path>) stream::iterator) {
                Files.deleteIfExists(p);
            }
        }

        try (Stream<Path> stream = Files.list(root)) {
            for (Path p : (Iterable<Path>) stream::iterator) {
                String n = p.getFileName().toString();
                if (n.startsWith(".incoming-") && n.endsWith(".part")) {
                    Files.deleteIfExists(p);
                }
            }
        }
    }

    public List<FileDto> list() throws IOException {
        try (Stream<Path> stream = Files.list(root)) {
            return stream
                    // Hide temp/internal files; they can't be resolved anyway.
                    .filter(path -> !path.getFileName()
                            .toString().startsWith("."))
                    .filter(path -> Files.isRegularFile(
                            path,
                            LinkOption.NOFOLLOW_LINKS
                    ))
                    .sorted(Comparator.comparing(
                            (Path p) -> p.getFileName().toString()
                    ))
                    .limit(maxListItems)
                    .map(this::toDto)
                    .toList();
        }
    }

    public FileDto metadata(String id) throws IOException {
        return toDto(existingFile(id));
    }

    // Obtain a resource for streaming a file.
    public Resource resource(String id) throws IOException {
        return new FileSystemResource(existingFile(id));
    }

    // Upload a complete file using multipart/form-data.
    public FileDto upload(MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "Empty files are not accepted"
            );
        }

        if (file.getSize() > maxUploadBytes) {
            throw new ApiException(
                    HttpStatus.CONTENT_TOO_LARGE,
                    "File exceeds upload limit"
            );
        }

        String name = cleanName(file.getOriginalFilename());

        Path temp = Files.createTempFile(
                root,
                ".incoming-",
                ".part"
        );

        try {
            try (InputStream input = file.getInputStream()) {
                Files.copy(
                        input,
                        temp,
                        StandardCopyOption.REPLACE_EXISTING
                );
            }

            Path target = moveToUniqueTarget(temp, name);

            return toDto(target);
        } finally {
            Files.deleteIfExists(temp);
        }
    }

    // Delete a stored file.
    public void delete(String id) throws IOException {
        Files.delete(existingFile(id));
    }

    // Start a resumable upload session.
    public UploadSessionDto startUpload(
            String filename,
            long totalBytes
    ) throws IOException {

        if (totalBytes <= 0 || totalBytes > maxUploadBytes) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid upload size"
            );
        }

        String name = cleanName(filename);

        String uploadId = UUID.randomUUID().toString();

        // Make sure the directory exists (it could have been removed).
        Files.createDirectories(uploadDirectory);

        Path path = uploadDirectory.resolve(uploadId + ".part");

        Files.createFile(path);

        uploads.put(
                uploadId,
                new UploadState(name, totalBytes, path)
        );

        return new UploadSessionDto(
                uploadId,
                0,
                totalBytes,
                false
        );
    }

    // Append a chunk to an existing upload.
    public UploadSessionDto appendChunk(
            String uploadId,
            long offset,
            InputStream chunk
    ) throws IOException {

        UploadState state = uploads.get(uploadId);

        if (state == null) {
            throw notFoundSession();
        }

        synchronized (state) {
            // The session may have been cancelled/completed while we
            // were waiting for the lock.
            if (uploads.get(uploadId) != state) {
                throw notFoundSession();
            }

            long current = Files.size(state.path());

            if (offset != current) {
                throw new ApiException(
                        HttpStatus.CONFLICT,
                        "Offset mismatch; expected " + current
                );
            }

            long remaining = state.total() - current;

            if (remaining <= 0) {
                throw new ApiException(
                        HttpStatus.CONFLICT,
                        "Upload is already complete"
                );
            }

            try (
                    InputStream input = chunk;
                    OutputStream output = Files.newOutputStream(
                            state.path(),
                            StandardOpenOption.APPEND
                    )
            ) {
                byte[] buffer = new byte[64 * 1024];
                long written = 0;
                int read;

                while ((read = input.read(buffer)) != -1) {
                    written += read;

                    if (written > remaining) {
                        throw new ApiException(
                                HttpStatus.CONTENT_TOO_LARGE,
                                "Chunk exceeds remaining upload size"
                        );
                    }

                    output.write(buffer, 0, read);
                }
            } catch (ApiException ex) {
                // Roll back only the bad chunk; keep the session so the
                // client can resume from the last good offset.
                truncate(state.path(), current);
                throw ex;
            }

            long received = Files.size(state.path());

            if (received == state.total()) {
                Path destination =
                        moveToUniqueTarget(state.path(), state.name());

                uploads.remove(uploadId);

                return new UploadSessionDto(
                        uploadId,
                        received,
                        state.total(),
                        true
                );
            }

            return new UploadSessionDto(
                    uploadId,
                    received,
                    state.total(),
                    false
            );
        }
    }

    // Get current upload progress.
    public UploadSessionDto uploadStatus(
            String uploadId
    ) throws IOException {

        UploadState state = uploads.get(uploadId);

        if (state == null) {
            throw notFoundSession();
        }

        synchronized (state) {
            if (uploads.get(uploadId) != state) {
                throw notFoundSession();
            }

            return new UploadSessionDto(
                    uploadId,
                    Files.size(state.path()),
                    state.total(),
                    false
            );
        }
    }

    // Cancel a resumable upload.
    public void cancelUpload(String uploadId) throws IOException {
        UploadState state = uploads.remove(uploadId);

        if (state == null) {
            throw notFoundSession();
        }

        synchronized (state) {
            Files.deleteIfExists(state.path());
        }
    }

    private ApiException notFoundSession() {
        return new ApiException(
                HttpStatus.NOT_FOUND,
                "Upload session not found"
        );
    }

    private void truncate(Path path, long size) throws IOException {
        try (FileChannel channel =
                     FileChannel.open(path, StandardOpenOption.WRITE)) {
            channel.truncate(size);
        }
    }

    // Resolve an ID and make sure it points to an existing regular file.
    private Path existingFile(String id) throws IOException {
        Path path = resolve(id);

        if (!Files.isRegularFile(
                path,
                LinkOption.NOFOLLOW_LINKS
        )) {
            throw new ApiException(
                    HttpStatus.NOT_FOUND,
                    "File not found"
            );
        }

        return path;
    }

    // Convert an API file ID into a safe storage path.
    private Path resolve(String id) {
        final String name;

        try {
            name = new String(
                    Base64.getUrlDecoder().decode(id),
                    StandardCharsets.UTF_8
            );
        } catch (IllegalArgumentException ex) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid file ID"
            );
        }

        if (name.isBlank()
                || name.contains("/")
                || name.contains("\\")
                || name.contains("\0")
                || name.startsWith(".")) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid file ID"
            );
        }

        final Path path;

        try {
            path = root.resolve(name).normalize();
        } catch (InvalidPathException ex) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid file ID"
            );
        }

        if (!root.equals(path.getParent())
                || Files.isSymbolicLink(path)) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid file ID"
            );
        }

        return path;
    }

    // Convert filesystem information into a DTO.
    private FileDto toDto(Path path) {
        try {
            String name = path.getFileName().toString();

            String id = Base64.getUrlEncoder()
                    .withoutPadding()
                    .encodeToString(
                            name.getBytes(StandardCharsets.UTF_8)
                    );

            String contentType = Files.probeContentType(path);

            BasicFileAttributes attributes =
                    Files.readAttributes(
                            path,
                            BasicFileAttributes.class,
                            LinkOption.NOFOLLOW_LINKS
                    );

            return new FileDto(
                    id,
                    name,
                    attributes.size(),
                    contentType == null
                            ? "application/octet-stream"
                            : contentType,
                    attributes.lastModifiedTime().toMillis()
            );

        } catch (IOException ex) {
            throw new UncheckedIOException(ex);
        }
    }

    // Sanitize a user-supplied filename.
    private String cleanName(String raw) {
        String name = raw == null ? "upload.bin" : raw;

        // Strip any directory part (both separator styles) without
        // relying on Path parsing, which can throw or return null.
        name = name.replace('\\', '/');
        int slash = name.lastIndexOf('/');
        if (slash >= 0) {
            name = name.substring(slash + 1);
        }

        name = name.replaceAll("\\p{Cntrl}", "_").trim();

        if (name.length() > MAX_NAME_LENGTH) {
            name = name.substring(name.length() - MAX_NAME_LENGTH).trim();
        }

        // Checked after truncation so the result can't become hidden.
        if (name.isBlank() || name.startsWith(".")) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid filename"
            );
        }

        return name;
    }

    private Path candidate(String name, int index) {
        String fileName = name;

        if (index > 0) {
            String stem = name;
            String extension = "";

            int dot = name.lastIndexOf('.');

            if (dot > 0) {
                stem = name.substring(0, dot);
                extension = name.substring(dot);
            }

            fileName = stem + " (" + index + ")" + extension;
        }

        Path target = root.resolve(fileName).normalize();

        if (!root.equals(target.getParent())) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid filename"
            );
        }

        return target;
    }

    /**
     * Move a finished file into the shared directory under a unique name.
     * The name is reserved atomically with createFile, so concurrent
     * uploads can never pick the same name and silently overwrite
     * each other (ATOMIC_MOVE replaces existing files on POSIX).
     */
    private Path moveToUniqueTarget(
            Path source,
            String name
    ) throws IOException {
        for (int i = 0; i < 100000; i++) {
            Path target = candidate(name, i);

            try {
                Files.createFile(target);
            } catch (FileAlreadyExistsException ex) {
                continue;
            }

            try {
                moveSafely(source, target);
                return target;
            } catch (IOException | RuntimeException ex) {
                Files.deleteIfExists(target);
                throw ex;
            }
        }

        throw new IOException(
                "Unable to allocate a unique filename"
        );
    }

    // Move a file onto an already-reserved destination.
    private void moveSafely(
            Path source,
            Path destination
    ) throws IOException {
        try {
            Files.move(
                    source,
                    destination,
                    StandardCopyOption.ATOMIC_MOVE,
                    StandardCopyOption.REPLACE_EXISTING
            );
        } catch (AtomicMoveNotSupportedException ex) {
            Files.move(
                    source,
                    destination,
                    StandardCopyOption.REPLACE_EXISTING
            );
        }
    }
}
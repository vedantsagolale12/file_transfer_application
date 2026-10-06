package com.pcfiletransfer.server.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.jspecify.annotations.NonNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RateLimitInterceptor implements HandlerInterceptor {
    private record Window(
            long minute,
            int count
    ) {
    }

    private final ConcurrentHashMap<String, Window> clients =
            new ConcurrentHashMap<>();

    private final int limit;

    public RateLimitInterceptor(
            @Value("${file-transfer.rate-limit.requests-per-minute:120}")
            int limit
    ) {
        this.limit = limit;
    }

    @Override
    public boolean preHandle(
            HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull Object handler
    ) throws Exception {

        String ip = request.getRemoteAddr();
        if (ip == null || ip.isBlank()) {
            ip = "unknown";
        }

        long minute = Instant.now().getEpochSecond() / 60;

        Window window = clients.compute(
                ip,
                (key, old) -> {
                    if (old == null || old.minute() != minute) {
                        return new Window(minute, 1);
                    }

                    return new Window(
                            minute,
                            old.count() + 1
                    );
                }
        );

        if (window.count() > limit) {
            response.setStatus(
                    HttpStatus.TOO_MANY_REQUESTS.value()
            );

            response.setContentType("application/json");

            response.getWriter().write(
                    "{\"error\":\"Rate limit exceeded\"}"
            );

            return false;
        }

        return true;
    }


}

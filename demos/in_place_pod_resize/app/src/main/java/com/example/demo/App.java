package com.example.demo;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.lang.management.ManagementFactory;
import java.lang.management.RuntimeMXBean;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Java Application designed to demonstrate In-Place Resource Resize in GKE.
 * Simulates high CPU consumption during startup/warmup phase,
 * and maintains continuous runtime metrics for inspection.
 */
public class App {

    private static final int PORT = 8080;
    private static final Instant START_INSTANT = Instant.now();
    private static final AtomicBoolean WARMUP_RUNNING = new AtomicBoolean(true);
    private static final long PID = ProcessHandle.current().pid();

    public static void main(String[] args) throws IOException {
        System.out.println("===============================================================");
        System.out.println("  Java In-Place Pod Resize Demo Application");
        System.out.println("===============================================================");
        System.out.printf("  PID:                  %d%n", PID);
        System.out.printf("  Java Version:         %s (%s)%n", System.getProperty("java.version"), System.getProperty("java.vendor"));
        System.out.printf("  Available Processors: %d%n", Runtime.getRuntime().availableProcessors());
        System.out.printf("  Max Memory (MB):      %d%n", Runtime.getRuntime().maxMemory() / (1024 * 1024));
        System.out.printf("  Start Time:           %s%n", START_INSTANT);
        System.out.println("===============================================================");

        // Inicia o servidor HTTP embutido
        HttpServer server = HttpServer.create(new InetSocketAddress(PORT), 0);
        server.createContext("/", new RootHandler());
        server.createContext("/status", new StatusHandler());
        server.createContext("/warmup", new WarmupTriggerHandler());
        server.createContext("/healthz", new HealthHandler());
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        server.start();

        System.out.printf("[INFO] HTTP Server started and listening on port %d%n", PORT);

        // Executa o warmup inicial assincronamente
        int warmupSeconds = getEnvInt("WARMUP_SECONDS", 10);
        startStartupWarmup(warmupSeconds);

        // Agenda logs periódicos de Heartbeat para monitorar uptime e demonstrar processo contínuo
        ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(App::logHeartbeat, 5, 10, TimeUnit.SECONDS);

        // Shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.printf("[SHUTDOWN] Application terminating after %d seconds uptime.%n", getUptimeSeconds());
            server.stop(0);
            scheduler.shutdown();
        }));
    }

    private static void startStartupWarmup(int seconds) {
        Thread.ofPlatform().name("startup-warmup").start(() -> {
            int cores = Runtime.getRuntime().availableProcessors();
            System.out.printf("[WARMUP] Starting simulated JVM warmup using %d threads for %d seconds...%n", cores, seconds);
            long end = System.currentTimeMillis() + (seconds * 1000L);

            var warmupExecutor = Executors.newFixedThreadPool(Math.max(1, cores));
            for (int i = 0; i < cores; i++) {
                warmupExecutor.submit(() -> {
                    long count = 0;
                    while (System.currentTimeMillis() < end) {
                        count += Math.sqrt(Math.random() * 10000);
                    }
                    return count;
                });
            }

            warmupExecutor.shutdown();
            try {
                warmupExecutor.awaitTermination(seconds + 5L, TimeUnit.SECONDS);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            }

            WARMUP_RUNNING.set(false);
            System.out.println("---------------------------------------------------------------");
            System.out.println("[WARMUP COMPLETE] Startup phase finished.");
            System.out.println("[WARMUP COMPLETE] Application in steady state idle.");
            System.out.println("[WARMUP COMPLETE] Ready for In-Place CPU reduction without restart!");
            System.out.println("---------------------------------------------------------------");
        });
    }

    private static void logHeartbeat() {
        long uptime = getUptimeSeconds();
        int processors = Runtime.getRuntime().availableProcessors();
        long usedMem = (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory()) / (1024 * 1024);
        long maxMem = Runtime.getRuntime().maxMemory() / (1024 * 1024);

        System.out.printf("[HEARTBEAT] PID: %d | Uptime: %ds | Cores (JVM): %d | Heap: %dMB/%dMB | Warmup: %s%n",
                PID, uptime, processors, usedMem, maxMem, WARMUP_RUNNING.get() ? "RUNNING" : "DONE");
    }

    private static long getUptimeSeconds() {
        RuntimeMXBean mxBean = ManagementFactory.getRuntimeMXBean();
        return mxBean.getUptime() / 1000;
    }

    private static int getEnvInt(String key, int defaultValue) {
        String val = System.getenv(key);
        if (val != null && !val.isBlank()) {
            try {
                return Integer.parseInt(val.trim());
            } catch (NumberFormatException ignored) {}
        }
        return defaultValue;
    }

    // Handlers HTTP
    static class RootHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = """
                    {
                      "message": "GKE In-Place Pod Resize Demo - Java App",
                      "endpoints": ["/status", "/warmup", "/healthz"]
                    }
                    """;
            sendResponse(exchange, 200, response, "application/json");
        }
    }

    static class StatusHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            long uptime = getUptimeSeconds();
            int processors = Runtime.getRuntime().availableProcessors();
            long totalMem = Runtime.getRuntime().totalMemory() / (1024 * 1024);
            long freeMem = Runtime.getRuntime().freeMemory() / (1024 * 1024);
            long usedMem = totalMem - freeMem;
            long maxMem = Runtime.getRuntime().maxMemory() / (1024 * 1024);

            String response = String.format("""
                    {
                      "pid": %d,
                      "uptime_seconds": %d,
                      "start_time": "%s",
                      "available_processors": %d,
                      "warmup_active": %b,
                      "memory": {
                        "used_mb": %d,
                        "total_mb": %d,
                        "max_mb": %d
                      }
                    }
                    """, PID, uptime, START_INSTANT, processors, WARMUP_RUNNING.get(), usedMem, totalMem, maxMem);

            sendResponse(exchange, 200, response, "application/json");
        }
    }

    static class WarmupTriggerHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            int duration = 5;
            startStartupWarmup(duration);
            String response = String.format("{\"status\": \"triggered\", \"duration_seconds\": %d}", duration);
            sendResponse(exchange, 200, response, "application/json");
        }
    }

    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            sendResponse(exchange, 200, "{\"status\": \"UP\"}", "application/json");
        }
    }

    private static void sendResponse(HttpExchange exchange, int statusCode, String body, String contentType) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", contentType);
        exchange.sendResponseHeaders(statusCode, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }
}

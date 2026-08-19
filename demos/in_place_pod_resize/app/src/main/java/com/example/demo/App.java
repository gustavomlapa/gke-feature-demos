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
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Java Application designed to demonstrate In-Place Resource Resize in GKE.
 * Serves an interactive Web Dashboard for side-by-side presentation.
 */
public class App {

    private static final int PORT = 8080;
    private static final Instant START_INSTANT = Instant.now();
    private static final AtomicBoolean WARMUP_RUNNING = new AtomicBoolean(true);
    private static final long PID = ProcessHandle.current().pid();
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
            .withZone(ZoneId.systemDefault());

    public static void main(String[] args) throws IOException {
        System.out.println("===============================================================");
        System.out.println("  GKE In-Place Pod Resize Demo - Java Web Application");
        System.out.println("===============================================================");
        System.out.printf("  PID:                  %d%n", PID);
        System.out.printf("  Java Version:         %s (%s)%n", System.getProperty("java.version"), System.getProperty("java.vendor"));
        System.out.printf("  Available Processors: %d%n", Runtime.getRuntime().availableProcessors());
        System.out.printf("  Max Memory (MB):      %d%n", Runtime.getRuntime().maxMemory() / (1024 * 1024));
        System.out.printf("  Start Time:           %s%n", FORMATTER.format(START_INSTANT));
        System.out.println("===============================================================");

        HttpServer server = HttpServer.create(new InetSocketAddress(PORT), 0);
        server.createContext("/", new DashboardHtmlHandler());
        server.createContext("/status", new StatusJsonHandler());
        server.createContext("/api/status", new StatusJsonHandler());
        server.createContext("/warmup", new WarmupTriggerHandler());
        server.createContext("/healthz", new HealthHandler());
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        server.start();

        System.out.printf("[INFO] Web Dashboard started at http://localhost:%d/%n", PORT);

        int warmupSeconds = getEnvInt("WARMUP_SECONDS", 15);
        startStartupWarmup(warmupSeconds);

        ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(App::logHeartbeat, 5, 10, TimeUnit.SECONDS);

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

        System.out.printf("[HEARTBEAT] PID: %d | Uptime: %ds | Cores: %d | Heap: %dMB/%dMB | Warmup: %s%n",
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

    // Handler do Dashboard HTML
    static class DashboardHtmlHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if (!exchange.getRequestMethod().equalsIgnoreCase("GET")) {
                sendResponse(exchange, 405, "Method Not Allowed", "text/plain");
                return;
            }

            String html = """
                    <!DOCTYPE html>
                    <html lang="pt-BR">
                    <head>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>GKE In-Place Pod Resize Demo - Java App</title>
                        <style>
                            :root {
                                --bg-main: #0f172a;
                                --bg-card: #1e293b;
                                --border-card: #334155;
                                --text-primary: #f8fafc;
                                --text-secondary: #94a3b8;
                                --accent-blue: #38bdf8;
                                --accent-green: #4ade80;
                                --accent-yellow: #facc15;
                                --accent-purple: #c084fc;
                                --accent-red: #f87171;
                            }
                            * { box-sizing: border-box; margin: 0; padding: 0; }
                            body {
                                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                                background-color: var(--bg-main);
                                color: var(--text-primary);
                                min-height: 100vh;
                                display: flex;
                                flex-direction: column;
                                align-items: center;
                                padding: 2rem 1rem;
                            }
                            .container { width: 100%; max-width: 900px; }
                            header {
                                text-align: center;
                                margin-bottom: 2rem;
                            }
                            .badge-header {
                                display: inline-flex;
                                align-items: center;
                                gap: 0.5rem;
                                background: rgba(56, 189, 248, 0.1);
                                color: var(--accent-blue);
                                border: 1px solid rgba(56, 189, 248, 0.3);
                                padding: 0.35rem 0.85rem;
                                border-radius: 9999px;
                                font-size: 0.875rem;
                                font-weight: 600;
                                margin-bottom: 1rem;
                            }
                            h1 { font-size: 2rem; font-weight: 700; margin-bottom: 0.5rem; }
                            .subtitle { color: var(--text-secondary); font-size: 1rem; }
                            
                            .status-banner {
                                background: var(--bg-card);
                                border: 1px solid var(--border-card);
                                border-radius: 12px;
                                padding: 1.25rem;
                                margin-bottom: 1.5rem;
                                display: flex;
                                justify-content: space-between;
                                align-items: center;
                                flex-wrap: wrap;
                                gap: 1rem;
                            }
                            .live-indicator {
                                display: flex;
                                align-items: center;
                                gap: 0.75rem;
                            }
                            .pulse-dot {
                                width: 14px;
                                height: 14px;
                                background-color: var(--accent-green);
                                border-radius: 50%;
                                box-shadow: 0 0 0 0 rgba(74, 222, 128, 0.7);
                                animation: pulse 1.5s infinite;
                            }
                            @keyframes pulse {
                                0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(74, 222, 128, 0.7); }
                                70% { transform: scale(1); box-shadow: 0 0 0 10px rgba(74, 222, 128, 0); }
                                100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(74, 222, 128, 0); }
                            }
                            .grid {
                                display: grid;
                                grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
                                gap: 1.25rem;
                                margin-bottom: 1.5rem;
                            }
                            .card {
                                background: var(--bg-card);
                                border: 1px solid var(--border-card);
                                border-radius: 12px;
                                padding: 1.5rem;
                                display: flex;
                                flex-direction: column;
                            }
                            .card-label {
                                color: var(--text-secondary);
                                font-size: 0.875rem;
                                font-weight: 500;
                                margin-bottom: 0.5rem;
                                text-transform: uppercase;
                                letter-spacing: 0.05em;
                            }
                            .card-value {
                                font-size: 1.75rem;
                                font-weight: 700;
                                color: var(--text-primary);
                                margin-top: auto;
                            }
                            .card-value.highlight { color: var(--accent-green); font-family: monospace; }
                            .card-value.blue { color: var(--accent-blue); }
                            .card-value.yellow { color: var(--accent-yellow); }
                            .card-value.purple { color: var(--accent-purple); }

                            .progress-container {
                                background: #334155;
                                border-radius: 9999px;
                                height: 8px;
                                width: 100%;
                                overflow: hidden;
                                margin-top: 0.75rem;
                            }
                            .progress-bar {
                                background: var(--accent-blue);
                                height: 100%;
                                width: 0%;
                                transition: width 0.3s ease;
                            }

                            .log-box {
                                background: #090d16;
                                border: 1px solid var(--border-card);
                                border-radius: 12px;
                                padding: 1.25rem;
                                font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
                                font-size: 0.85rem;
                                color: #e2e8f0;
                                height: 160px;
                                overflow-y: auto;
                            }
                            .log-entry { margin-bottom: 0.35rem; }
                            .log-time { color: var(--text-secondary); }
                            .log-success { color: var(--accent-green); }
                            .log-warmup { color: var(--accent-yellow); }

                            .actions {
                                display: flex;
                                justify-content: flex-end;
                                gap: 0.75rem;
                                margin-top: 1rem;
                            }
                            .btn {
                                background: #334155;
                                color: var(--text-primary);
                                border: none;
                                padding: 0.5rem 1rem;
                                border-radius: 8px;
                                font-size: 0.875rem;
                                font-weight: 600;
                                cursor: pointer;
                                transition: background 0.2s;
                            }
                            .btn:hover { background: #475569; }
                            .btn-primary { background: #0284c7; color: white; }
                            .btn-primary:hover { background: #0369a1; }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <header>
                                <div class="badge-header">
                                    <span>☸️ Google Kubernetes Engine</span>
                                    <span>•</span>
                                    <span>Feature Demo</span>
                                </div>
                                <h1>In-Place Pod Resize Demo</h1>
                                <p class="subtitle">Aplicação Java em execução contínua com redimensionamento de CPU sem downtime</p>
                            </header>

                            <div class="status-banner">
                                <div class="live-indicator">
                                    <div class="pulse-dot"></div>
                                    <div>
                                        <strong style="color: var(--accent-green); font-size: 1.1rem;">POD EM EXECUÇÃO CONTÍNUA</strong>
                                        <div style="font-size: 0.85rem; color: var(--text-secondary);">Processo Java Ativo (Zero Restarts)</div>
                                    </div>
                                </div>
                                <div id="warmup-badge" style="padding: 0.4rem 0.9rem; border-radius: 8px; font-weight: 600; font-size: 0.875rem; background: rgba(250, 204, 21, 0.15); color: var(--accent-yellow); border: 1px solid rgba(250, 204, 21, 0.3);">
                                    🔥 Aguardando status...
                                </div>
                            </div>

                            <div class="grid">
                                <div class="card">
                                    <div class="card-label">⏱️ Uptime Contínuo</div>
                                    <div class="card-value highlight" id="uptime">00:00:00</div>
                                    <div style="font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.5rem;" id="uptime-seconds">Uptime: 0s</div>
                                </div>

                                <div class="card">
                                    <div class="card-label">🆔 Process ID (PID) & Startup</div>
                                    <div class="card-value purple" id="pid">PID: ...</div>
                                    <div style="font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.5rem;" id="start-time">Iniciado: ...</div>
                                </div>

                                <div class="card">
                                    <div class="card-label">⚙️ Cores Vistos pela JVM</div>
                                    <div class="card-value blue" id="cores">... Cores</div>
                                    <div style="font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.5rem;">Runtime.availableProcessors()</div>
                                </div>

                                <div class="card">
                                    <div class="card-label">🧠 Memória Heap JVM</div>
                                    <div class="card-value yellow" id="heap-text">... MB</div>
                                    <div class="progress-container">
                                        <div class="progress-bar" id="heap-bar"></div>
                                    </div>
                                    <div style="font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.5rem;" id="heap-max">Máx: ... MB</div>
                                </div>
                            </div>

                            <div style="margin-bottom: 0.5rem; display: flex; justify-content: space-between; align-items: center;">
                                <strong style="font-size: 0.95rem; color: var(--text-secondary);">📜 Log de Atividade em Tempo Real</strong>
                                <span style="font-size: 0.8rem; color: var(--text-secondary);">Atualização automática: 1s</span>
                            </div>
                            <div class="log-box" id="logs">
                                <div class="log-entry"><span class="log-time">[Init]</span> Conectando ao Pod...</div>
                            </div>

                            <div class="actions">
                                <button class="btn" onclick="triggerWarmup()">⚡ Simular Novo Warmup de CPU</button>
                                <button class="btn btn-primary" onclick="fetchStatus()">🔄 Atualizar Agora</button>
                            </div>
                        </div>

                        <script>
                            let lastWarmupState = null;

                            function formatUptime(seconds) {
                                const h = Math.floor(seconds / 3600).toString().padStart(2, '0');
                                const m = Math.floor((seconds % 3600) / 60).toString().padStart(2, '0');
                                const s = (seconds % 60).toString().padStart(2, '0');
                                return `${h}:${m}:${s}`;
                            }

                            function addLog(msg, type = 'info') {
                                const box = document.getElementById('logs');
                                const now = new Date().toLocaleTimeString();
                                const div = document.createElement('div');
                                div.className = 'log-entry';
                                let cls = '';
                                if (type === 'success') cls = 'log-success';
                                if (type === 'warmup') cls = 'log-warmup';
                                div.innerHTML = `<span class="log-time">[${now}]</span> <span class="${cls}">${msg}</span>`;
                                box.appendChild(div);
                                box.scrollTop = box.scrollHeight;
                            }

                            async function fetchStatus() {
                                try {
                                    const res = await fetch('/status');
                                    if (!res.ok) throw new Error('HTTP ' + res.status);
                                    const data = await res.json();

                                    document.getElementById('uptime').innerText = formatUptime(data.uptime_seconds);
                                    document.getElementById('uptime-seconds').innerText = `Uptime: ${data.uptime_seconds}s ininterruptos`;
                                    document.getElementById('pid').innerText = `PID: ${data.pid}`;
                                    document.getElementById('start-time').innerText = `Iniciado: ${data.start_time.substring(0, 19).replace('T', ' ')} UTC`;
                                    document.getElementById('cores').innerText = `${data.available_processors} Core(s)`;

                                    const usedMb = data.memory.used_mb;
                                    const maxMb = data.memory.max_mb;
                                    const pct = Math.min(100, Math.round((usedMb / maxMb) * 100));
                                    document.getElementById('heap-text').innerText = `${usedMb} MB (${pct}%)`;
                                    document.getElementById('heap-max').innerText = `Total Alocado: ${data.memory.total_mb} MB | Máx: ${maxMb} MB`;
                                    document.getElementById('heap-bar').style.width = pct + '%';

                                    const badge = document.getElementById('warmup-badge');
                                    if (data.warmup_active) {
                                        badge.style.background = 'rgba(250, 204, 21, 0.15)';
                                        badge.style.color = '#facc15';
                                        badge.style.borderColor = 'rgba(250, 204, 21, 0.3)';
                                        badge.innerHTML = '🔥 Startup Warmup Ativo (Carga de CPU)';
                                    } else {
                                        badge.style.background = 'rgba(74, 222, 128, 0.15)';
                                        badge.style.color = '#4ade80';
                                        badge.style.borderColor = 'rgba(74, 222, 128, 0.3)';
                                        badge.innerHTML = '🟢 Regime Estável (Idle) - Pronto para Resize';
                                    }

                                    if (lastWarmupState === true && !data.warmup_active) {
                                        addLog('🎉 Warmup concluído! Pod em repouso. Pronto para redução in-place de CPU.', 'success');
                                    }
                                    lastWarmupState = data.warmup_active;

                                } catch (err) {
                                    addLog('Erro ao consultar status: ' + err.message, 'warmup');
                                }
                            }

                            async function triggerWarmup() {
                                addLog('Disparando simulação de warmup sob demanda...', 'warmup');
                                try {
                                    await fetch('/warmup');
                                    fetchStatus();
                                } catch (e) {
                                    addLog('Falha ao disparar warmup: ' + e.message, 'warmup');
                                }
                            }

                            setInterval(fetchStatus, 1000);
                            fetchStatus();
                            addLog('Dashboard conectado com sucesso ao Pod Java.', 'success');
                        </script>
                    </body>
                    </html>
                    """;

            sendResponse(exchange, 200, html, "text/html; charset=UTF-8");
        }
    }

    // Handler JSON
    static class StatusJsonHandler implements HttpHandler {
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

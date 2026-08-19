# Stage 1: Build Java Application
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build
COPY src/main/java/com/example/demo/App.java ./src/main/java/com/example/demo/App.java

# Compila o arquivo Java
RUN javac -d ./out src/main/java/com/example/demo/App.java

# Stage 2: Runtime Image (leve)
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY --from=builder /build/out /app

# Variáveis de ambiente default
ENV WARMUP_SECONDS=10 \
    JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

EXPOSE 8080

# Executa a aplicação
ENTRYPOINT ["java", "-cp", "/app", "com.example.demo.App"]

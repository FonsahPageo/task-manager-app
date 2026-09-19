# ---- Backend image (task-manager back-end: Spring Boot 3.3, Java 21) ----
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B -DskipTests package

FROM eclipse-temurin:21-jre AS runtime
RUN useradd -m -u 10001 appuser
USER appuser
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"
# Runtime config comes from the environment (see docker-compose.yml / docker-compose.prod.yml).
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

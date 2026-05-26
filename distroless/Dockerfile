# STAGE 1: Build
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

COPY HelloWorld.java .
RUN javac HelloWorld.java && jar cf app.jar HelloWorld.class


# STAGE 2: Runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy only the compiled JAR from the build stage
COPY --from=build /app/*.jar app.jar

# Expose the application port (standard for Spring Boot)
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

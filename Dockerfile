# Stage 1: Build the application using Java 21 and Gradle
FROM openjdk:21-jdk-buster AS builder

# Ensure apt-get is available, and install required packages for Gradle
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    apt-transport-https \
    gnupg2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Gradle manually
RUN wget https://services.gradle.org/distributions/gradle-8.3-bin.zip \
    && unzip gradle-8.3-bin.zip -d /opt/gradle \
    && rm gradle-8.3-bin.zip

# Set the Gradle binary in the PATH
ENV PATH="/opt/gradle/gradle-8.3/bin:${PATH}"

# Set the working directory inside the container
WORKDIR /home/gradle/project

# Copy the project files into the container
COPY . /home/gradle/project

# Ensure the gradlew script has execute permissions
RUN chmod +x ./gradlew

# Run the Gradle build with more verbose logging for Java 21 compatibility
RUN ./gradlew build --no-daemon --stacktrace --info

# Stage 2: Run the application with Java 21
FROM openjdk:21-jdk-slim

# Expose the application port
EXPOSE 8080

# Copy the built JAR file from the builder stage to the app directory in the new container
COPY --from=builder /home/gradle/project/build/libs/*.jar /app/app.jar

# Use JSON format for ENTRYPOINT to avoid issues with OS signals
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

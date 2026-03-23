// Docker配置文件示例
// Dockerfile
FROM openjdk:11-jdk-slim

WORKDIR /app

COPY target/*.jar app.jar

EXPOSE 8080

ENV JAVA_OPTS="-Xmx512m"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
FROM eclipse-temurin:25-jdk AS build
WORKDIR /app
COPY Hello.java .
RUN javac Hello.java && \
    jar --create --file hello.jar --main-class Hello Hello.class

FROM gcr.io/distroless/java25-debian12
COPY --from=build /app/hello.jar /hello.jar
CMD ["/hello.jar"]

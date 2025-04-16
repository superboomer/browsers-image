# syntax=docker/dockerfile:1.4

ARG BASE_IMAGE=alpine:latest
FROM --platform=$BUILDPLATFORM ${BASE_IMAGE} AS build

ARG TARGETPLATFORM
ENV LANG=C.UTF-8

# Install all dependencies once in the build stage
RUN apk add --no-cache \
    curl \
    tar

# Determine correct OpenJDK 23 binary
WORKDIR /opt
RUN set -eux; \
    case "${TARGETPLATFORM}" in \
    "linux/amd64") ARCH="x64" ;; \
    "linux/arm64") ARCH="aarch64" ;; \
    *) echo "Unsupported architecture: ${TARGETPLATFORM}" && exit 1 ;; \
    esac && \
    JDK_URL="https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.2%2B7/OpenJDK23U-jdk_${ARCH}_alpine-linux_hotspot_23.0.2_7.tar.gz" && \
    echo "Downloading: $JDK_URL" && \
    curl -L "$JDK_URL" | tar -xz && \
    mv jdk-* jdk23

# Final slim image
FROM alpine:latest

# Only add minimal runtime dependencies
RUN apk add --no-cache \
    dbus \
    xvfb \
    ttf-freefont \
    fontconfig \
    ca-certificates \
    bash \
    firefox-esr \
    udev

# Copy only what's needed from the builder
COPY --from=build /opt/jdk23 /opt/jdk23

ENV JAVA_HOME=/opt/jdk23
ENV PATH="${JAVA_HOME}/bin:${PATH}"

CMD ["java", "-version"]

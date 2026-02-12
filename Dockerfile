# Dockerfile for wavelog-stoat
#
# docker build --platform linux/amd64 -t wavelog-stoat:latest
#
# Build stage: compile a static Go binary
FROM golang:1.19-alpine AS builder

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -o wavelog-stoat .

# Runtime stage: minimal image with just the binary
FROM alpine:3.19

# CA certs needed for HTTPS calls to the WaveLog API
RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /build/wavelog-stoat .

EXPOSE 2333/udp

ENTRYPOINT ["./wavelog-stoat"]
CMD ["-c", "/app/config.ini"]

# Usage:
#   docker build -t wavelog-stoat .
#   docker run -v /path/to/config.ini:/app/config.ini:ro \
#              -v /dev/null:/app/wavelog-stoat.log \
#              -p 2333:2333/udp wavelog-stoat
#
# The app logs to both stdout and a file. Since Docker captures stdout
# and handles log rotation, the log file is mounted to /dev/null by default.
# To persist the log file instead, replace /dev/null with a host path:
#   -v /path/to/wavelog-stoat.log:/app/wavelog-stoat.log
#
# To use a different config path, override CMD:
#   docker run -v /path/to/my.ini:/etc/wavelog.ini:ro \
#              -v /dev/null:/app/wavelog-stoat.log \
#              -p 2333:2333/udp wavelog-stoat -c /etc/wavelog.ini
#
# Docker Compose example:
#   services:
#     wavelog-stoat:
#       build: .
#       ports:
#         - "2333:2333/udp"
#       volumes:
#         - ./config.ini:/app/config.ini:ro
#         - /dev/null:/app/wavelog-stoat.log
#       restart: unless-stopped

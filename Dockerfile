# --- ЭТАП 1: СБОРКА ---
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git make gcc musl-dev
WORKDIR /app
COPY . .
ARG SERVICE_NAME
RUN go work sync
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/bin/service ./services/${SERVICE_NAME}/cmd/app/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /app/bin/service /app/service
RUN chown -R appuser:appgroup /app
USER appuser
CMD ["/app/service"]
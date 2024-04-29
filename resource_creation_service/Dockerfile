# Use the official Go image with a specific version
FROM golang:1.22.2-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files for dependency management
COPY go.mod go.sum ./

# Download and install dependencies
RUN go mod download

# Copy the rest of the application source code
COPY . .

# Build the Go application
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

# Use a lightweight Alpine image as the final base
FROM alpine:latest

# Set the working directory inside the container
WORKDIR /root/

# Copy the built executable from the builder stage
COPY --from=builder /app/app .

# Expose port 8080 for the application
EXPOSE 8080

# Command to run the executable
CMD ["./app"]
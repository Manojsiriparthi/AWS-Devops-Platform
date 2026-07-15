# ==============================================================================
# Multi-stage Dockerfile for Netflix-like React Application
# Stage 1: Build the React application
# Stage 2: Serve with optimized Nginx
# ==============================================================================

# Stage 1: Build Stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Add labels for better image management
LABEL maintainer="DevOps Team" \
      description="StreamFlix - Netflix-like React App for Day 4 K8s Demo" \
      version="1.0.0" \
      project="aws-devops-platform"

# Install dependencies first (for better Docker layer caching)
COPY package*.json ./
RUN npm ci --only=production --silent

# Copy source code
COPY public/ ./public/
COPY src/ ./src/

# Set build-time environment variables
ARG REACT_APP_VERSION=1.0.0
ARG REACT_APP_BUILD_DATE
ARG REACT_APP_ENVIRONMENT=production

ENV REACT_APP_VERSION=${REACT_APP_VERSION}
ENV REACT_APP_BUILD_DATE=${REACT_APP_BUILD_DATE}
ENV REACT_APP_ENVIRONMENT=${REACT_APP_ENVIRONMENT}

# Build the application
RUN npm run build

# Remove source code and node_modules to reduce image size
RUN rm -rf src/ node_modules/ package*.json

# Stage 2: Production Stage with Nginx
FROM nginx:1.25-alpine AS production

# Install security updates
RUN apk update && apk upgrade && apk add --no-cache \
    curl \
    jq \
    && rm -rf /var/cache/apk/*

# Create non-root user for better security
RUN addgroup -g 1001 -S streamflix && \
    adduser -S streamflix -u 1001 -G streamflix

# Copy built React app from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Create health check script
COPY --chmod=755 <<EOF /usr/local/bin/healthcheck.sh
#!/bin/sh
curl -f http://localhost:80/health || exit 1
EOF

# Create health endpoint
RUN echo '{"status":"healthy","service":"streamflix","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > /usr/share/nginx/html/health

# Set proper ownership and permissions
RUN chown -R streamflix:streamflix /usr/share/nginx/html && \
    chown -R streamflix:streamflix /var/cache/nginx && \
    chown -R streamflix:streamflix /var/log/nginx && \
    chown -R streamflix:streamflix /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown streamflix:streamflix /var/run/nginx.pid

# Create directories for nginx to work properly
RUN mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp && \
    chown -R streamflix:streamflix /var/cache/nginx

# Expose port 80
EXPOSE 80

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Switch to non-root user
USER streamflix

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

# Metadata
LABEL org.opencontainers.image.title="StreamFlix React App" \
      org.opencontainers.image.description="Netflix-like streaming frontend for Kubernetes demo" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.created="${REACT_APP_BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/your-org/aws-devops-platform" \
      org.opencontainers.image.licenses="MIT"
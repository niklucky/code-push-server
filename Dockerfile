# Builder for CodePush API
FROM public.ecr.aws/docker/library/node:22-alpine3.21 AS api-builder

WORKDIR /usr/src/app

# Copy dependency definitions
COPY api/package.json api/package-lock.json ./

# Install dependencies
RUN npm ci

# Copy the source code
COPY api/ .

# Build the application
RUN npm run build

# Builder for Azurite
FROM public.ecr.aws/docker/library/node:22-alpine3.21 AS azurite-builder

WORKDIR /opt/azurite

# Install dependencies and build the app
COPY azurite/*.json azurite/LICENSE azurite/NOTICE.txt ./
COPY azurite/src ./src
COPY azurite/tests ./tests
RUN npm ci --unsafe-perm && npm run build

# Production image
FROM public.ecr.aws/docker/library/node:22-alpine3.21

ENV NODE_ENV=production

WORKDIR /usr/src/app

# Install tini
RUN apk add --no-cache tini

# Install azurite globally
RUN npm install -g azurite

# Copy built CodePush API from builder stage
COPY --from=api-builder /usr/src/app /usr/src/app

# Copy built Azurite from builder stage
WORKDIR /opt/azurite
COPY --from=azurite-builder /opt/azurite /opt/azurite

# Default Workspace Volume for Azurite
VOLUME [ "/data" ]

# Expose ports for CodePush API and Azurite
EXPOSE 3000
EXPOSE 10000
EXPOSE 10001
EXPOSE 10002

# Install supervisord
RUN apk add --no-cache supervisor

# Copy the supervisord configuration file into the container
COPY supervisord.conf /etc/supervisord.conf

# Main process
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
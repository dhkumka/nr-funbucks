ARG REPO_LOCATION=
FROM ${REPO_LOCATION}node:18-alpine as builder

# Install packages and build
WORKDIR /app
COPY . ./
RUN npm ci --no-audit && \
    npm run build

# Keep only prod packages
RUN npm ci --omit=dev --no-audit

# Deployment container
FROM ${REPO_LOCATION}node:18-alpine

# Create app directory
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/bin ./bin
COPY --from=builder /app/config ./config
COPY --from=builder /app/package.json ./package.json

VOLUME /app/config
VOLUME /app/output
VOLUME /app/output_pack

ENTRYPOINT [ "./bin/run" ]

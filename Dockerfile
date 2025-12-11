# syntax=docker/dockerfile:1.6

FROM node:22-alpine AS base
WORKDIR /app

FROM base AS deps
RUN apk add --no-cache libc6-compat
COPY package*.json ./
RUN npm ci

FROM deps AS builder
ARG SESSION_SECRET="development-session-secret-change-me"
ARG MONGODB_URI="mongodb://localhost:27017/placeholder"
ENV SESSION_SECRET=${SESSION_SECRET}
ENV MONGODB_URI=${MONGODB_URI}
COPY . .
RUN npm run build

FROM base AS runner
ARG SESSION_SECRET="development-session-secret-change-me"
ARG MONGODB_URI="mongodb://localhost:27017/placeholder"
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV SESSION_SECRET=${SESSION_SECRET}
ENV MONGODB_URI=${MONGODB_URI}
WORKDIR /app
RUN apk add --no-cache libc6-compat
COPY --from=deps /app/package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/messages ./messages
EXPOSE 3000
CMD ["npm", "run", "start", "--", "--hostname", "0.0.0.0", "--port", "3000"]

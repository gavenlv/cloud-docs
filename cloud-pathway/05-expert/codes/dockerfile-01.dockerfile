FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM gcr.io/distroless/nodejs18-debian11

WORKDIR /app

COPY --from=builder --chown=nonroot:nonroot /app/dist ./dist
COPY --from=builder --chown=nonroot:nonroot /app/node_modules ./node_modules

USER nonroot

EXPOSE 3000

CMD ["dist/main.js"]
FROM node:20-bookworm-slim

RUN apt-get update -y && \
    apt-get install -y openssl xvfb && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci

RUN npx playwright install --with-deps chromium

COPY tsconfig.json ./
COPY prisma.config.ts ./
COPY src ./src
COPY prisma ./prisma

RUN npm run build

CMD ["sh", "-c", "\
  npx prisma migrate resolve --applied 00000000000000_baseline || true && \
  npx prisma migrate deploy && \
  xvfb-run --auto-servernum node --enable-source-maps dist/index.js \
"]

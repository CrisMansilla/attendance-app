FROM node:20-alpine AS builder

ENV LANG=es_CL.UTF-8 \
    LANGUAGE=es_CL:es \
    LC_ALL=es_CL.UTF-8

WORKDIR /app

COPY package*.json ./

RUN npm install

FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY . .

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

USER appuser

EXPOSE 3000

CMD ["node", "index.js"]
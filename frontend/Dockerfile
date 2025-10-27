FROM node:18-alpine

WORKDIR /app

RUN npm install -g @angular/cli@16

COPY package*.json ./

RUN npm install --legacy-peer-deps

COPY . .

EXPOSE 4200

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:4200 || exit 1

CMD ["ng", "serve", "--host", "0.0.0.0", "--port", "4200", "--poll", "2000"]

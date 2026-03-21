FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY src ./src
COPY build.js ./

RUN node build.js

EXPOSE 3000

CMD ["node", "src/index.js"]
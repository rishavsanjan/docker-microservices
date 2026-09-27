FROM node:22-alpine

WORKDIR /app

COPY --chown=node:node package*.json ./

RUN npm ci

COPY --chown=node:node . .

USER node

EXPOSE 5000

CMD ["npm", "start"]
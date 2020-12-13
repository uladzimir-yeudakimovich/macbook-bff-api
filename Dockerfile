FROM mhart/alpine-node:14 as base

WORKDIR /build
COPY package*.json ./
RUN npm ci --from-lock-file && npm cache clean --force
COPY . .
RUN npm run build && npm prune --production

FROM mhart/alpine-node:slim-14
WORKDIR /app

COPY --from=base /build/dist ./dist
COPY --from=base /build/node_modules ./node_modules

ENV PORT=8080
EXPOSE 8080

CMD ["node", "dist/main.js"]
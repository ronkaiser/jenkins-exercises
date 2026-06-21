# Node 24 Alpine base image
FROM node:24-alpine

# App directory and files
WORKDIR /app
COPY app/ ./
RUN npm install

# Run on port 3000
EXPOSE 3000
CMD ["node", "server.js"]

# Simple Node.js image for the ERP mock backend
FROM node:18-alpine

WORKDIR /app

# Copy only what we need (no npm deps for this simple HTTP server)
COPY server.js .

EXPOSE 9001

CMD ["node", "server.js"]

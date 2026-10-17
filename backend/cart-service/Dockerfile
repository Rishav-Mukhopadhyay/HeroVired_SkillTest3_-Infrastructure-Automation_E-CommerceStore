# Start from a small Linux image that already has Node.js 22 installed
FROM node:22-alpine

# Every command below runs inside the /app folder in the container
WORKDIR /app

# Copy ONLY the package list first, then install libraries
COPY package*.json ./
RUN npm install --omit=dev

# Now copy the actual source code
COPY . .

# The port this service listens on
ENV PORT=3003
EXPOSE 3003

# What to run when the container starts (plain node, NOT nodemon)
CMD ["node", "server.js"]

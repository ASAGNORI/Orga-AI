# Base image
FROM node:23-alpine

# Working directory
WORKDIR /app

# Copiar os arquivos do frontend para o container
COPY . /app/    

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of the app
COPY . .

# Create and set permissions on .next directory 
RUN mkdir -p /app/.next && chmod -R 777 /app/.next

# Set environment variables
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=development
ENV PORT=3010

# Expose the port
EXPOSE 3010

# Start the development server
CMD ["npm", "run", "dev"]

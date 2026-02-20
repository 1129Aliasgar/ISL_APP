# Base image with Node
FROM node:18

# Install Python and pip
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    apt-get clean

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node dependencies
WORKDIR /app
RUN npm install

# Copy backend source
COPY . .

# Copy ML folder
COPY ml ./ml

# Copy requirements.txt
COPY requirements.txt .

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose port
EXPOSE 5000

# Start Node server
CMD ["npm", "start"]
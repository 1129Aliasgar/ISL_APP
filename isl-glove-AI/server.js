require('dotenv').config();
const http = require('http');
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { initSockets } = require('./src/sockets');

const PORT = process.env.PORT || 5000;

connectDB();

const server = http.createServer(app);
initSockets(server);

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log('Socket namespaces: /sensor, /predict');
});

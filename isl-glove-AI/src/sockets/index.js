const { Server } = require('socket.io');
const { registerPredictSocket } = require('./predict.socket');
const { registerSensorSocket } = require('./sensor.socket');

const initSockets = (httpServer) => {
  const io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  const predictNs = registerPredictSocket(io);
  registerSensorSocket(io, predictNs);

  return io;
};

module.exports = { initSockets };

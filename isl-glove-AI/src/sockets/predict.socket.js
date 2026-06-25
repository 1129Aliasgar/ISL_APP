const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

const predictRoom = (deviceId) => `predict:${deviceId}`;

const registerPredictSocket = (io) => {
  const predictNs = io.of('/predict');

  predictNs.on('connection', (socket) => {
    let joinedDeviceId = null;

    socket.on('join', async ({ deviceId, token }) => {
      try {
        if (!deviceId) {
          socket.emit('error', { message: 'deviceId is required' });
          return;
        }
        if (!token) {
          socket.emit('error', { message: 'Missing auth token' });
          return;
        }

        const payload = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(payload.sub);
        if (!user) {
          socket.emit('error', { message: 'Invalid auth token' });
          return;
        }

        joinedDeviceId = deviceId;
        socket.join(predictRoom(deviceId));
        socket.emit('joined', {
          deviceId,
          room: predictRoom(deviceId),
          user: { id: user._id.toString(), name: user.name },
        });
      } catch (err) {
        socket.emit('error', { message: err.message || 'Unauthorized' });
      }
    });

    socket.on('leave', ({ deviceId }) => {
      const id = deviceId || joinedDeviceId;
      if (!id) return;
      socket.leave(predictRoom(id));
      joinedDeviceId = null;
      socket.emit('left', { deviceId: id });
    });

    socket.on('disconnect', () => {
      joinedDeviceId = null;
    });
  });

  return predictNs;
};

module.exports = { registerPredictSocket };

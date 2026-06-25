const { addToBuffer, flushBuffer, getBufferSize } = require('../utils/sensorBuffer');
const { runPrediction } = require('../services/predictionPipeline.service');
const { emitPredictionResult, emitPredictionError } = require('./predictionEmitter');

const sensorRoom = (deviceId) => `sensor:${deviceId}`;

const validateDeviceToken = (token) => {
  const expected = process.env.DEVICE_TOKEN || 'local-dev-device-token';
  return token && token === expected;
};

const parseReading = (payload) => {
  const { deviceId, sensors, timestamp } = payload;
  if (!deviceId || !sensors) {
    throw new Error('deviceId and sensors are required');
  }

  const { flex, accel, gyro } = sensors;
  if (!flex || !accel || !gyro) {
    throw new Error('Invalid sensor format');
  }

  const readingTimestamp = timestamp ? new Date(timestamp) : new Date();
  if (Number.isNaN(readingTimestamp.getTime())) {
    throw new Error('Invalid timestamp format');
  }

  return {
    deviceId,
    reading: [...flex, ...accel, ...gyro],
    readingTimestamp,
  };
};

const registerSensorSocket = (io, predictNs) => {
  const sensorNs = io.of('/sensor');

  sensorNs.on('connection', (socket) => {
    let joinedDeviceId = null;

    socket.on('join', ({ deviceId, deviceToken }) => {
      if (!deviceId) {
        socket.emit('error', { message: 'deviceId is required' });
        return;
      }
      if (!validateDeviceToken(deviceToken)) {
        socket.emit('error', { message: 'Invalid device token' });
        return;
      }

      joinedDeviceId = deviceId;
      socket.join(sensorRoom(deviceId));
      socket.emit('joined', { deviceId, room: sensorRoom(deviceId) });
    });

    socket.on('stream:start', ({ deviceId }) => {
      const id = deviceId || joinedDeviceId;
      if (!id) {
        socket.emit('error', { message: 'deviceId is required' });
        return;
      }
      flushBuffer(id);
      socket.emit('stream:started', { deviceId: id });
    });

    socket.on('sensor:reading', (payload) => {
      try {
        const { deviceId, reading, readingTimestamp } = parseReading(payload);
        const id = deviceId || joinedDeviceId;
        if (!id) {
          socket.emit('error', { message: 'deviceId is required' });
          return;
        }

        addToBuffer(id, reading, readingTimestamp);
        socket.emit('reading:buffered', {
          deviceId: id,
          bufferedCount: getBufferSize(id),
        });
      } catch (err) {
        socket.emit('error', { message: err.message });
      }
    });

    socket.on('stream:end', async (payload = {}) => {
      const id = payload.deviceId || joinedDeviceId;
      if (!id) {
        socket.emit('error', { message: 'deviceId is required' });
        return;
      }

      try {
        const flushed = flushBuffer(id);
        if (!flushed) {
          socket.emit('error', { message: 'No buffered data to predict for this device' });
          return;
        }

        socket.emit('stream:processing', { deviceId: id });
        predictNs.to(`predict:${id}`).emit('status', {
          deviceId: id,
          state: 'processing',
        });

        const result = await runPrediction(id, flushed.window);

        emitPredictionResult(id, result);

        socket.emit('stream:completed', {
          deviceId: id,
          prediction: result,
        });
      } catch (err) {
        const message = typeof err === 'string' ? err : err.message || String(err);
        emitPredictionError(id, message);
        socket.emit('error', { message });
      }
    });

    socket.on('disconnect', () => {
      joinedDeviceId = null;
    });
  });

  return sensorNs;
};

module.exports = { registerSensorSocket };

const sensorService = require('../services/sensor.service');
const { addToBuffer, flushBuffer, getBufferSize } = require('../utils/sensorBuffer');

const createSensorData = async (req, res, next) => {
  try {
    const { deviceId, sensors, timestamp, end = false , gestureLabel = null } = req.body;

    if (!deviceId || !sensors) {
      return res.status(400).json({
        success: false,
        message: "deviceId and sensors are required"
      });
    }

    const { flex, accel, gyro } = sensors;

    if (!flex || !accel || !gyro ) {
      return res.status(400).json({
        success: false,
        message: "Invalid sensor format"
      });
    }

    const readingTimestamp = timestamp ? new Date(timestamp) : new Date();
    if (Number.isNaN(readingTimestamp.getTime())) {
      return res.status(400).json({
        success: false,
        message: "Invalid timestamp format"
      });
    }

    const reading = [
      ...flex,
      ...accel,
      ...gyro
    ];

    addToBuffer(deviceId, reading, readingTimestamp );

    if (end) {
      const flushed = flushBuffer(deviceId);
      if (!flushed) {
        return res.status(400).json({
          success: false,
          message: "No buffered data to save for this device"
        });
      }

      const { window, windowStart } = flushed;
      await sensorService.saveSensorWindow({
        deviceId,
        windowStart,
        data: window,
        gestureLabel
      });

      return res.status(201).json({
        success: true,
        message:"Sequence saved",
        length: window.length
      });
    }

     return res.status(200).json({
      success: true,
      message:"Reading buffered",
      bufferedCount: getBufferSize(deviceId)
     });

  } catch (err) {
    next(err);
  }
};

module.exports = {
  createSensorData,
};

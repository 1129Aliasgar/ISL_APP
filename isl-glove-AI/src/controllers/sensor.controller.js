const sensorService = require('../services/sensor.service');
const { addToBuffer } = require('../utils/sensorBuffer');

const createSensorData = async (req, res, next) => {
  try {
    const { deviceId, sensors, timestamp } = req.body;

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
      ...gyro,
    ];

    const bufferedWindow = addToBuffer(deviceId, reading, readingTimestamp);
    if (bufferedWindow) {
      const { window, windowStart } = bufferedWindow;
      await sensorService.saveSensorWindow({
        deviceId,
        windowStart,
        data: window
      });

      return res.status(201).json({
        message:"Data save",
        window
      });
    }

     return res.status(200).json({
      message:"Data reached",
      status:"Success"
     });

  } catch (err) {
    next(err);
  }
};

module.exports = {
  createSensorData,
};

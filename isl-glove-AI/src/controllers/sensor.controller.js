const sensorService = require('../services/sensor.service');
const { addToBuffer } = require('../utils/sensorBuffer');

const createSensorData = async (req, res, next) => {
  try {
    const { deviceId, sensors } = req.body;

    if (!deviceId || !sensors) {
      return res.status(400).json({
        success: false,
        message: "deviceId and sensors are required"
      });
    }

    const { flex, accel, gyro, orientation } = sensors;

    if (!flex || !accel || !gyro || !orientation) {
      return res.status(400).json({
        success: false,
        message: "Invalid sensor format"
      });
    }

    const reading = [
      ...flex,
      ...accel,
      ...gyro,
      ...orientation
    ];

    const window = addToBuffer(deviceId, reading);
    if (window) {
      await sensorService.saveSensorWindow({
        deviceId,
        windowStart: new Date(),
        data: window
      });

      res.status(201).json({
        message:"Data save"
      })
    }

     res.status(200).json({
      message:"Data reached",
      status:"Sucess"
     })

  } catch (err) {
    next(err);
  }
};

module.exports = {
  createSensorData,
};

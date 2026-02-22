const predictionService = require('../services/prediction.service');
const { publishToQueue } = require('../utils/rabbit.client')
const { addToBuffer } = require('../utils/sensorBuffer');

const predict = async (req, res, next) => {
  try {
    let predictionInput = req.body.data;

    if (!predictionInput && req.body.sensors && req.body.deviceId) {
      const { flex, accel, gyro } = req.body.sensors;
      const reading = [...flex, ...accel, ...gyro];
      const readingTimestamp = req.body.timestamp ? new Date(req.body.timestamp) : new Date();

      const bufferedWindow = addToBuffer(req.body.deviceId, reading, readingTimestamp);
      if (!bufferedWindow) {
        return res.status(202).json({
          success: true,
          buffered: true,
          message: 'Reading buffered. Waiting for 50 timesteps.',
        });
      }

      predictionInput = bufferedWindow.window;
    }

    const result = await predictionService.predictGesture(predictionInput);
    await publishToQueue(process.env.QUEUE_NAME, result.character);

    return res.json({
      success: true,
      prediction: result,
    });
  } catch (err) {
    console.error("PREDICT ERROR:", err); 
    const message = typeof err === 'string' ? err : err.message || String(err);
    const statusCode = message.includes('Missing ML artifacts') ? 503 : 500;
    return res.status(statusCode).json({
      success: false,
      error: message
    });
  }
};

module.exports = { predict };

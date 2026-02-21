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
    return res.status(500).json({
      success: false,
      error: typeof err === 'string' ? err : err.message || err
    });
  }
};

module.exports = { predict };
